// Unity test cho phan loi cua vph_ble: dung schema, kich thuoc, ghep VALUES,
// parse WRITE don/lo, id danh rieng, CRC. Chay tren chip, khong can ket noi BLE.
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include "unity.h"
#include "vph_core.h"

// ---------- Thiet bi gia dung cho test ----------

static struct {
    double sv;
    bool out;
    double lo, hi;
    char last_id[24];
    int writes, batches;
    char saved_name[24];
    bool reboot_seen;
    bool big_values;        // dien VALUES rat dai de thu canh bao / cat
} dev;

static void fill(uint8_t screen, vph_out_t *o)
{
    if (screen == VPH_SCREEN_HDR) {
        vph_out_num(o, "t", 28.44, 1);
        vph_out_bool(o, "out", dev.out);
        return;
    }
    if (screen == 0) {
        vph_out_num(o, "t", 28.44, 1);
        vph_out_num(o, "sv", dev.sv, 0);
        vph_out_bool(o, "out", dev.out);
        vph_out_str(o, "msg", "Xin \"chao\" \\ nhe");
        vph_out_null(o, "h");
        vph_out_num(o, "bad", 0.0 / 0.0, 1);
    } else if (screen == 1) {
        vph_out_num(o, "lo", dev.lo, 1);
        vph_out_num(o, "hi", dev.hi, 1);
        vph_out_int(o, "days", 127);
        if (dev.big_values) {
            char id[16];
            for (int i = 0; i < 40; i++) {
                snprintf(id, sizeof(id), "truong_dai_%02d", i);
                vph_out_str(o, id, "gia tri kha dai");
            }
        }
    }
}

static int on_write(const char *id, const cJSON *v, char *err, size_t err_len)
{
    dev.writes++;
    strlcpy(dev.last_id, id, sizeof(dev.last_id));
    if (!strcmp(id, "sv")) {
        if (!cJSON_IsNumber(v) || v->valuedouble > 1200) {
            strlcpy(err, "Nhiệt độ đặt tối đa 1200 °C", err_len);
            return VPH_ERR_REJECT;
        }
        dev.sv = v->valuedouble;
        return VPH_OK;
    }
    if (!strcmp(id, "out")) {
        dev.out = cJSON_IsTrue(v) || (cJSON_IsNumber(v) && v->valuedouble != 0);
        return VPH_OK;
    }
    if (!strcmp(id, "silent_fail")) return VPH_ERR_REJECT;      // tu choi ma khong ghi ly do
    if (!strcmp(id, "long_err")) {
        // Loi dai hon 80 byte, toan chu co dau (2-3 byte/ky tu)
        strlcpy(err, "Lỗi rất dài để thử cắt chuỗi ở đúng ranh giới ký tự tiếng Việt có dấu đầy đủ ạ", err_len);
        return VPH_ERR_REJECT;
    }
    if (!strcmp(id, "_name")) {
        strlcpy(dev.saved_name, v->valuestring, sizeof(dev.saved_name));
        return VPH_OK;
    }
    if (!strcmp(id, "_reboot")) {
        dev.reboot_seen = true;
        return VPH_OK;
    }
    return VPH_ERR_UNKNOWN;
}

static int on_batch(const cJSON *set, char *err, size_t err_len)
{
    dev.batches++;
    double lo = dev.lo, hi = dev.hi;
    const cJSON *it;
    cJSON_ArrayForEach(it, set) {
        if (!strcmp(it->string, "lo")) lo = it->valuedouble;
        else if (!strcmp(it->string, "hi")) hi = it->valuedouble;
        else {
            snprintf(err, err_len, "Không có trường %s", it->string);
            return VPH_ERR_REJECT;
        }
    }
    if (!(lo < hi)) {
        strlcpy(err, "Ngưỡng thấp phải nhỏ hơn ngưỡng cao", err_len);
        return VPH_ERR_REJECT;
    }
    dev.lo = lo;
    dev.hi = hi;
    return VPH_OK;
}

static cJSON *screen_overview(void)
{
    cJSON *s = vph_screen("overview", "Tổng quan", "live");
    cJSON *t = vph_field(s, "t", "Nhiệt độ", "num");
    vph_unit(t, "°C");
    vph_dp(t, 1);
    vph_readonly(t);
    vph_hint(t, "trend");
    cJSON *sv = vph_field(s, "sv", "Nhiệt độ đặt", "num");
    vph_range(sv, 0, 1200, 1);
    cJSON *mode = vph_field(s, "mode", "Chế độ", "enum");
    static const char *const vals[] = {"manual", "auto"};
    static const char *const labels[] = {"Tay", "Tự động"};
    vph_options(mode, vals, labels, 2);
    cJSON *out = vph_field(s, "out", "Relay", "bool");
    vph_enable_if(out, "mode==manual");
    cJSON *al = vph_field(s, "alarm", "Báo động", "flags");
    static const char *const bits[] = {"Mất cảm biến", "Chưa có giờ"};
    vph_flag_labels(al, bits, 2);
    cJSON *si = vph_field(s, "silence", "Tắt còi", "act");
    vph_show_if(si, "alarm!=0");
    vph_confirm(si, "Tắt còi?");
    return s;
}

// Man batch co khoi lap va rat nhieu truong, de schema dai hon 1 trang
static cJSON *screen_settings(int extra_fields)
{
    cJSON *s = vph_screen("settings", "Cài đặt", "batch");
    cJSON *lo = vph_field(s, "lo", "Ngưỡng thấp", "num");
    vph_group(lo, "Ngưỡng");
    vph_nullable(lo);
    vph_field(s, "hi", "Ngưỡng cao", "num");
    char id[16], label[40];
    for (int i = 0; i < extra_fields; i++) {
        snprintf(id, sizeof(id), "x%d", i);
        snprintf(label, sizeof(label), "Trường phụ số %d", i);
        vph_field(s, id, label, "num");
    }
    cJSON *rep = vph_repeat(s, 5, "s", "Khung");
    vph_repeat_count(rep, "count");
    vph_field(rep, "en", "Bật", "bool");
    vph_field(rep, "days", "Thứ", "days");
    vph_field(rep, "on", "Giờ bật", "time");
    return s;
}

static const char *const HDR[] = {"t", "out", NULL};

static void setup(int extra_fields)
{
    memset(&dev, 0, sizeof(dev));
    dev.sv = 100;
    dev.lo = 20;
    dev.hi = 35;
    const vph_info_t info = {
        .model = "c3relay", .fw = "1.1.0", .hw = "esp32c3", .icon = "relay", .domain = "agri",
        .hdr = HDR, .caps = VPH_CAP_TIME, .name_prefix = "C3-RELAY",
    };
    cJSON *screens[2] = {screen_overview(), screen_settings(extra_fields)};
    vph_core_deinit();
    TEST_ASSERT_EQUAL(ESP_OK, vph_core_init(&info, screens, 2, fill, on_write, on_batch));
    TEST_ASSERT_EQUAL(ESP_OK, vph_core_set_name("C3-RELAY-A1B2"));
}

static cJSON *parse(const char *s)
{
    cJSON *j = cJSON_Parse(s);
    TEST_ASSERT_NOT_NULL_MESSAGE(j, s);
    return j;
}

static const char *str_of(const cJSON *j, const char *key)
{
    const cJSON *v = cJSON_GetObjectItemCaseSensitive(j, key);
    return cJSON_IsString(v) ? v->valuestring : "";
}

static double num_of(const cJSON *j, const char *key)
{
    const cJSON *v = cJSON_GetObjectItemCaseSensitive(j, key);
    return cJSON_IsNumber(v) ? v->valuedouble : -9999;
}

// ---------- INFO ----------

TEST_CASE("INFO: du khoa, dung gia tri, duoi 240 byte", "[info]")
{
    setup(0);
    const char *info = vph_core_info();
    TEST_ASSERT_LESS_OR_EQUAL(VPH_MAX_INFO, strlen(info));
    cJSON *j = parse(info);
    TEST_ASSERT_EQUAL_STRING("vph", str_of(j, "proto"));
    TEST_ASSERT_EQUAL(1, (int)num_of(j, "pv"));
    TEST_ASSERT_EQUAL_STRING("c3relay", str_of(j, "model"));
    TEST_ASSERT_EQUAL_STRING("C3-RELAY-A1B2", str_of(j, "name"));
    TEST_ASSERT_EQUAL_STRING("1.1.0", str_of(j, "fw"));
    TEST_ASSERT_EQUAL_STRING("esp32c3", str_of(j, "hw"));
    TEST_ASSERT_EQUAL(2, (int)num_of(j, "n"));
    TEST_ASSERT_EQUAL_STRING("relay", str_of(j, "icon"));
    TEST_ASSERT_EQUAL_STRING("agri", str_of(j, "dom"));
    TEST_ASSERT_EQUAL_STRING(vph_core_sch(), str_of(j, "sch"));
    TEST_ASSERT_EQUAL(4, strlen(vph_core_sch()));
    const cJSON *hdr = cJSON_GetObjectItemCaseSensitive(j, "hdr");
    TEST_ASSERT_EQUAL(2, cJSON_GetArraySize(hdr));
    TEST_ASSERT_EQUAL_STRING("out", cJSON_GetArrayItem(hdr, 1)->valuestring);
    const cJSON *caps = cJSON_GetObjectItemCaseSensitive(j, "caps");
    TEST_ASSERT_EQUAL_STRING("time", cJSON_GetArrayItem(caps, 0)->valuestring);
    cJSON_Delete(j);
}

TEST_CASE("INFO: tham so sai bi tu choi", "[info]")
{
    const vph_info_t info = {.model = "x", .fw = "1.0.0"};
    cJSON *one[1] = {vph_screen("a", "A", "live")};
    vph_core_deinit();
    TEST_ASSERT_EQUAL(ESP_ERR_INVALID_ARG, vph_core_init(NULL, one, 1, fill, on_write, NULL));
    TEST_ASSERT_EQUAL(ESP_ERR_INVALID_ARG, vph_core_init(&info, one, 0, fill, on_write, NULL));
    TEST_ASSERT_EQUAL(ESP_ERR_INVALID_ARG, vph_core_init(&info, one, VPH_MAX_SCREENS + 1, fill, on_write, NULL));
    TEST_ASSERT_EQUAL(ESP_ERR_INVALID_ARG, vph_core_init(&info, one, 1, NULL, on_write, NULL));
    // Hop le: ten mac dinh la model viet hoa (vph_init se them 4 hex MAC)
    TEST_ASSERT_EQUAL(ESP_OK, vph_core_init(&info, one, 1, fill, on_write, NULL));
    TEST_ASSERT_EQUAL_STRING("X", vph_core_name());
}

// ---------- SCHEMA ----------

TEST_CASE("schema: khoa ngan dung PROTOCOL 5", "[schema]")
{
    setup(0);
    cJSON *j = parse(vph_core_schema(0));
    TEST_ASSERT_EQUAL_STRING("overview", str_of(j, "id"));
    TEST_ASSERT_EQUAL_STRING("Tổng quan", str_of(j, "l"));
    TEST_ASSERT_EQUAL_STRING("live", str_of(j, "save"));
    const cJSON *f = cJSON_GetObjectItemCaseSensitive(j, "f");
    TEST_ASSERT_EQUAL(6, cJSON_GetArraySize(f));
    const cJSON *t = cJSON_GetArrayItem(f, 0);
    TEST_ASSERT_EQUAL_STRING("t", str_of(t, "id"));
    TEST_ASSERT_EQUAL_STRING("num", str_of(t, "t"));
    TEST_ASSERT_EQUAL_STRING("°C", str_of(t, "u"));
    TEST_ASSERT_EQUAL(1, (int)num_of(t, "dp"));
    TEST_ASSERT_EQUAL(1, (int)num_of(t, "ro"));
    TEST_ASSERT_EQUAL_STRING("trend", str_of(t, "w"));
    const cJSON *sv = cJSON_GetArrayItem(f, 1);
    TEST_ASSERT_EQUAL(1200, (int)num_of(sv, "max"));
    TEST_ASSERT_EQUAL(1, (int)num_of(sv, "st"));
    const cJSON *opt = cJSON_GetObjectItemCaseSensitive(cJSON_GetArrayItem(f, 2), "opt");
    TEST_ASSERT_EQUAL(2, cJSON_GetArraySize(opt));
    TEST_ASSERT_EQUAL_STRING("auto", cJSON_GetArrayItem(cJSON_GetArrayItem(opt, 1), 0)->valuestring);
    TEST_ASSERT_EQUAL_STRING("Tự động", cJSON_GetArrayItem(cJSON_GetArrayItem(opt, 1), 1)->valuestring);
    TEST_ASSERT_EQUAL_STRING("mode==manual", str_of(cJSON_GetArrayItem(f, 3), "en"));
    const cJSON *bits = cJSON_GetObjectItemCaseSensitive(cJSON_GetArrayItem(f, 4), "opt");
    TEST_ASSERT_EQUAL_STRING("Chưa có giờ", cJSON_GetArrayItem(bits, 1)->valuestring);
    TEST_ASSERT_EQUAL_STRING("alarm!=0", str_of(cJSON_GetArrayItem(f, 5), "if"));
    TEST_ASSERT_EQUAL_STRING("Tắt còi?", str_of(cJSON_GetArrayItem(f, 5), "c"));
    cJSON_Delete(j);
}

TEST_CASE("schema: man batch co khoi lap", "[schema]")
{
    setup(0);
    cJSON *j = parse(vph_core_schema(1));
    TEST_ASSERT_EQUAL_STRING("batch", str_of(j, "save"));
    const cJSON *f = cJSON_GetObjectItemCaseSensitive(j, "f");
    TEST_ASSERT_EQUAL_STRING("Ngưỡng", str_of(cJSON_GetArrayItem(f, 0), "g"));
    TEST_ASSERT_EQUAL(1, (int)num_of(cJSON_GetArrayItem(f, 0), "nul"));
    const cJSON *rep = cJSON_GetObjectItemCaseSensitive(j, "rep");
    TEST_ASSERT_EQUAL(5, (int)num_of(rep, "n"));
    TEST_ASSERT_EQUAL_STRING("s", str_of(rep, "pfx"));
    TEST_ASSERT_EQUAL_STRING("Khung", str_of(rep, "l"));
    TEST_ASSERT_EQUAL_STRING("count", str_of(rep, "cnt"));
    TEST_ASSERT_EQUAL(3, cJSON_GetArraySize(cJSON_GetObjectItemCaseSensitive(rep, "f")));
    cJSON_Delete(j);
}

TEST_CASE("schema: man ngoai pham vi tra {}", "[schema]")
{
    setup(0);
    TEST_ASSERT_EQUAL_STRING("{}", vph_core_schema(2));
    TEST_ASSERT_EQUAL_STRING("{}", vph_core_schema(-1));
    const char *p;
    TEST_ASSERT_EQUAL(2, vph_core_schema_page(9, 0, &p));
    TEST_ASSERT_EQUAL(0, vph_core_schema_page(9, 1, &p));
}

TEST_CASE("schema: cat trang 480 byte, ghep lai dung nguyen van", "[schema]")
{
    setup(30);      // 30 truong phu -> schema dai nhieu trang
    const char *all = vph_core_schema(1);
    size_t total = strlen(all);
    TEST_ASSERT_GREATER_THAN(2 * VPH_SCHEMA_PAGE, total);
    char joined[4096];
    size_t at = 0;
    int pages = 0;
    for (int page = 0; page < 16; page++) {
        const char *p;
        size_t n = vph_core_schema_page(1, page, &p);
        TEST_ASSERT_LESS_OR_EQUAL(VPH_SCHEMA_PAGE, n);
        TEST_ASSERT_LESS_THAN(sizeof(joined), at + n);
        memcpy(joined + at, p, n);
        at += n;
        pages++;
        if (n < VPH_SCHEMA_PAGE) break;     // quy tac dung cua app (PROTOCOL 8.1)
    }
    joined[at] = '\0';
    TEST_ASSERT_EQUAL(total, at);
    TEST_ASSERT_EQUAL_STRING(all, joined);
    TEST_ASSERT_EQUAL((int)(total / VPH_SCHEMA_PAGE) + 1, pages);
    // Man 0 (ngan hon): trang cuoi chua phan du, trang sau do rong
    const char *p;
    size_t small = strlen(vph_core_schema(0));
    int last = (int)(small / VPH_SCHEMA_PAGE);
    TEST_ASSERT_EQUAL(small % VPH_SCHEMA_PAGE, vph_core_schema_page(0, last, &p));
    TEST_ASSERT_EQUAL(0, vph_core_schema_page(0, last + 1, &p));
}

TEST_CASE("schema: kich thuoc lon nhat tung man duoi 1920 byte", "[schema][size]")
{
    setup(0);
    for (int i = 0; i < vph_core_screen_count(); i++) {
        size_t len = strlen(vph_core_schema(i));
        printf("schema[%d] = %u byte\n", i, (unsigned)len);
        TEST_ASSERT_LESS_OR_EQUAL(VPH_MAX_SCHEMA, len);
    }
}

TEST_CASE("sch: CRC16 doi khi schema doi, giu nguyen khi schema nhu cu", "[schema][crc]")
{
    // Gia tri chuan CRC-16/MODBUS cua "123456789" la 0x4B37
    TEST_ASSERT_EQUAL_HEX16(0x4B37, vph_crc16((const uint8_t *)"123456789", 9, 0xFFFF));
    setup(0);
    char a[5];
    strlcpy(a, vph_core_sch(), sizeof(a));
    setup(0);
    TEST_ASSERT_EQUAL_STRING(a, vph_core_sch());
    setup(1);
    TEST_ASSERT_TRUE(strcmp(a, vph_core_sch()) != 0);
    for (const char *c = vph_core_sch(); *c; c++) {
        TEST_ASSERT_TRUE((*c >= '0' && *c <= '9') || (*c >= 'a' && *c <= 'f'));
    }
}

// ---------- VALUES ----------

TEST_CASE("VALUES: JSON phang, dung kieu, escape chuoi, NaN thanh null", "[values]")
{
    setup(0);
    char buf[400];
    size_t n = vph_core_values(0, buf, sizeof(buf));
    TEST_ASSERT_EQUAL(strlen(buf), n);
    TEST_ASSERT_LESS_OR_EQUAL(VPH_MAX_VALUES, n);
    cJSON *j = parse(buf);
    TEST_ASSERT_EQUAL_FLOAT(28.4f, (float)num_of(j, "t"));
    TEST_ASSERT_EQUAL(100, (int)num_of(j, "sv"));
    TEST_ASSERT_TRUE(cJSON_IsFalse(cJSON_GetObjectItemCaseSensitive(j, "out")));
    TEST_ASSERT_EQUAL_STRING("Xin \"chao\" \\ nhe", str_of(j, "msg"));
    TEST_ASSERT_TRUE(cJSON_IsNull(cJSON_GetObjectItemCaseSensitive(j, "h")));
    TEST_ASSERT_TRUE(cJSON_IsNull(cJSON_GetObjectItemCaseSensitive(j, "bad")));
    cJSON_Delete(j);
    // So thuc in dung so chu so thap phan yeu cau
    TEST_ASSERT_NOT_NULL(strstr(buf, "\"t\":28.4,"));
    TEST_ASSERT_NOT_NULL(strstr(buf, "\"sv\":100,"));
}

TEST_CASE("VALUES: tu ghep truong hdr vao moi man, khong lap id", "[values]")
{
    setup(0);
    char buf[400];
    // Man 1 khong tu ghi t/out -> component chen tu hdr
    vph_core_values(1, buf, sizeof(buf));
    cJSON *j = parse(buf);
    TEST_ASSERT_EQUAL_FLOAT(20.0f, (float)num_of(j, "lo"));
    TEST_ASSERT_EQUAL(127, (int)num_of(j, "days"));
    TEST_ASSERT_EQUAL_FLOAT(28.4f, (float)num_of(j, "t"));
    TEST_ASSERT_NOT_NULL(cJSON_GetObjectItemCaseSensitive(j, "out"));
    cJSON_Delete(j);
    // Man 0 da co t/out -> khong duoc lap lai
    vph_core_values(0, buf, sizeof(buf));
    const char *first = strstr(buf, "\"t\":");
    TEST_ASSERT_NOT_NULL(first);
    TEST_ASSERT_NULL(strstr(first + 1, "\"t\":"));
    const char *o1 = strstr(buf, "\"out\":");
    TEST_ASSERT_NOT_NULL(o1);
    TEST_ASSERT_NULL(strstr(o1 + 1, "\"out\":"));
}

TEST_CASE("VALUES: man ngoai pham vi tra {}", "[values]")
{
    setup(0);
    char buf[64];
    TEST_ASSERT_EQUAL(2, vph_core_values(5, buf, sizeof(buf)));
    TEST_ASSERT_EQUAL_STRING("{}", buf);
}

TEST_CASE("VALUES: qua dai thi bo truong thua, JSON van hop le", "[values][size]")
{
    setup(0);
    dev.big_values = true;
    char buf[400];
    size_t n = vph_core_values(1, buf, sizeof(buf));
    TEST_ASSERT_LESS_THAN(sizeof(buf), n);
    TEST_ASSERT_GREATER_THAN(VPH_MAX_VALUES, n);    // vuot 240: component da ESP_LOGW
    cJSON *j = parse(buf);                          // van parse duoc
    TEST_ASSERT_EQUAL_FLOAT(20.0f, (float)num_of(j, "lo"));
    cJSON_Delete(j);
}

TEST_CASE("VALUES: kich thuoc binh thuong cua tung man duoi 240 byte", "[values][size]")
{
    setup(0);
    char buf[400];
    for (int i = 0; i < vph_core_screen_count(); i++) {
        size_t n = vph_core_values(i, buf, sizeof(buf));
        printf("values[%d] = %u byte\n", i, (unsigned)n);
        TEST_ASSERT_LESS_OR_EQUAL(VPH_MAX_VALUES, n);
    }
}

// ---------- WRITE / RESULT ----------

static cJSON *do_write(const char *json, int *act)
{
    char result[VPH_MAX_RESULT + 40];
    *act = vph_core_handle_write(json, result, sizeof(result));
    TEST_ASSERT_LESS_OR_EQUAL_MESSAGE(VPH_MAX_RESULT, strlen(result), result);
    return parse(result);
}

TEST_CASE("WRITE don: ok, tra lai dung q", "[write]")
{
    setup(0);
    int act;
    cJSON *r = do_write("{\"q\":12,\"id\":\"sv\",\"v\":150}", &act);
    TEST_ASSERT_EQUAL(12, (int)num_of(r, "q"));
    TEST_ASSERT_EQUAL(1, (int)num_of(r, "ok"));
    TEST_ASSERT_NULL(cJSON_GetObjectItemCaseSensitive(r, "err"));
    TEST_ASSERT_EQUAL(VPH_ACT_OK, act);
    TEST_ASSERT_EQUAL(150, (int)dev.sv);
    cJSON_Delete(r);
    r = do_write("{\"q\":65535,\"id\":\"out\",\"v\":true}", &act);
    TEST_ASSERT_EQUAL(65535, (int)num_of(r, "q"));
    TEST_ASSERT_TRUE(dev.out);
    cJSON_Delete(r);
}

TEST_CASE("WRITE don: loi tieng Viet tu project, giu gia tri cu", "[write]")
{
    setup(0);
    int act;
    cJSON *r = do_write("{\"q\":3,\"id\":\"sv\",\"v\":5000}", &act);
    TEST_ASSERT_EQUAL(3, (int)num_of(r, "q"));
    TEST_ASSERT_EQUAL(0, (int)num_of(r, "ok"));
    TEST_ASSERT_EQUAL_STRING("Nhiệt độ đặt tối đa 1200 °C", str_of(r, "err"));
    TEST_ASSERT_EQUAL(0, act);
    TEST_ASSERT_EQUAL(100, (int)dev.sv);
    cJSON_Delete(r);
}

TEST_CASE("WRITE don: id khong biet -> Khong co truong <id>", "[write]")
{
    setup(0);
    int act;
    cJSON *r = do_write("{\"q\":4,\"id\":\"abc\",\"v\":1}", &act);
    TEST_ASSERT_EQUAL(0, (int)num_of(r, "ok"));
    TEST_ASSERT_EQUAL_STRING("Không có trường abc", str_of(r, "err"));
    cJSON_Delete(r);
    // Id danh rieng la cung bi tu choi, khong goi project
    int before = dev.writes;
    r = do_write("{\"q\":5,\"id\":\"_xyz\",\"v\":1}", &act);
    TEST_ASSERT_EQUAL_STRING("Không có trường _xyz", str_of(r, "err"));
    TEST_ASSERT_EQUAL(before, dev.writes);
    cJSON_Delete(r);
}

TEST_CASE("WRITE: tu choi khong ly do van co err; err dai bi cat <= 80 byte dung ranh gioi", "[write]")
{
    setup(0);
    int act;
    cJSON *r = do_write("{\"q\":6,\"id\":\"silent_fail\",\"v\":1}", &act);
    TEST_ASSERT_EQUAL(0, (int)num_of(r, "ok"));
    TEST_ASSERT_TRUE(strlen(str_of(r, "err")) > 0);
    cJSON_Delete(r);
    r = do_write("{\"q\":7,\"id\":\"long_err\",\"v\":1}", &act);
    const char *err = str_of(r, "err");
    TEST_ASSERT_LESS_OR_EQUAL(VPH_MAX_ERR, strlen(err));
    TEST_ASSERT_GREATER_THAN(60, strlen(err));
    // Byte cuoi khong duoc la byte mo dau cua ky tu nhieu byte bi cat cut
    unsigned char last = (unsigned char)err[strlen(err) - 1];
    TEST_ASSERT_TRUE(last < 0x80 || (last & 0xC0) == 0x80);
    cJSON_Delete(r);
}

TEST_CASE("WRITE: JSON hong / thieu khoa -> bao loi, khong goi project", "[write]")
{
    setup(0);
    int act;
    const char *bad[] = {"", "{", "abc", "[1,2]", "{\"q\":9}", "{\"q\":9,\"id\":\"sv\"}", "{\"q\":9,\"v\":1}"};
    for (int i = 0; i < 7; i++) {
        cJSON *r = do_write(bad[i], &act);
        TEST_ASSERT_EQUAL_MESSAGE(0, (int)num_of(r, "ok"), bad[i]);
        TEST_ASSERT_TRUE(strlen(str_of(r, "err")) > 0);
        TEST_ASSERT_EQUAL(0, act);
        cJSON_Delete(r);
    }
    TEST_ASSERT_EQUAL(0, dev.writes);
    TEST_ASSERT_EQUAL(0, dev.batches);
}

TEST_CASE("WRITE lo: hop le thi ap ca lo, sai thi giu nguyen cau hinh cu", "[write][batch]")
{
    setup(0);
    int act;
    cJSON *r = do_write("{\"q\":13,\"set\":{\"lo\":10,\"hi\":50}}", &act);
    TEST_ASSERT_EQUAL(13, (int)num_of(r, "q"));
    TEST_ASSERT_EQUAL(1, (int)num_of(r, "ok"));
    TEST_ASSERT_EQUAL(VPH_ACT_OK, act);
    TEST_ASSERT_EQUAL(10, (int)dev.lo);
    TEST_ASSERT_EQUAL(50, (int)dev.hi);
    cJSON_Delete(r);

    r = do_write("{\"q\":14,\"set\":{\"lo\":60}}", &act);
    TEST_ASSERT_EQUAL(0, (int)num_of(r, "ok"));
    TEST_ASSERT_EQUAL_STRING("Ngưỡng thấp phải nhỏ hơn ngưỡng cao", str_of(r, "err"));
    TEST_ASSERT_EQUAL(10, (int)dev.lo);
    cJSON_Delete(r);

    r = do_write("{\"q\":15,\"set\":{\"lo\":5,\"zz\":1}}", &act);
    TEST_ASSERT_EQUAL_STRING("Không có trường zz", str_of(r, "err"));
    TEST_ASSERT_EQUAL(10, (int)dev.lo);
    cJSON_Delete(r);
    TEST_ASSERT_EQUAL(3, dev.batches);
    TEST_ASSERT_EQUAL(0, dev.writes);
}

TEST_CASE("WRITE lo: thiet bi khong co batch_cb thi tu choi", "[write][batch]")
{
    const vph_info_t info = {.model = "x", .fw = "1.0.0"};
    cJSON *one[1] = {vph_screen("a", "A", "live")};
    vph_core_deinit();
    TEST_ASSERT_EQUAL(ESP_OK, vph_core_init(&info, one, 1, fill, on_write, NULL));
    int act;
    cJSON *r = do_write("{\"q\":1,\"set\":{\"lo\":1}}", &act);
    TEST_ASSERT_EQUAL(0, (int)num_of(r, "ok"));
    TEST_ASSERT_EQUAL(0, act);
    cJSON_Delete(r);
}

// ---------- Id danh rieng ----------

TEST_CASE("_time: dat gio he thong, gio vo ly bi tu choi", "[reserved]")
{
    setup(0);
    int act;
    cJSON *r = do_write("{\"q\":1,\"id\":\"_time\",\"v\":1759300000}", &act);
    TEST_ASSERT_EQUAL(1, (int)num_of(r, "ok"));
    TEST_ASSERT_EQUAL(VPH_ACT_OK, act);
    cJSON_Delete(r);
    time_t now = time(NULL);
    TEST_ASSERT_INT_WITHIN(3, 1759300000, (int)now);
    // Project duoc goi (tra VPH_ERR_UNKNOWN = khong can lam gi them) va van ok
    TEST_ASSERT_EQUAL_STRING("_time", dev.last_id);

    r = do_write("{\"q\":2,\"id\":\"_time\",\"v\":123}", &act);
    TEST_ASSERT_EQUAL(0, (int)num_of(r, "ok"));
    cJSON_Delete(r);
    r = do_write("{\"q\":3,\"id\":\"_time\",\"v\":\"abc\"}", &act);
    TEST_ASSERT_EQUAL(0, (int)num_of(r, "ok"));
    cJSON_Delete(r);
    TEST_ASSERT_INT_WITHIN(3, 1759300000, (int)time(NULL));
}

TEST_CASE("_name: goi project truoc, doi ten trong INFO, bao can quang ba lai", "[reserved]")
{
    setup(0);
    int act;
    cJSON *r = do_write("{\"q\":1,\"id\":\"_name\",\"v\":\"VUON-RAU-1\"}", &act);
    TEST_ASSERT_EQUAL(1, (int)num_of(r, "ok"));
    TEST_ASSERT_EQUAL(VPH_ACT_OK | VPH_ACT_RENAME, act);
    cJSON_Delete(r);
    TEST_ASSERT_EQUAL_STRING("VUON-RAU-1", dev.saved_name);
    TEST_ASSERT_EQUAL_STRING("VUON-RAU-1", vph_core_name());
    cJSON *info = parse(vph_core_info());
    TEST_ASSERT_EQUAL_STRING("VUON-RAU-1", str_of(info, "name"));
    cJSON_Delete(info);
}

TEST_CASE("_name: ten sai bi tu choi, giu ten cu", "[reserved]")
{
    setup(0);
    int act;
    const char *bad[] = {
        "{\"q\":1,\"id\":\"_name\",\"v\":\"\"}",
        "{\"q\":1,\"id\":\"_name\",\"v\":\"TEN-DAI-HON-HAI-MUOI-KY-TU\"}",
        "{\"q\":1,\"id\":\"_name\",\"v\":\"Vườn\"}",
        "{\"q\":1,\"id\":\"_name\",\"v\":\"A\\\"B\"}",
        "{\"q\":1,\"id\":\"_name\",\"v\":\"A\\\\B\"}",
        "{\"q\":1,\"id\":\"_name\",\"v\":5}",
    };
    for (int i = 0; i < 6; i++) {
        cJSON *r = do_write(bad[i], &act);
        TEST_ASSERT_EQUAL_MESSAGE(0, (int)num_of(r, "ok"), bad[i]);
        TEST_ASSERT_EQUAL(0, act);
        cJSON_Delete(r);
    }
    TEST_ASSERT_EQUAL_STRING("C3-RELAY-A1B2", vph_core_name());
    TEST_ASSERT_EQUAL_STRING("", dev.saved_name);
    // Dung 20 ky tu thi duoc
    cJSON *r = do_write("{\"q\":2,\"id\":\"_name\",\"v\":\"12345678901234567890\"}", &act);
    TEST_ASSERT_EQUAL(1, (int)num_of(r, "ok"));
    cJSON_Delete(r);
}

TEST_CASE("_reboot: goi project truoc (de luu NVS), bao can reset", "[reserved]")
{
    setup(0);
    int act;
    cJSON *r = do_write("{\"q\":8,\"id\":\"_reboot\",\"v\":1}", &act);
    TEST_ASSERT_EQUAL(8, (int)num_of(r, "q"));
    TEST_ASSERT_EQUAL(1, (int)num_of(r, "ok"));
    TEST_ASSERT_EQUAL(VPH_ACT_OK | VPH_ACT_REBOOT, act);
    TEST_ASSERT_TRUE(dev.reboot_seen);
    cJSON_Delete(r);
}

// ---------- v1.1: tu vung hien thi + WRITE 500 byte ----------

TEST_CASE("v1.1 schema: ic, d, sub, opt cua bool, opt co icon", "[schema][v11]")
{
    cJSON *s = vph_screen("o", "Tổng quan", "live");
    vph_icon(s, "dashboard");
    vph_nav_menu(s);
    cJSON *t = vph_field(s, "t", "Nhiệt độ", "num");
    vph_hint(t, "tile,trend");
    vph_icon(t, "temp");
    cJSON *out = vph_field(s, "out", "Relay", "bool");
    vph_hint(out, "hero,btns");
    vph_sub(out, "mode");
    vph_desc(out, "Chỉ ở chế độ Tay");
    cJSON *run = vph_field(s, "run", "Đốt lò", "bool");
    vph_bool_labels(run, "Dừng", "Đang đốt");
    cJSON *mode = vph_field(s, "mode", "Chế độ", "enum");
    static const char *const vals[] = {"manual", "auto"};
    static const char *const labels[] = {"Tay", "Tự động"};
    static const char *const icons[] = {"hand", NULL};
    vph_options_ic(mode, vals, labels, icons, 2);

    const vph_info_t info = {.model = "x", .fw = "1.1.0"};
    cJSON *one[1] = {s};
    vph_core_deinit();
    TEST_ASSERT_EQUAL(ESP_OK, vph_core_init(&info, one, 1, fill, on_write, NULL));
    cJSON *j = parse(vph_core_schema(0));
    TEST_ASSERT_EQUAL_STRING("dashboard", str_of(j, "ic"));
    TEST_ASSERT_EQUAL_STRING("menu", str_of(j, "nav"));
    const cJSON *f = cJSON_GetObjectItemCaseSensitive(j, "f");
    const cJSON *jt = cJSON_GetArrayItem(f, 0);
    TEST_ASSERT_EQUAL_STRING("tile,trend", str_of(jt, "w"));
    TEST_ASSERT_EQUAL_STRING("temp", str_of(jt, "ic"));
    const cJSON *jo = cJSON_GetArrayItem(f, 1);
    TEST_ASSERT_EQUAL_STRING("mode", str_of(jo, "sub"));
    TEST_ASSERT_EQUAL_STRING("Chỉ ở chế độ Tay", str_of(jo, "d"));
    const cJSON *bl = cJSON_GetObjectItemCaseSensitive(cJSON_GetArrayItem(f, 2), "opt");
    TEST_ASSERT_EQUAL(2, cJSON_GetArraySize(bl));
    TEST_ASSERT_EQUAL_STRING("Dừng", cJSON_GetArrayItem(bl, 0)->valuestring);
    TEST_ASSERT_EQUAL_STRING("Đang đốt", cJSON_GetArrayItem(bl, 1)->valuestring);
    const cJSON *opt = cJSON_GetObjectItemCaseSensitive(cJSON_GetArrayItem(f, 3), "opt");
    // Lua chon co icon: 3 phan tu; icon NULL: van 2 phan tu nhu v1.0
    TEST_ASSERT_EQUAL(3, cJSON_GetArraySize(cJSON_GetArrayItem(opt, 0)));
    TEST_ASSERT_EQUAL_STRING("hand", cJSON_GetArrayItem(cJSON_GetArrayItem(opt, 0), 2)->valuestring);
    TEST_ASSERT_EQUAL(2, cJSON_GetArraySize(cJSON_GetArrayItem(opt, 1)));
    cJSON_Delete(j);
}

// Dung lenh set dai: {"q":Q,"set":{"lo":10,"hi":50,"pad":"xxxx..."}} voi tong do dai dung bang len
static void long_set(char *buf, size_t cap, int q, const char *fields, size_t len)
{
    int n = snprintf(buf, cap, "{\"q\":%d,\"set\":{%s", q, fields);
    TEST_ASSERT_TRUE(len + 1 <= cap && (size_t)n + 2 <= len);
    memset(buf + n, ' ', len - n - 2);      // dem bang dau cach, JSON van hop le
    buf[len - 2] = '}';
    buf[len - 1] = '}';
    buf[len] = 0;
}

TEST_CASE("v1.1 WRITE: lenh set dai hon 240 byte van duoc, dung 500 byte van duoc", "[write][batch][v11]")
{
    setup(0);
    int act;
    char cmd[VPH_MAX_WRITE + 40];
    long_set(cmd, sizeof(cmd), 21, "\"lo\":10,\"hi\":50", 300);
    TEST_ASSERT_EQUAL(300, strlen(cmd));
    cJSON *r = do_write(cmd, &act);
    TEST_ASSERT_EQUAL(21, (int)num_of(r, "q"));
    TEST_ASSERT_EQUAL(1, (int)num_of(r, "ok"));
    TEST_ASSERT_EQUAL(10, (int)dev.lo);
    TEST_ASSERT_EQUAL(50, (int)dev.hi);
    cJSON_Delete(r);

    long_set(cmd, sizeof(cmd), 22, "\"lo\":11,\"hi\":51", VPH_MAX_WRITE);
    TEST_ASSERT_EQUAL(VPH_MAX_WRITE, strlen(cmd));
    r = do_write(cmd, &act);
    TEST_ASSERT_EQUAL(1, (int)num_of(r, "ok"));
    TEST_ASSERT_EQUAL(11, (int)dev.lo);
    cJSON_Delete(r);
    TEST_ASSERT_EQUAL(2, dev.batches);
}

TEST_CASE("v1.1 WRITE: qua 500 byte -> Lenh qua dai, tra dung q, khong goi project", "[write][v11]")
{
    setup(0);
    int act;
    char cmd[VPH_MAX_WRITE + 40];
    long_set(cmd, sizeof(cmd), 23, "\"lo\":12,\"hi\":52", VPH_MAX_WRITE + 1);
    cJSON *r = do_write(cmd, &act);
    TEST_ASSERT_EQUAL(23, (int)num_of(r, "q"));
    TEST_ASSERT_EQUAL(0, (int)num_of(r, "ok"));
    TEST_ASSERT_EQUAL_STRING("Lệnh quá dài", str_of(r, "err"));
    TEST_ASSERT_EQUAL(0, act);
    TEST_ASSERT_EQUAL(20, (int)dev.lo);
    TEST_ASSERT_EQUAL(0, dev.batches);
    TEST_ASSERT_EQUAL(0, dev.writes);
    cJSON_Delete(r);
}
