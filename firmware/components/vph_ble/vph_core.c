#include "vph_core.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include "esp_log.h"

static const char *TAG = "vph";

#define MAX_KEYS 64

struct vph_out {
    char *buf;
    size_t cap;
    size_t len;
    bool overflow;
    uint8_t nkeys;
    uint16_t key_off[MAX_KEYS];
    uint8_t key_len[MAX_KEYS];
};

typedef struct {
    vph_info_t info;
    int n;
    char *schema[VPH_MAX_SCREENS];
    size_t schema_len[VPH_MAX_SCREENS];
    char sch[5];
    char name[VPH_NAME_MAX + 1];
    char info_json[VPH_MAX_INFO + 64];
    vph_values_cb vcb;
    vph_write_cb wcb;
    vph_batch_cb bcb;
    bool ready;
    uint32_t warned_values;     // bit i: da canh bao VALUES man i qua dai
} core_t;

static core_t s;

// ---------- Dung schema ----------

cJSON *vph_screen(const char *id, const char *title, const char *save)
{
    cJSON *r = cJSON_CreateObject();
    if (!r) return NULL;
    cJSON_AddStringToObject(r, "id", id);
    cJSON_AddStringToObject(r, "l", title);
    cJSON_AddStringToObject(r, "save", save ? save : "live");
    cJSON_AddArrayToObject(r, "f");
    return r;
}

cJSON *vph_field(cJSON *screen, const char *id, const char *label, const char *type)
{
    cJSON *arr = cJSON_GetObjectItemCaseSensitive(screen, "f");
    cJSON *f = cJSON_CreateObject();
    if (!arr || !f) {
        cJSON_Delete(f);
        return NULL;
    }
    cJSON_AddStringToObject(f, "id", id);
    cJSON_AddStringToObject(f, "l", label);
    cJSON_AddStringToObject(f, "t", type);
    cJSON_AddItemToArray(arr, f);
    return f;
}

void vph_range(cJSON *f, double min, double max, double step)
{
    cJSON_AddNumberToObject(f, "min", min);
    cJSON_AddNumberToObject(f, "max", max);
    if (step > 0) cJSON_AddNumberToObject(f, "st", step);
}

void vph_unit(cJSON *f, const char *u) { cJSON_AddStringToObject(f, "u", u); }
void vph_dp(cJSON *f, int dp) { cJSON_AddNumberToObject(f, "dp", dp); }
void vph_readonly(cJSON *f) { cJSON_AddNumberToObject(f, "ro", 1); }
void vph_nullable(cJSON *f) { cJSON_AddNumberToObject(f, "nul", 1); }
void vph_hint(cJSON *f, const char *w) { cJSON_AddStringToObject(f, "w", w); }
void vph_confirm(cJSON *f, const char *question) { cJSON_AddStringToObject(f, "c", question); }
void vph_show_if(cJSON *f, const char *cond) { cJSON_AddStringToObject(f, "if", cond); }
void vph_enable_if(cJSON *f, const char *cond) { cJSON_AddStringToObject(f, "en", cond); }
void vph_group(cJSON *f, const char *name) { cJSON_AddStringToObject(f, "g", name); }
void vph_maxlen(cJSON *f, int max) { cJSON_AddNumberToObject(f, "max", max); }

void vph_options(cJSON *f, const char *const *vals, const char *const *labels, int n)
{
    cJSON *opt = cJSON_AddArrayToObject(f, "opt");
    for (int i = 0; i < n; i++) {
        cJSON *pair = cJSON_CreateArray();
        cJSON_AddItemToArray(pair, cJSON_CreateString(vals[i]));
        cJSON_AddItemToArray(pair, cJSON_CreateString(labels[i]));
        cJSON_AddItemToArray(opt, pair);
    }
}

void vph_options_num(cJSON *f, const double *vals, const char *const *labels, int n)
{
    cJSON *opt = cJSON_AddArrayToObject(f, "opt");
    for (int i = 0; i < n; i++) {
        cJSON *pair = cJSON_CreateArray();
        cJSON_AddItemToArray(pair, cJSON_CreateNumber(vals[i]));
        cJSON_AddItemToArray(pair, cJSON_CreateString(labels[i]));
        cJSON_AddItemToArray(opt, pair);
    }
}

void vph_flag_labels(cJSON *f, const char *const *labels, int n)
{
    cJSON *opt = cJSON_AddArrayToObject(f, "opt");
    for (int i = 0; i < n; i++) cJSON_AddItemToArray(opt, cJSON_CreateString(labels[i]));
}

cJSON *vph_repeat(cJSON *screen, int n, const char *pfx, const char *label)
{
    cJSON *rep = cJSON_AddObjectToObject(screen, "rep");
    if (!rep) return NULL;
    cJSON_AddNumberToObject(rep, "n", n);
    cJSON_AddStringToObject(rep, "pfx", pfx);
    if (label) cJSON_AddStringToObject(rep, "l", label);
    cJSON_AddArrayToObject(rep, "f");
    return rep;
}

void vph_repeat_count(cJSON *rep, const char *cnt_id) { cJSON_AddStringToObject(rep, "cnt", cnt_id); }

// ---------- CRC16 (Modbus, da thuc 0xA001) ----------

uint16_t vph_crc16(const uint8_t *data, size_t len, uint16_t crc)
{
    for (size_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (int b = 0; b < 8; b++) crc = (crc & 1) ? (crc >> 1) ^ 0xA001 : crc >> 1;
    }
    return crc;
}

// ---------- VALUES ----------

static void out_raw(vph_out_t *o, const char *s, size_t n)
{
    if (o->overflow) return;
    if (o->len + n + 2 > o->cap) {      // chua cho cho '}' va '\0'
        o->overflow = true;
        return;
    }
    memcpy(o->buf + o->len, s, n);
    o->len += n;
}

// Mo mot khoa. Tra false neu id da co (truong hdr trung voi truong cua man hinh) hoac het cho.
static bool out_key(vph_out_t *o, const char *id)
{
    size_t idl = strlen(id);
    for (int i = 0; i < o->nkeys; i++) {
        if (o->key_len[i] == idl && memcmp(o->buf + o->key_off[i], id, idl) == 0) return false;
    }
    if (o->overflow) return false;
    size_t mark = o->len;
    if (o->len > 1) out_raw(o, ",", 1);
    out_raw(o, "\"", 1);
    size_t at = o->len;
    out_raw(o, id, idl);
    out_raw(o, "\":", 2);
    if (o->overflow) {
        o->len = mark;
        return false;
    }
    if (o->nkeys < MAX_KEYS && idl < 256) {
        o->key_off[o->nkeys] = (uint16_t)at;
        o->key_len[o->nkeys] = (uint8_t)idl;
        o->nkeys++;
    }
    return true;
}

// Ghi gia tri cho khoa vua mo; neu tran thi bo ca khoa de JSON van hop le
static void out_val(vph_out_t *o, size_t mark, const char *s, size_t n)
{
    out_raw(o, s, n);
    if (o->overflow) {
        o->len = mark;
        if (o->nkeys) o->nkeys--;
    }
}

#define OUT_BEGIN(o, id)                    \
    size_t mark = (o)->len;                 \
    if (!out_key((o), (id))) return

void vph_out_null(vph_out_t *o, const char *id)
{
    OUT_BEGIN(o, id);
    out_val(o, mark, "null", 4);
}

void vph_out_num(vph_out_t *o, const char *id, double v, int dp)
{
    if (isnan(v) || isinf(v)) {
        vph_out_null(o, id);
        return;
    }
    OUT_BEGIN(o, id);
    char t[32];
    if (dp < 0) dp = 0;
    if (dp > 6) dp = 6;
    int n = snprintf(t, sizeof(t), "%.*f", dp, v);
    out_val(o, mark, t, (size_t)n);
}

void vph_out_int(vph_out_t *o, const char *id, long v)
{
    OUT_BEGIN(o, id);
    char t[24];
    int n = snprintf(t, sizeof(t), "%ld", v);
    out_val(o, mark, t, (size_t)n);
}

void vph_out_bool(vph_out_t *o, const char *id, bool v)
{
    OUT_BEGIN(o, id);
    out_val(o, mark, v ? "true" : "false", v ? 4 : 5);
}

void vph_out_str(vph_out_t *o, const char *id, const char *str)
{
    if (!str) {
        vph_out_null(o, id);
        return;
    }
    OUT_BEGIN(o, id);
    out_raw(o, "\"", 1);
    for (const unsigned char *p = (const unsigned char *)str; *p; p++) {
        if (*p == '"' || *p == '\\') {
            char e[2] = {'\\', (char)*p};
            out_raw(o, e, 2);
        } else if (*p < 0x20) {
            out_raw(o, " ", 1);     // ky tu dieu khien: thay bang dau cach
        } else {
            out_raw(o, (const char *)p, 1);
        }
    }
    out_val(o, mark, "\"", 1);
}

size_t vph_core_values(int screen, char *buf, size_t cap)
{
    if (cap < 3) return 0;
    if (!s.ready || screen < 0 || screen >= s.n) {
        memcpy(buf, "{}", 3);
        return 2;
    }
    vph_out_t o = {.buf = buf, .cap = cap, .len = 0};
    buf[o.len++] = '{';
    if (s.vcb) {
        s.vcb((uint8_t)screen, &o);
        // Truong dau trang luon co trong VALUES cua moi man hinh; trung id thi bo qua
        if (s.info.hdr) s.vcb(VPH_SCREEN_HDR, &o);
    }
    buf[o.len++] = '}';
    buf[o.len] = '\0';
    if ((o.len > VPH_MAX_VALUES || o.overflow) && !(s.warned_values & (1u << screen))) {
        s.warned_values |= 1u << screen;
        ESP_LOGW(TAG, "VALUES man %d = %d byte%s, vuot %d (PROTOCOL 8): tach man hinh hoac rut id",
                 screen, (int)o.len, o.overflow ? " (bi cat)" : "", VPH_MAX_VALUES);
    }
    return o.len;
}

// ---------- INFO ----------

static void build_info(void)
{
    cJSON *j = cJSON_CreateObject();
    cJSON_AddStringToObject(j, "proto", "vph");
    cJSON_AddNumberToObject(j, "pv", VPH_PROTO_VERSION);
    cJSON_AddStringToObject(j, "model", s.info.model);
    cJSON_AddStringToObject(j, "name", s.name);
    cJSON_AddStringToObject(j, "fw", s.info.fw ? s.info.fw : "0.0.0");
    if (s.info.hw) cJSON_AddStringToObject(j, "hw", s.info.hw);
    cJSON_AddNumberToObject(j, "n", s.n);
    cJSON_AddStringToObject(j, "sch", s.sch);
    if (s.info.hdr) {
        cJSON *h = cJSON_AddArrayToObject(j, "hdr");
        for (const char *const *p = s.info.hdr; *p; p++) cJSON_AddItemToArray(h, cJSON_CreateString(*p));
    }
    if (s.info.caps) {
        cJSON *c = cJSON_AddArrayToObject(j, "caps");
        if (s.info.caps & VPH_CAP_TIME) cJSON_AddItemToArray(c, cJSON_CreateString("time"));
    }
    if (s.info.icon) cJSON_AddStringToObject(j, "icon", s.info.icon);
    if (!cJSON_PrintPreallocated(j, s.info_json, sizeof(s.info_json), false)) {
        ESP_LOGE(TAG, "INFO qua dai, khong dung duoc");
        strcpy(s.info_json, "{}");
    }
    cJSON_Delete(j);
    size_t len = strlen(s.info_json);
    if (len > VPH_MAX_INFO) ESP_LOGW(TAG, "INFO = %d byte, vuot %d (PROTOCOL 8)", (int)len, VPH_MAX_INFO);
}

const char *vph_core_info(void) { return s.ready ? s.info_json : "{}"; }
const char *vph_core_sch(void) { return s.sch; }
int vph_core_screen_count(void) { return s.n; }

// ---------- Ten ----------

static bool name_valid(const char *name)
{
    size_t n = name ? strlen(name) : 0;
    if (n < 1 || n > VPH_NAME_MAX) return false;
    for (size_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char)name[i];
        if (c < 0x20 || c > 0x7E || c == '"' || c == '\\') return false;
    }
    return true;
}

esp_err_t vph_core_set_name(const char *name)
{
    if (!name_valid(name)) return ESP_ERR_INVALID_ARG;
    strlcpy(s.name, name, sizeof(s.name));
    if (s.ready) build_info();
    return ESP_OK;
}

const char *vph_core_name(void) { return s.name; }

// ---------- Schema ----------

const char *vph_core_schema(int screen)
{
    return (s.ready && screen >= 0 && screen < s.n) ? s.schema[screen] : "{}";
}

size_t vph_core_schema_page(int screen, int page, const char **p)
{
    const char *all = vph_core_schema(screen);
    size_t len = strlen(all);
    size_t from = (size_t)(page < 0 ? 0 : page) * VPH_SCHEMA_PAGE;
    if (from >= len) {
        *p = all + len;
        return 0;
    }
    *p = all + from;
    return len - from > VPH_SCHEMA_PAGE ? VPH_SCHEMA_PAGE : len - from;
}

void vph_core_deinit(void)
{
    for (int i = 0; i < VPH_MAX_SCREENS; i++) {
        if (s.schema[i]) cJSON_free(s.schema[i]);
    }
    memset(&s, 0, sizeof(s));
}

esp_err_t vph_core_init(const vph_info_t *info, cJSON *const *screens, int n,
                        vph_values_cb vcb, vph_write_cb wcb, vph_batch_cb bcb)
{
    if (!info || !info->model || !screens || n < 1 || n > VPH_MAX_SCREENS || !vcb) return ESP_ERR_INVALID_ARG;
    char keep[VPH_NAME_MAX + 1];
    strlcpy(keep, s.name, sizeof(keep));
    vph_core_deinit();
    s.info = *info;
    s.n = n;
    s.vcb = vcb;
    s.wcb = wcb;
    s.bcb = bcb;
    uint16_t crc = 0xFFFF;
    for (int i = 0; i < n; i++) {
        char *js = screens[i] ? cJSON_PrintUnformatted(screens[i]) : NULL;
        cJSON_Delete(screens[i]);
        if (!js) {
            ESP_LOGE(TAG, "Khong dung duoc schema man %d", i);
            // Giai phong cac man con lai roi bao loi
            for (int k = i + 1; k < n; k++) cJSON_Delete(screens[k]);
            vph_core_deinit();
            return ESP_ERR_NO_MEM;
        }
        s.schema[i] = js;
        s.schema_len[i] = strlen(js);
        crc = vph_crc16((const uint8_t *)js, s.schema_len[i], crc);
        ESP_LOGI(TAG, "schema[%d] = %d byte, %d trang", i, (int)s.schema_len[i],
                 (int)(s.schema_len[i] / VPH_SCHEMA_PAGE + 1));
        if (s.schema_len[i] > VPH_MAX_SCHEMA) {
            ESP_LOGW(TAG, "schema[%d] vuot %d byte (PROTOCOL 8): tach man hinh", i, VPH_MAX_SCHEMA);
        }
    }
    snprintf(s.sch, sizeof(s.sch), "%04x", crc);
    if (name_valid(keep)) {
        strlcpy(s.name, keep, sizeof(s.name));
    } else {
        // Ten tam, vph_init se thay bang <TIEN TO>-<4 hex MAC>
        size_t i = 0;
        const char *src = info->name_prefix ? info->name_prefix : info->model;
        for (; src[i] && i < VPH_NAME_MAX; i++) {
            char c = src[i];
            s.name[i] = (!info->name_prefix && c >= 'a' && c <= 'z') ? (char)(c - 32) : c;
        }
        s.name[i] = '\0';
    }
    s.ready = true;
    build_info();
    return ESP_OK;
}

// ---------- WRITE ----------

// Cat chuoi UTF-8 con toi da max byte, khong cat giua ky tu
static void utf8_trunc(char *str, size_t max)
{
    size_t n = strlen(str);
    if (n <= max) return;
    n = max;
    while (n > 0 && ((unsigned char)str[n] & 0xC0) == 0x80) n--;
    str[n] = '\0';
}

static void make_result(char *result, size_t cap, int q, const char *err)
{
    cJSON *j = cJSON_CreateObject();
    cJSON_AddNumberToObject(j, "q", q);
    cJSON_AddNumberToObject(j, "ok", err ? 0 : 1);
    if (err) cJSON_AddStringToObject(j, "err", err);
    if (!cJSON_PrintPreallocated(j, result, (int)cap, false)) {
        snprintf(result, cap, "{\"q\":%d,\"ok\":%d}", q, err ? 0 : 1);
    }
    cJSON_Delete(j);
}

int vph_core_handle_write(const char *json, char *result, size_t result_cap)
{
    char err[VPH_MAX_ERR + 16] = "";
    int act = 0;
    int q = 0;
    int rc = VPH_ERR_REJECT;
    cJSON *root = cJSON_Parse(json);
    const cJSON *jq = cJSON_GetObjectItemCaseSensitive(root, "q");
    if (cJSON_IsNumber(jq)) q = jq->valueint;
    const cJSON *set = cJSON_GetObjectItemCaseSensitive(root, "set");
    const cJSON *jid = cJSON_GetObjectItemCaseSensitive(root, "id");
    const cJSON *v = cJSON_GetObjectItemCaseSensitive(root, "v");

    if (!cJSON_IsObject(root)) {
        strlcpy(err, "Lệnh sai định dạng", sizeof(err));
    } else if (cJSON_IsObject(set)) {
        // Ghi theo lo
        if (!s.bcb) {
            strlcpy(err, "Thiết bị không nhận ghi theo lô", sizeof(err));
        } else {
            rc = s.bcb(set, err, VPH_MAX_ERR + 1);
            if (rc == VPH_ERR_UNKNOWN && !err[0]) strlcpy(err, "Có trường không tồn tại", sizeof(err));
        }
    } else if (cJSON_IsString(jid) && v) {
        const char *id = jid->valuestring;
        bool reserved = id[0] == '_';
        if (!strcmp(id, "_time")) {
            double e = cJSON_IsNumber(v) ? v->valuedouble : 0;
            if (e < 1700000000.0 || e > 4102444800.0) {
                strlcpy(err, "Giờ không hợp lệ", sizeof(err));
                goto done;
            }
            struct timeval tv = {.tv_sec = (time_t)e, .tv_usec = 0};
            settimeofday(&tv, NULL);
        } else if (!strcmp(id, "_name")) {
            if (!cJSON_IsString(v) || !name_valid(v->valuestring)) {
                strlcpy(err, "Tên phải 1-20 ký tự ASCII, không có \" và \\", sizeof(err));
                goto done;
            }
        } else if (!strcmp(id, "_reboot")) {
            // khong can kiem tra gia tri
        } else if (reserved) {
            snprintf(err, sizeof(err), "Không có trường %s", id);
            goto done;
        }
        rc = s.wcb ? s.wcb(id, v, err, VPH_MAX_ERR + 1) : VPH_ERR_UNKNOWN;
        if (rc == VPH_ERR_UNKNOWN) {
            if (reserved) {
                rc = VPH_OK;    // project khong can lam gi them
                err[0] = '\0';
            } else {
                snprintf(err, sizeof(err), "Không có trường %s", id);
            }
        }
        if (rc == VPH_OK) {
            if (!strcmp(id, "_name")) {
                vph_core_set_name(v->valuestring);
                act |= VPH_ACT_RENAME;
            } else if (!strcmp(id, "_reboot")) {
                act |= VPH_ACT_REBOOT;
            }
        }
    } else {
        strlcpy(err, "Lệnh thiếu id hoặc v", sizeof(err));
    }

done:
    if (rc == VPH_OK) {
        act |= VPH_ACT_OK;
        make_result(result, result_cap, q, NULL);
    } else {
        if (!err[0]) strlcpy(err, "Thiết bị từ chối lệnh", sizeof(err));
        utf8_trunc(err, VPH_MAX_ERR);
        make_result(result, result_cap, q, err);
    }
    cJSON_Delete(root);
    return act;
}
