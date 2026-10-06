// vph_demo - firmware mau cho giao thuc VPH v1 (ESP32-C3 SuperMini, WS2812 o GPIO8).
// Day la MAU CHUAN de chep khi lam du an moi: khai bao man hinh, dien VALUES, xu ly ghi.
// Xem docs/QUY_TAC_THIET_BI_MOI.md va firmware/components/vph_ble/README.md.
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "esp_log.h"
#include "esp_random.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "led_strip.h"
#include "nvs.h"
#include "nvs_flash.h"
#include "vph_ble.h"

static const char *TAG = "demo";

#define PIN_WS2812      8
#define LED_LEVEL       24          // do sang toi da 255
#define SLOT_COUNT      3
#define NVS_NS          "vphdemo"

enum { SCR_OVERVIEW = 0, SCR_SETTINGS, SCR_COUNT };

typedef struct {
    bool en;
    uint8_t days;       // bit0 = Thu 2 ... bit6 = Chu nhat
    char on[6];         // "HH:MM"
    char off[6];
} slot_t;

// Cau hinh luu NVS (man "Cai dat")
typedef struct {
    slot_t slots[SLOT_COUNT];
    float lo, hi;       // nguong thap < nguong cao
} cfg_t;

// Trang thai chay cua thiet bi, chi task chinh dung
typedef struct {
    cfg_t cfg;
    float temp;
    bool led;
    char color[8];
    int64_t beep_until;     // dang "bip": LED nhay trang den thoi diem nay
    bool save_cfg;
    led_strip_handle_t strip;
} app_t;

static app_t app = {
    .cfg = {
        .slots = {
            {true, 127, "08:00", "17:00"},
            {false, 31, "19:00", "21:30"},
            {false, 96, "06:00", "07:00"},
        },
        .lo = 20, .hi = 35,
    },
    .temp = 28.0f,
    .color = "green",
};

// ---------- NVS ----------

static void storage_load(void)
{
    nvs_handle_t h;
    if (nvs_open(NVS_NS, NVS_READONLY, &h) != ESP_OK) return;
    cfg_t c;
    size_t len = sizeof(c);
    if (nvs_get_blob(h, "cfg", &c, &len) == ESP_OK && len == sizeof(c)) app.cfg = c;
    char name[VPH_NAME_MAX + 1];
    len = sizeof(name);
    // Ten da doi qua app: dat truoc vph_init de quang ba dung ten
    if (nvs_get_str(h, "name", name, &len) == ESP_OK) vph_set_name(name);
    nvs_close(h);
}

static esp_err_t storage_save_cfg(void)
{
    nvs_handle_t h;
    esp_err_t e = nvs_open(NVS_NS, NVS_READWRITE, &h);
    if (e != ESP_OK) return e;
    e = nvs_set_blob(h, "cfg", &app.cfg, sizeof(app.cfg));
    if (e == ESP_OK) e = nvs_commit(h);
    nvs_close(h);
    return e;
}

static esp_err_t storage_save_name(const char *name)
{
    nvs_handle_t h;
    esp_err_t e = nvs_open(NVS_NS, NVS_READWRITE, &h);
    if (e != ESP_OK) return e;
    e = nvs_set_str(h, "name", name);
    if (e == ESP_OK) e = nvs_commit(h);
    nvs_close(h);
    return e;
}

// ---------- LED ----------

static void led_init(void)
{
    led_strip_config_t cfg = {
        .strip_gpio_num = PIN_WS2812,
        .max_leds = 1,
        .led_model = LED_MODEL_WS2812,
        .color_component_format = LED_STRIP_COLOR_COMPONENT_FMT_GRB,
    };
    led_strip_rmt_config_t rmt = {
        .clk_src = RMT_CLK_SRC_DEFAULT,
        .resolution_hz = 10 * 1000 * 1000,
    };
    if (led_strip_new_rmt_device(&cfg, &rmt, &app.strip) != ESP_OK) {
        ESP_LOGE(TAG, "Khong khoi tao duoc WS2812");
        app.strip = NULL;
        return;
    }
    led_strip_clear(app.strip);
}

static void led_update(int64_t now)
{
    if (!app.strip) return;
    uint8_t r = 0, g = 0, b = 0;
    if (now < app.beep_until) {
        // "Bip": nhay trang 5 Hz
        if ((now / 100000) % 2 == 0) r = g = b = LED_LEVEL;
    } else if (app.led) {
        if (!strcmp(app.color, "red")) r = LED_LEVEL;
        else if (!strcmp(app.color, "blue")) b = LED_LEVEL;
        else if (!strcmp(app.color, "white")) r = g = b = LED_LEVEL;
        else g = LED_LEVEL;
    }
    static uint32_t last = 0xFFFFFFFF;      // chi gui khi mau doi
    uint32_t rgb = ((uint32_t)r << 16) | ((uint32_t)g << 8) | b;
    if (rgb == last) return;
    last = rgb;
    led_strip_set_pixel(app.strip, 0, r, g, b);
    led_strip_refresh(app.strip);
}

// ---------- Schema ----------

static cJSON *build_overview(void)
{
    cJSON *s = vph_screen("overview", "Tổng quan", "live");

    cJSON *t = vph_field(s, "t", "Nhiệt độ", "num");
    vph_unit(t, "°C");
    vph_dp(t, 1);
    vph_readonly(t);
    vph_hint(t, "big,trend");

    vph_field(s, "led", "Đèn LED", "bool");

    cJSON *color = vph_field(s, "color", "Màu đèn", "enum");
    static const char *const vals[] = {"red", "green", "blue", "white"};
    static const char *const labels[] = {"Đỏ", "Lục", "Lam", "Trắng"};
    vph_options(color, vals, labels, 4);
    vph_enable_if(color, "led==true");

    vph_field(s, "beep", "Bíp", "act");

    cJSON *clock = vph_field(s, "clock", "Giờ thiết bị", "text");
    vph_group(clock, "Thiết bị");
    cJSON *name = vph_field(s, "_name", "Tên thiết bị", "str");
    vph_maxlen(name, VPH_NAME_MAX);
    vph_group(name, "Thiết bị");
    cJSON *rb = vph_field(s, "_reboot", "Khởi động lại", "act");
    vph_confirm(rb, "Khởi động lại thiết bị?");
    vph_group(rb, "Thiết bị");
    return s;
}

static cJSON *build_settings(void)
{
    // Hai nguong rang buoc nhau (lo < hi) nen dung man batch: sua xong bam Luu mot lan
    cJSON *s = vph_screen("settings", "Cài đặt", "batch");

    cJSON *lo = vph_field(s, "lo", "Ngưỡng thấp", "num");
    vph_unit(lo, "°C");
    vph_range(lo, 0, 100, 0.5);
    vph_group(lo, "Ngưỡng nhiệt độ");
    cJSON *hi = vph_field(s, "hi", "Ngưỡng cao", "num");
    vph_unit(hi, "°C");
    vph_range(hi, 0, 100, 0.5);
    vph_group(hi, "Ngưỡng nhiệt độ");

    // Khoi lap: chi mo ta mau mot lan, app tu sinh s1_en .. s3_off
    cJSON *rep = vph_repeat(s, SLOT_COUNT, "s", "Khung");
    vph_field(rep, "en", "Bật", "bool");
    cJSON *days = vph_field(rep, "days", "Thứ", "days");
    vph_enable_if(days, "en==true");
    cJSON *on = vph_field(rep, "on", "Giờ bật", "time");
    vph_enable_if(on, "en==true");
    cJSON *off = vph_field(rep, "off", "Giờ tắt", "time");
    vph_enable_if(off, "en==true");
    return s;
}

// ---------- VALUES ----------

static void fill_values(uint8_t screen, vph_out_t *o)
{
    char id[16];
    switch (screen) {
    case VPH_SCREEN_HDR:
        // Cac truong dau trang, co mat trong VALUES cua moi man hinh
        vph_out_num(o, "t", app.temp, 1);
        vph_out_bool(o, "led", app.led);
        break;
    case SCR_OVERVIEW: {
        vph_out_num(o, "t", app.temp, 1);
        vph_out_bool(o, "led", app.led);
        vph_out_str(o, "color", app.color);
        time_t now = time(NULL);
        if (now > 1700000000) {
            struct tm tm;
            char buf[24];
            localtime_r(&now, &tm);
            strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", &tm);
            vph_out_str(o, "clock", buf);
        } else {
            vph_out_null(o, "clock");       // chua co gio: app hien "--"
        }
        vph_out_str(o, "_name", vph_get_name());
        break;
    }
    case SCR_SETTINGS:
        vph_out_num(o, "lo", app.cfg.lo, 1);
        vph_out_num(o, "hi", app.cfg.hi, 1);
        for (int i = 0; i < SLOT_COUNT; i++) {
            const slot_t *sl = &app.cfg.slots[i];
            snprintf(id, sizeof(id), "s%d_en", i + 1);
            vph_out_bool(o, id, sl->en);
            snprintf(id, sizeof(id), "s%d_days", i + 1);
            vph_out_int(o, id, sl->days);
            snprintf(id, sizeof(id), "s%d_on", i + 1);
            vph_out_str(o, id, sl->on);
            snprintf(id, sizeof(id), "s%d_off", i + 1);
            vph_out_str(o, id, sl->off);
        }
        break;
    }
}

// ---------- Ghi ----------

static bool json_bool(const cJSON *v, bool *out)
{
    if (cJSON_IsBool(v)) *out = cJSON_IsTrue(v);
    else if (cJSON_IsNumber(v)) *out = v->valuedouble != 0;
    else return false;
    return true;
}

static bool valid_hhmm(const char *s)
{
    return s && strlen(s) == 5 && s[2] == ':' &&
           s[0] >= '0' && s[0] <= '2' && s[1] >= '0' && s[1] <= '9' &&
           s[3] >= '0' && s[3] <= '5' && s[4] >= '0' && s[4] <= '9' &&
           (s[0] - '0') * 10 + (s[1] - '0') <= 23;
}

// Ghi mot truong (man live va id danh rieng). Chay trong task chinh.
static int on_write(const char *id, const cJSON *v, char *err, size_t err_len)
{
    if (!strcmp(id, "led")) {
        if (!json_bool(v, &app.led)) {
            strlcpy(err, "Giá trị phải là bật hoặc tắt", err_len);
            return VPH_ERR_REJECT;
        }
        return VPH_OK;
    }
    if (!strcmp(id, "color")) {
        const char *c = cJSON_IsString(v) ? v->valuestring : "";
        if (strcmp(c, "red") && strcmp(c, "green") && strcmp(c, "blue") && strcmp(c, "white")) {
            strlcpy(err, "Màu không hợp lệ", err_len);
            return VPH_ERR_REJECT;
        }
        if (!app.led) {
            strlcpy(err, "Phải bật đèn trước khi đổi màu", err_len);
            return VPH_ERR_REJECT;
        }
        strlcpy(app.color, c, sizeof(app.color));
        return VPH_OK;
    }
    if (!strcmp(id, "beep")) {
        app.beep_until = esp_timer_get_time() + 1000000;
        return VPH_OK;
    }
    if (!strcmp(id, "_name")) {
        // Component da kiem tra ten hop le; o day chi luu de lan sau khoi dong con giu
        if (storage_save_name(v->valuestring) != ESP_OK) {
            strlcpy(err, "Không lưu được tên", err_len);
            return VPH_ERR_REJECT;
        }
        return VPH_OK;
    }
    if (!strcmp(id, "_reboot")) {
        storage_save_cfg();     // luu ngay truoc khi component reset sau 0,5 s
        return VPH_OK;
    }
    // "_time": component da dat gio he thong; thiet bi nay khong co RTC nen khong lam gi them
    return VPH_ERR_UNKNOWN;
}

// Ghi theo lo (man batch): ap TAT CA len ban sao -> kiem tra -> hop le moi luu
static int on_batch(const cJSON *set, char *err, size_t err_len)
{
    cfg_t c = app.cfg;
    const cJSON *it;
    cJSON_ArrayForEach(it, set) {
        const char *id = it->string;
        int n = 0;
        char what[8] = "";
        if (!strcmp(id, "lo") && cJSON_IsNumber(it)) {
            c.lo = (float)it->valuedouble;
        } else if (!strcmp(id, "hi") && cJSON_IsNumber(it)) {
            c.hi = (float)it->valuedouble;
        } else if (sscanf(id, "s%d_%7s", &n, what) == 2 && n >= 1 && n <= SLOT_COUNT) {
            slot_t *sl = &c.slots[n - 1];
            if (!strcmp(what, "en")) {
                if (!json_bool(it, &sl->en)) goto bad_value;
            } else if (!strcmp(what, "days")) {
                if (!cJSON_IsNumber(it) || it->valuedouble < 0 || it->valuedouble > 127) goto bad_value;
                sl->days = (uint8_t)it->valuedouble;
            } else if (!strcmp(what, "on") || !strcmp(what, "off")) {
                if (!cJSON_IsString(it) || !valid_hhmm(it->valuestring)) {
                    strlcpy(err, "Giờ phải dạng HH:MM", err_len);
                    return VPH_ERR_REJECT;
                }
                strlcpy(what[1] == 'n' ? sl->on : sl->off, it->valuestring, sizeof(sl->on));
            } else {
                snprintf(err, err_len, "Không có trường %s", id);
                return VPH_ERR_REJECT;
            }
        } else {
            snprintf(err, err_len, "Không có trường %s", id);
            return VPH_ERR_REJECT;
        }
        continue;
    bad_value:
        snprintf(err, err_len, "Giá trị của %s không hợp lệ", id);
        return VPH_ERR_REJECT;
    }
    // Kiem tra rang buoc tren ca cau hinh moi, sai thi giu nguyen cau hinh cu
    if (c.lo < 0 || c.hi > 100) {
        strlcpy(err, "Ngưỡng phải trong khoảng 0-100 °C", err_len);
        return VPH_ERR_REJECT;
    }
    if (!(c.lo < c.hi)) {
        strlcpy(err, "Ngưỡng thấp phải nhỏ hơn ngưỡng cao", err_len);
        return VPH_ERR_REJECT;
    }
    for (int i = 0; i < SLOT_COUNT; i++) {
        if (c.slots[i].en && c.slots[i].days == 0) {
            snprintf(err, err_len, "Khung %d đang bật nhưng chưa chọn thứ nào", i + 1);
            return VPH_ERR_REJECT;
        }
    }
    app.cfg = c;
    app.save_cfg = true;    // ghi NVS trong vong lap chinh
    return VPH_OK;
}

// ---------- app_main ----------

void app_main(void)
{
    esp_err_t e = nvs_flash_init();
    if (e == ESP_ERR_NVS_NO_FREE_PAGES || e == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        e = nvs_flash_init();
    }
    if (e != ESP_OK) ESP_LOGE(TAG, "NVS loi: %s", esp_err_to_name(e));
    setenv("TZ", "ICT-7", 1);
    tzset();
    led_init();
    storage_load();

    static const char *const hdr[] = {"t", "led", NULL};
    const vph_info_t info = {
        .model = "vphdemo",
        .fw = "1.0.0",
        .hw = "esp32c3",
        .icon = "light",
        .hdr = hdr,
        .caps = VPH_CAP_TIME,
        .name_prefix = "VPH-DEMO",
    };
    cJSON *screens[SCR_COUNT] = {
        [SCR_OVERVIEW] = build_overview(),
        [SCR_SETTINGS] = build_settings(),
    };
    e = vph_init(&info, screens, SCR_COUNT, fill_values, on_write, on_batch);
    if (e != ESP_OK) ESP_LOGE(TAG, "vph_init loi: %s", esp_err_to_name(e));

    int64_t next_sample = 0;
    float phase = 0;
    while (1) {
        int64_t now = esp_timer_get_time();
        if (now >= next_sample) {
            // Nhiet do gia: song sin cham quanh 28 do + nhieu nho
            next_sample = now + 1000000;
            phase += 0.05f;
            app.temp = 28.0f + 3.0f * sinf(phase) + ((int)(esp_random() % 21) - 10) / 50.0f;
        }
        if (app.save_cfg) {
            app.save_cfg = false;
            if (storage_save_cfg() != ESP_OK) ESP_LOGE(TAG, "Khong luu duoc cau hinh");
            else ESP_LOGI(TAG, "Da luu cau hinh");
        }
        led_update(now);
        vph_poll();
        vTaskDelay(pdMS_TO_TICKS(50));
    }
}
