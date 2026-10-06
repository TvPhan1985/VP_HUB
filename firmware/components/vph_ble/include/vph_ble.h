// vph_ble - component dung chung cho moi thiet bi noi giao thuc VPH v1.
// Tai lieu giao thuc: docs/PROTOCOL.md. Cach dung: README.md cung thu muc.
#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "cJSON.h"
#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

#define VPH_PROTO_VERSION   1
#define VPH_CAP_TIME        (1u << 0)   // thiet bi can gio, app gui _time khi ket noi

// Gioi han kich thuoc (PROTOCOL §8)
#define VPH_MAX_INFO        240
#define VPH_SCHEMA_PAGE     480
#define VPH_MAX_SCHEMA      (4 * VPH_SCHEMA_PAGE)
#define VPH_MAX_VALUES      240
#define VPH_MAX_WRITE       240
#define VPH_MAX_RESULT      120
#define VPH_MAX_ERR         80
#define VPH_MAX_SCREENS     16
#define VPH_NAME_MAX        20

// Gia tri `screen` khi component hoi cac truong dau trang (hdr)
#define VPH_SCREEN_HDR      0xFF

// Ma tra ve cua vph_write_cb / vph_batch_cb
#define VPH_OK              0
#define VPH_ERR_UNKNOWN     (-1)        // khong biet truong nay -> "Không có trường <id>"
#define VPH_ERR_REJECT      1           // tu choi, ly do tieng Viet ghi vao err

typedef struct {
    const char *model;          // chu thuong, khong dau, khong cach. KHONG doi sau khi phat hanh
    const char *fw;             // "x.y.z"
    const char *hw;             // co the NULL
    const char *icon;           // relay|heater|sensor|pump|light|motor|generic, co the NULL
    const char *const *hdr;     // id cac truong dau trang, ket thuc bang NULL; co the NULL
    uint32_t caps;              // VPH_CAP_TIME ...
    const char *name_prefix;    // ten quang ba mac dinh = <name_prefix>-<4 hex MAC>; NULL = MODEL viet hoa
} vph_info_t;

// ---------- Dung schema (goi truoc vph_init) ----------

// save: "live" hoac "batch"
cJSON *vph_screen(const char *id, const char *title, const char *save);
// type: num|bool|text|str|enum|time|date|days|flags|act (PROTOCOL §5.2)
cJSON *vph_field(cJSON *screen, const char *id, const char *label, const char *type);
void vph_range(cJSON *f, double min, double max, double step);
void vph_unit(cJSON *f, const char *u);
void vph_dp(cJSON *f, int dp);
void vph_readonly(cJSON *f);
void vph_nullable(cJSON *f);
void vph_hint(cJSON *f, const char *w);             // big|trend|led|gauge|warn, noi bang dau phay
void vph_confirm(cJSON *f, const char *question);
void vph_show_if(cJSON *f, const char *cond);       // "alarm!=0"
void vph_enable_if(cJSON *f, const char *cond);     // "mode==manual"
void vph_group(cJSON *f, const char *name);
void vph_maxlen(cJSON *f, int max);                 // do dai toi da cua kieu str
// enum: vals[i] la gia tri, labels[i] la chu hien thi
void vph_options(cJSON *f, const char *const *vals, const char *const *labels, int n);
// enum co gia tri so
void vph_options_num(cJSON *f, const double *vals, const char *const *labels, int n);
// flags: nhan cua bit0, bit1...
void vph_flag_labels(cJSON *f, const char *const *labels, int n);
// Khoi lap: tra ve doi tuong de them truong mau bang vph_field(rep, ...)
cJSON *vph_repeat(cJSON *screen, int n, const char *pfx, const char *label);
void vph_repeat_count(cJSON *rep, const char *cnt_id);

// ---------- Dien VALUES ----------

typedef struct vph_out vph_out_t;

// Project ghi cac truong cua man hinh `screen` vao out. Khi screen == VPH_SCREEN_HDR:
// ghi cac truong dau trang (hdr). Luon duoc goi trong task goi vph_poll().
typedef void (*vph_values_cb)(uint8_t screen, vph_out_t *out);

void vph_out_num(vph_out_t *o, const char *id, double v, int dp);   // NaN/Inf -> null
void vph_out_int(vph_out_t *o, const char *id, long v);
void vph_out_bool(vph_out_t *o, const char *id, bool v);
void vph_out_str(vph_out_t *o, const char *id, const char *s);      // NULL -> null
void vph_out_null(vph_out_t *o, const char *id);

// ---------- Ghi ----------

// Goi trong TASK CHINH (ben trong vph_poll), khong phai callback GATT.
// Tra VPH_OK, VPH_ERR_UNKNOWN, hoac khac 0 kem err tieng Viet (toi da 80 byte).
// Id danh rieng cung di qua day TRUOC khi component thuc hien:
//   "_time"   v = epoch UTC   (component da settimeofday; project ghi RTC neu co)
//   "_name"   v = ten moi     (project luu NVS; component doi ten quang ba)
//   "_reboot" v = 1           (project luu NVS ngay; component reset sau 0,5 s)
// Voi id danh rieng, tra VPH_ERR_UNKNOWN nghia la "khong can lam gi them".
typedef int (*vph_write_cb)(const char *id, const cJSON *v, char *err, size_t err_len);
// Ghi theo lo: ap TAT CA len ban sao cau hinh, kiem tra hop le roi moi luu.
typedef int (*vph_batch_cb)(const cJSON *set, char *err, size_t err_len);

// ---------- Vong doi ----------

// screens[i] do vph_screen() tao; component giu quyen so huu va tu giai phong.
// bcb co the NULL neu khong co man batch.
esp_err_t vph_init(const vph_info_t *info, cJSON *const *screens, int n,
                   vph_values_cb vcb, vph_write_cb wcb, vph_batch_cb bcb);

// Goi deu trong vong lap task chinh, it nhat 10 lan/giay: xu ly WRITE tu queue, tra RESULT,
// notify VALUES moi giay, doi ten, reset sau _reboot. Khong chan.
void vph_poll(void);

// Dat ten quang ba (vd ten da luu trong NVS). Ten sai (rong, > 20, khong ASCII) bi bo qua.
esp_err_t vph_set_name(const char *name);
const char *vph_get_name(void);

// Gui VALUES ngay o lan vph_poll() ke tiep (vd sau khi nut nhan doi trang thai)
void vph_notify_now(void);
bool vph_connected(void);

#ifdef __cplusplus
}
#endif
