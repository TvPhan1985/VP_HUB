// Lop BLE (NimBLE GATT) cua giao thuc VPH v1. Khung lay tu c3_relay_ctrl/ble_svc.c.
// Callback GATT chi doc bo dem va day lenh vao queue; moi viec nang lam trong vph_poll().
#include "vph_ble.h"
#include "vph_core.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "esp_log.h"
#include "esp_mac.h"
#include "esp_system.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/semphr.h"
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_hs.h"
#include "host/util/util.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"

static const char *TAG = "vph_ble";

// UUID goc 5b39XXXX-5578-4ab2-9265-4b994a7bc724, viet little-endian cho NimBLE
#define VPH_UUID(x) BLE_UUID128_INIT(0x24, 0xc7, 0x7b, 0x4a, 0x99, 0x4b, 0x65, 0x92, \
                                     0xb2, 0x4a, 0x78, 0x55, (x), 0x00, 0x39, 0x5b)
static const ble_uuid128_t UUID_SVC = VPH_UUID(0x01);
static const ble_uuid128_t UUID_INFO = VPH_UUID(0x02);
static const ble_uuid128_t UUID_SELECT = VPH_UUID(0x03);
static const ble_uuid128_t UUID_SCHEMA = VPH_UUID(0x04);
static const ble_uuid128_t UUID_VALUES = VPH_UUID(0x05);
static const ble_uuid128_t UUID_WRITE = VPH_UUID(0x06);
static const ble_uuid128_t UUID_RESULT = VPH_UUID(0x07);

enum { CHR_INFO = 2, CHR_SELECT, CHR_SCHEMA, CHR_VALUES, CHR_WRITE, CHR_RESULT };

#define VALUES_CAP      400     // lon hon 240 de goi qua co van gui duoc khi MTU cho phep (da canh bao)
#define WRITE_CAP       512
#define WRITE_QUEUE_LEN 8
#define NOTIFY_PERIOD_US    1000000
#define REBOOT_DELAY_US     500000

static SemaphoreHandle_t s_lock;        // bao ve s_vals va chuoi INFO
static QueueHandle_t s_writes;          // phan tu: char * (malloc), task chinh giai phong
static char *s_vals;                    // n * VALUES_CAP: VALUES da dung san cua tung man
static int s_n;
static uint8_t s_addr_type;
static volatile uint16_t s_conn = BLE_HS_CONN_HANDLE_NONE;
static volatile bool s_sub_values, s_sub_result;
static volatile bool s_synced;
static volatile uint8_t s_screen, s_page;
static volatile bool s_kick;            // can dung lai VALUES va notify ngay
static volatile bool s_readv;           // ten doi, can quang ba lai
static uint16_t s_h_values, s_h_result;
static int64_t s_last_notify;
static int64_t s_reboot_at;
static bool s_started;

static void advertise(void);

// ---------- GATT ----------

static int append(struct ble_gatt_access_ctxt *ctxt, const void *p, size_t n)
{
    return os_mbuf_append(ctxt->om, p, n) == 0 ? 0 : BLE_ATT_ERR_INSUFFICIENT_RES;
}

static int gatt_access(uint16_t conn, uint16_t attr, struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    int which = (int)(intptr_t)arg;
    bool rd = ctxt->op == BLE_GATT_ACCESS_OP_READ_CHR;
    bool wr = ctxt->op == BLE_GATT_ACCESS_OP_WRITE_CHR;
    switch (which) {
    case CHR_INFO:
        if (rd) {
            xSemaphoreTake(s_lock, portMAX_DELAY);
            const char *i = vph_core_info();
            int rc = append(ctxt, i, strlen(i));
            xSemaphoreGive(s_lock);
            return rc;
        }
        break;
    case CHR_SELECT:
        if (rd) {
            uint8_t v[2] = {s_screen, s_page};
            return append(ctxt, v, 2);
        }
        if (wr) {
            uint8_t v[2] = {0, 0};
            uint16_t len = OS_MBUF_PKTLEN(ctxt->om);
            if (len < 1 || len > 2) return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
            if (os_mbuf_copydata(ctxt->om, 0, len, v) != 0) return BLE_ATT_ERR_UNLIKELY;
            bool changed = v[0] != s_screen;
            s_screen = v[0];
            s_page = v[1];      // thieu byte trang = trang 0
            if (changed) s_kick = true;
            return 0;
        }
        break;
    case CHR_SCHEMA:
        if (rd) {
            // Chuoi schema khong doi sau vph_init nen doc truc tiep, khong can khoa
            const char *p;
            size_t n = vph_core_schema_page(s_screen, s_page, &p);
            return append(ctxt, p, n);
        }
        break;
    case CHR_VALUES:
        if (rd) {
            if (s_screen >= s_n) return append(ctxt, "{}", 2);
            xSemaphoreTake(s_lock, portMAX_DELAY);
            const char *v = s_vals + (size_t)s_screen * VALUES_CAP;
            int rc = append(ctxt, v, strlen(v));
            xSemaphoreGive(s_lock);
            return rc;
        }
        break;
    case CHR_WRITE:
        if (wr) {
            uint16_t len = OS_MBUF_PKTLEN(ctxt->om);
            if (len == 0 || len > WRITE_CAP) return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
            char *buf = malloc(len + 1);
            if (!buf) return BLE_ATT_ERR_INSUFFICIENT_RES;
            if (ble_hs_mbuf_to_flat(ctxt->om, buf, len, NULL) != 0) {
                free(buf);
                return BLE_ATT_ERR_UNLIKELY;
            }
            buf[len] = '\0';
            // Chi day sang task chinh, khong xu ly o day
            if (xQueueSend(s_writes, &buf, 0) != pdTRUE) {
                free(buf);
                return BLE_ATT_ERR_INSUFFICIENT_RES;
            }
            return 0;
        }
        break;
    case CHR_RESULT:
        if (rd) return 0;
        break;
    }
    return BLE_ATT_ERR_UNLIKELY;
}

static const struct ble_gatt_svc_def s_svcs[] = {
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &UUID_SVC.u,
        .characteristics = (struct ble_gatt_chr_def[]) {
            {.uuid = &UUID_INFO.u, .access_cb = gatt_access, .arg = (void *)CHR_INFO,
             .flags = BLE_GATT_CHR_F_READ},
            {.uuid = &UUID_SELECT.u, .access_cb = gatt_access, .arg = (void *)CHR_SELECT,
             .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_WRITE},
            {.uuid = &UUID_SCHEMA.u, .access_cb = gatt_access, .arg = (void *)CHR_SCHEMA,
             .flags = BLE_GATT_CHR_F_READ},
            {.uuid = &UUID_VALUES.u, .access_cb = gatt_access, .arg = (void *)CHR_VALUES,
             .val_handle = &s_h_values, .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_NOTIFY},
            {.uuid = &UUID_WRITE.u, .access_cb = gatt_access, .arg = (void *)CHR_WRITE,
             .flags = BLE_GATT_CHR_F_WRITE},
            {.uuid = &UUID_RESULT.u, .access_cb = gatt_access, .arg = (void *)CHR_RESULT,
             .val_handle = &s_h_result, .flags = BLE_GATT_CHR_F_NOTIFY},
            {0},
        },
    },
    {0},
};

// ---------- GAP ----------

static int gap_event(struct ble_gap_event *ev, void *arg)
{
    switch (ev->type) {
    case BLE_GAP_EVENT_CONNECT:
        if (ev->connect.status == 0) {
            s_screen = 0;       // ket noi moi: SELECT ve 0
            s_page = 0;
            s_conn = ev->connect.conn_handle;
            s_kick = true;
            ESP_LOGI(TAG, "BLE ket noi, handle=%d", s_conn);
        } else {
            ESP_LOGW(TAG, "BLE ket noi that bai: %d", ev->connect.status);
            advertise();
        }
        break;
    case BLE_GAP_EVENT_DISCONNECT:
        ESP_LOGI(TAG, "BLE ngat ket noi, ly do=0x%x", ev->disconnect.reason);
        s_conn = BLE_HS_CONN_HANDLE_NONE;
        s_sub_values = s_sub_result = false;
        advertise();    // ten moi (neu vua doi) duoc dung tu day
        break;
    case BLE_GAP_EVENT_ADV_COMPLETE:
        if (s_conn == BLE_HS_CONN_HANDLE_NONE) advertise();
        break;
    case BLE_GAP_EVENT_SUBSCRIBE:
        if (ev->subscribe.attr_handle == s_h_values) {
            s_sub_values = ev->subscribe.cur_notify;
            if (s_sub_values) s_kick = true;
        }
        if (ev->subscribe.attr_handle == s_h_result) s_sub_result = ev->subscribe.cur_notify;
        ESP_LOGI(TAG, "Dang ky notify: values=%d result=%d", s_sub_values, s_sub_result);
        break;
    case BLE_GAP_EVENT_MTU:
        ESP_LOGI(TAG, "MTU = %d", ev->mtu.value);
        break;
    default:
        break;
    }
    return 0;
}

static void advertise(void)
{
    if (!s_synced) return;
    // Goi quang ba: flags + UUID 128 bit. Ten nam o scan response (31 byte khong du ca hai)
    struct ble_hs_adv_fields f = {0};
    f.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
    f.uuids128 = &UUID_SVC;
    f.num_uuids128 = 1;
    f.uuids128_is_complete = 1;
    int rc = ble_gap_adv_set_fields(&f);
    if (rc) {
        ESP_LOGE(TAG, "Loi dat goi quang ba: %d", rc);
        return;
    }
    char name[VPH_NAME_MAX + 1];
    xSemaphoreTake(s_lock, portMAX_DELAY);
    strlcpy(name, vph_core_name(), sizeof(name));
    xSemaphoreGive(s_lock);
    struct ble_hs_adv_fields r = {0};
    r.name = (uint8_t *)name;
    r.name_len = strlen(name);
    r.name_is_complete = 1;
    rc = ble_gap_adv_rsp_set_fields(&r);
    if (rc) {
        ESP_LOGE(TAG, "Loi dat scan response: %d", rc);
        return;
    }
    struct ble_gap_adv_params p = {0};
    p.conn_mode = BLE_GAP_CONN_MODE_UND;
    p.disc_mode = BLE_GAP_DISC_MODE_GEN;
    rc = ble_gap_adv_start(s_addr_type, NULL, BLE_HS_FOREVER, &p, gap_event, NULL);
    if (rc == 0) ESP_LOGI(TAG, "BLE dang quang ba: %s", name);
    else if (rc != BLE_HS_EALREADY) ESP_LOGE(TAG, "Loi bat dau quang ba: %d", rc);
}

static void on_sync(void)
{
    ble_hs_util_ensure_addr(0);
    ble_hs_id_infer_auto(0, &s_addr_type);
    s_synced = true;
    advertise();
}

static void on_reset(int reason)
{
    s_synced = false;
    ESP_LOGE(TAG, "NimBLE reset, ly do=%d", reason);
}

static void host_task(void *param)
{
    nimble_port_run();
    nimble_port_freertos_deinit();
}

// ---------- Task chinh ----------

static void notify(uint16_t h, const char *str)
{
    uint16_t conn = s_conn;
    if (conn == BLE_HS_CONN_HANDLE_NONE) return;
    struct os_mbuf *om = ble_hs_mbuf_from_flat(str, strlen(str));
    if (!om) return;
    int rc = ble_gatts_notify_custom(conn, h, om);
    if (rc) ESP_LOGD(TAG, "Notify loi: %d", rc);
}

// Dung lai VALUES cua moi man hinh (goi vcb cua project) roi chep vao bo dem dung chung
static void refresh_values(void)
{
    char tmp[VALUES_CAP];
    for (int i = 0; i < s_n; i++) {
        vph_core_values(i, tmp, sizeof(tmp));
        xSemaphoreTake(s_lock, portMAX_DELAY);
        strcpy(s_vals + (size_t)i * VALUES_CAP, tmp);
        xSemaphoreGive(s_lock);
    }
}

static void apply_name(void)
{
    ble_svc_gap_device_name_set(vph_core_name());
    // Dang ket noi thi ten moi duoc quang ba khi ngat ket noi
    if (s_conn == BLE_HS_CONN_HANDLE_NONE && s_synced) {
        ble_gap_adv_stop();
        advertise();
    }
}

void vph_poll(void)
{
    if (!s_started) return;
    int64_t now = esp_timer_get_time();

    char *cmd;
    while (xQueueReceive(s_writes, &cmd, 0) == pdTRUE) {
        char result[VPH_MAX_RESULT + 40];
        if (strlen(cmd) > VPH_MAX_WRITE) {
            ESP_LOGW(TAG, "WRITE %d byte, vuot %d (PROTOCOL 8)", (int)strlen(cmd), VPH_MAX_WRITE);
        }
        // Khong giu s_lock o day: callback cua project co the lau (ghi NVS) hoac goi lai vph_set_name
        int act = vph_core_handle_write(cmd, result, sizeof(result));
        free(cmd);
        if (strlen(result) > VPH_MAX_RESULT) {
            ESP_LOGW(TAG, "RESULT %d byte, vuot %d (PROTOCOL 8)", (int)strlen(result), VPH_MAX_RESULT);
        }
        if (s_sub_result) notify(s_h_result, result);
        if (act & VPH_ACT_OK) s_kick = true;
        if (act & VPH_ACT_RENAME) s_readv = true;
        if (act & VPH_ACT_REBOOT) s_reboot_at = now + REBOOT_DELAY_US;
    }

    if (s_readv) {
        s_readv = false;
        apply_name();
    }

    if (s_kick || now - s_last_notify >= NOTIFY_PERIOD_US) {
        s_kick = false;
        s_last_notify = now;
        refresh_values();
        uint8_t scr = s_screen;
        if (s_sub_values && s_conn != BLE_HS_CONN_HANDLE_NONE && scr < s_n) {
            char tmp[VALUES_CAP];
            xSemaphoreTake(s_lock, portMAX_DELAY);
            strcpy(tmp, s_vals + (size_t)scr * VALUES_CAP);
            xSemaphoreGive(s_lock);
            notify(s_h_values, tmp);
        }
    }

    if (s_reboot_at && now >= s_reboot_at) {
        ESP_LOGW(TAG, "Khoi dong lai theo lenh _reboot");
        esp_restart();
    }
}

void vph_notify_now(void) { s_kick = true; }

bool vph_connected(void) { return s_conn != BLE_HS_CONN_HANDLE_NONE; }

const char *vph_get_name(void) { return vph_core_name(); }

esp_err_t vph_set_name(const char *name)
{
    if (!s_started) return vph_core_set_name(name);    // truoc vph_init: chi ghi nho
    xSemaphoreTake(s_lock, portMAX_DELAY);
    esp_err_t e = vph_core_set_name(name);
    xSemaphoreGive(s_lock);
    if (e == ESP_OK) s_readv = true;
    return e;
}

esp_err_t vph_init(const vph_info_t *info, cJSON *const *screens, int n,
                   vph_values_cb vcb, vph_write_cb wcb, vph_batch_cb bcb)
{
    if (s_started) return ESP_ERR_INVALID_STATE;
    // Ten da dat truoc bang vph_set_name() (vd doc tu NVS) thi giu, khong thi dung ten mac dinh
    char preset[VPH_NAME_MAX + 1];
    strlcpy(preset, vph_core_name(), sizeof(preset));
    esp_err_t e = vph_core_init(info, screens, n, vcb, wcb, bcb);
    if (e != ESP_OK) return e;
    if (!preset[0]) {
        uint8_t mac[6] = {0};
        esp_read_mac(mac, ESP_MAC_BT);
        char base[VPH_NAME_MAX + 1], name[VPH_NAME_MAX + 8];
        strlcpy(base, vph_core_name(), sizeof(base));
        base[VPH_NAME_MAX - 5] = '\0';      // chua cho cho "-XXXX"
        snprintf(name, sizeof(name), "%s-%02X%02X", base, mac[4], mac[5]);
        vph_core_set_name(name);
    }
    ESP_LOGI(TAG, "INFO (%d byte): %s", (int)strlen(vph_core_info()), vph_core_info());

    s_n = n;
    s_lock = xSemaphoreCreateMutex();
    s_writes = xQueueCreate(WRITE_QUEUE_LEN, sizeof(char *));
    s_vals = calloc((size_t)n, VALUES_CAP);
    if (!s_lock || !s_writes || !s_vals) return ESP_ERR_NO_MEM;
    for (int i = 0; i < n; i++) strcpy(s_vals + (size_t)i * VALUES_CAP, "{}");

    e = nimble_port_init();
    if (e != ESP_OK) {
        ESP_LOGE(TAG, "Khong khoi tao duoc NimBLE: %s", esp_err_to_name(e));
        return e;
    }
    ble_hs_cfg.sync_cb = on_sync;
    ble_hs_cfg.reset_cb = on_reset;
    ble_svc_gap_init();
    ble_svc_gatt_init();
    ble_svc_gap_device_name_set(vph_core_name());
    int rc = ble_gatts_count_cfg(s_svcs);
    if (rc == 0) rc = ble_gatts_add_svcs(s_svcs);
    if (rc) {
        ESP_LOGE(TAG, "Loi dang ky GATT: %d", rc);
        return ESP_FAIL;
    }
    ble_att_set_preferred_mtu(512);
    s_started = true;
    s_kick = true;
    nimble_port_freertos_init(host_task);
    return ESP_OK;
}
