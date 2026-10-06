// Phan loi cua vph_ble, khong dung den BLE: dung chuoi INFO/SCHEMA/VALUES, xu ly WRITE.
// Tach rieng de unit test tren chip khong can ket noi (firmware/test_app).
// Project binh thuong chi can vph_ble.h.
#pragma once

#include "vph_ble.h"

#ifdef __cplusplus
extern "C" {
#endif

// Viec component phai lam sau khi xu ly mot lenh ghi
#define VPH_ACT_OK          (1 << 0)    // lenh thanh cong -> gui VALUES ngay
#define VPH_ACT_RENAME      (1 << 1)    // ten doi -> quang ba lai
#define VPH_ACT_REBOOT      (1 << 2)    // reset sau 0,5 s

esp_err_t vph_core_init(const vph_info_t *info, cJSON *const *screens, int n,
                        vph_values_cb vcb, vph_write_cb wcb, vph_batch_cb bcb);
void vph_core_deinit(void);

int vph_core_screen_count(void);
// Chuoi INFO hien tai (dung lai moi khi doi ten)
const char *vph_core_info(void);
// Toan bo chuoi schema cua mot man hinh; ngoai pham vi tra "{}"
const char *vph_core_schema(int screen);
// Mot trang 480 byte cua schema (PROTOCOL §8.1). Tra so byte, *p tro vao du lieu.
size_t vph_core_schema_page(int screen, int page, const char **p);
// CRC16 cua toan bo schema, 4 ky tu hex
const char *vph_core_sch(void);

// Dung VALUES cua man `screen` + cac truong hdr vao buf. Tra do dai (khong tinh '\0').
size_t vph_core_values(int screen, char *buf, size_t cap);

// Xu ly mot goi WRITE. Ghi chuoi RESULT vao result. Tra to hop VPH_ACT_*.
int vph_core_handle_write(const char *json, char *result, size_t result_cap);

esp_err_t vph_core_set_name(const char *name);
const char *vph_core_name(void);

uint16_t vph_crc16(const uint8_t *data, size_t len, uint16_t crc);

#ifdef __cplusplus
}
#endif
