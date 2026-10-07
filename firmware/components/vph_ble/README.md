# vph_ble — giao thức VPH v1 cho thiết bị ESP32 (ESP-IDF, NimBLE)

Component dùng chung: thiết bị nào dùng nó thì app **VP Hub** tự quét thấy, tự vẽ giao diện, tự ghi được — không phải làm app mới, không phải tự viết GATT.

- Giao thức: `docs/PROTOCOL.md` (nguồn sự thật duy nhất).
- Quy tắc cho dự án mới: `docs/QUY_TAC_THIET_BI_MOI.md`.
- Mẫu đầy đủ để chép: `firmware/examples/vph_demo/main/main.c`.
- Phiên bản: file `VERSION`. ESP-IDF ≥ 5.5 (đã build với v5.5.5). Với v6.x `CMakeLists.txt` và `idf_component.yml` đã chuyển sang `espressif/cjson`, **nhưng chưa build thử trên v6**.

## Thêm vào dự án mới

1. `main/idf_component.yml`:
   ```yaml
   dependencies:
     vph_ble:
       path: ../../../vp_hub/firmware/components/vph_ble   # dự án nằm trong D:\2026\
   ```
   Dự án ở chỗ khác: chép nguyên thư mục `vph_ble` vào `components/`, giữ file `VERSION`.
2. `main/CMakeLists.txt`: thêm `vph_ble` vào `REQUIRES`.
3. `sdkconfig.defaults`:
   ```
   CONFIG_BT_ENABLED=y
   CONFIG_BT_NIMBLE_ENABLED=y
   CONFIG_BT_BLUEDROID_ENABLED=n
   CONFIG_BT_NIMBLE_MAX_CONNECTIONS=1
   CONFIG_BT_NIMBLE_ATT_PREFERRED_MTU=512
   CONFIG_BT_NIMBLE_SECURITY_ENABLE=n
   CONFIG_ESP_MAIN_TASK_STACK_SIZE=8192
   ```
   Task gọi `vph_poll()` cần stack ≥ 4096 byte (nên 8192).
4. Gọi `nvs_flash_init()` trước `vph_init()` (BLE cần NVS).

## Dùng trong 4 bước

```c
#include "vph_ble.h"

// 1. Khai báo màn hình (một lần lúc khởi động)
static cJSON *build_overview(void)
{
    cJSON *s = vph_screen("overview", "Tổng quan", "live");
    vph_icon(s, "dashboard");                       // icon của tab
    cJSON *t = vph_field(s, "t", "Nhiệt độ", "num");
    vph_unit(t, "°C"); vph_dp(t, 1); vph_readonly(t);
    vph_hint(t, "tile,trend"); vph_icon(t, "temp"); // thẻ số đo có icon, chạm để xem biểu đồ
    cJSON *out = vph_field(s, "out", "Relay", "bool");
    vph_hint(out, "hero,btns"); vph_icon(out, "power");   // thẻ trạng thái lớn + 2 nút BẬT/TẮT
    return s;
}

// 2. Điền VALUES: ghi các trường của màn `screen`; VPH_SCREEN_HDR = các trường đầu trang
static void fill_values(uint8_t screen, vph_out_t *o)
{
    if (screen == VPH_SCREEN_HDR || screen == 0) {
        vph_out_num(o, "t", temp, 1);
        vph_out_bool(o, "out", relay_on);
    }
}

// 3. Xử lý ghi (chạy trong task chính, được phép ghi NVS)
static int on_write(const char *id, const cJSON *v, char *err, size_t err_len)
{
    if (!strcmp(id, "out")) { relay_set(cJSON_IsTrue(v)); return VPH_OK; }
    return VPH_ERR_UNKNOWN;     // component trả "Không có trường <id>"
}

// 4. Khởi động và gọi vph_poll() đều trong vòng lặp chính
void app_main(void)
{
    nvs_flash_init();
    static const char *const hdr[] = {"t", "out", NULL};
    const vph_info_t info = {.model = "mydevice", .fw = "1.0.0", .hw = "esp32c3",
                             .icon = "relay", .hdr = hdr, .name_prefix = "MY-DEVICE"};
    cJSON *screens[] = {build_overview()};
    vph_init(&info, screens, 1, fill_values, on_write, NULL);
    while (1) {
        vph_poll();                         // ít nhất 10 lần/giây
        vTaskDelay(pdMS_TO_TICKS(50));
    }
}
```

## Quy ước cần nhớ

| Việc | Cách làm |
|---|---|
| Mã trả về của `on_write` / `on_batch` | `VPH_OK`; `VPH_ERR_UNKNOWN` (không biết trường); `VPH_ERR_REJECT` + ghi lý do **tiếng Việt có dấu** vào `err` (≤ 80 byte) |
| Màn `batch` | `on_batch(set, ...)`: áp **tất cả** lên **bản sao** cấu hình → kiểm tra → hợp lệ mới gán và lưu. Sai thì giữ nguyên cấu hình cũ |
| Trường đầu trang (`hdr`) | Liệt kê id trong `info.hdr`; trong `fill_values` ghi chúng khi `screen == VPH_SCREEN_HDR`. Component tự chèn vào VALUES mọi màn, id trùng thì bỏ qua |
| Khối lặp | `rep = vph_repeat(s, 5, "s", "Khung"); vph_field(rep, "en", "Bật", "bool");` → VALUES phải có `s1_en … s5_en` |
| `_time` | Component tự `settimeofday`. Có RTC thì ghi RTC trong `on_write("_time")`. Nhớ đặt `info.caps = VPH_CAP_TIME` |
| `_name` | Component kiểm tra tên rồi gọi `on_write("_name")` để project lưu NVS, sau đó đổi tên quảng bá. Lúc khởi động gọi `vph_set_name(tên_đã_lưu)` **trước** `vph_init()` |
| `_reboot` | Component gọi `on_write("_reboot")` (lưu NVS ngay ở đây), trả RESULT, rồi reset sau 0,5 s |
| Id dành riêng không cần xử lý | Trả `VPH_ERR_UNKNOWN` — với id bắt đầu bằng `_` nghĩa là "không cần làm gì thêm" |
| Trạng thái đổi ngoài app (nút nhấn…) | Gọi `vph_notify_now()` để app thấy ngay |

## Component tự lo

UUID và GATT, quảng bá (UUID ở gói advertising, tên ở scan response), MTU 512, SELECT `[màn, trang]`, cắt schema thành trang 480 byte, tính `sch` (CRC16 toàn bộ schema), dựng INFO, ghép `hdr`, notify VALUES mỗi giây và ngay sau lệnh ghi thành công, queue lệnh ghi, RESULT có `q`, cắt `err` ở 80 byte đúng ranh giới UTF-8, tên mặc định `<name_prefix>-<4 hex MAC>`.

**Luồng chạy:** callback GATT (task của NimBLE) chỉ chép dữ liệu và đẩy lệnh vào queue. `fill_values`, `on_write`, `on_batch` **luôn** chạy trong task gọi `vph_poll()`, nên project không cần mutex cho dữ liệu của mình. VALUES của mọi màn được dựng sẵn mỗi giây để lệnh đọc ngay sau SELECT trả đúng màn mới.

## Gợi ý hiển thị v1.1 (PROTOCOL §5.4, §5.6)

Để app vẽ đẹp như app viết riêng, dùng các hàm sau (app VP Hub 1.0 bỏ qua, không lỗi):

| Muốn | Gọi |
|---|---|
| Icon cho tab / trường | `vph_icon(screen_or_field, "temp")` |
| Màn cài đặt / thông tin nằm trong menu ⋮, không làm tab | `vph_nav_menu(screen)` |
| Số đo chính thành thẻ, 2 thẻ một hàng | `vph_hint(f, "tile")` + `vph_icon` |
| Vài số phụ gom một thẻ | `vph_hint(f, "mini")` cho các trường liền nhau |
| Công tắc tải chính | `vph_hint(f, "hero,btns")`, `vph_sub(f, "mode")`, `vph_desc(f, "lý do khi bị khóa")` |
| Chữ trạng thái khác BẬT/TẮT | `vph_bool_labels(f, "Dừng", "Đang đốt")` |
| Chọn chế độ có icon | `vph_hint(f, "seg")` + `vph_options_ic(...)` |
| Thẻ báo động | `vph_hint(flags, "alarm")`, nút "Tắt còi" đặt liền sau, cùng `vph_group` |
| Dòng cảnh báo | `vph_hint(f, "note")` + `vph_show_if` |
| Số giây thành "2 giờ 5 phút" | `vph_hint(f, "dur")` |

Mẫu đầy đủ: `firmware/examples/vph_demo/main/main.c`.

## Giới hạn kích thước (PROTOCOL §8)

| Gói | Tối đa | Component làm gì khi vượt |
|---|---|---|
| INFO | 240 byte | `ESP_LOGW` |
| SCHEMA mỗi màn | 1920 byte (4 trang) | `ESP_LOGW` lúc khởi động; in kích thước từng màn ra log |
| VALUES mỗi màn (kể cả `hdr`) | 240 byte | `ESP_LOGW` một lần cho mỗi màn; quá 400 byte thì bỏ các trường cuối (JSON vẫn hợp lệ) |
| WRITE | 500 byte (v1.1) | RESULT `"err":"Lệnh quá dài"`, không gọi `on_write` / `on_batch` |
| RESULT | 120 byte | `err` bị cắt còn 80 byte |

VALUES quá 240 byte → tách thành 2 màn hoặc rút id ngắn lại. **Dự án phải có unit test** kiểm tra kích thước lớn nhất của từng màn (xem `firmware/test_app/main/test_vph.c`, các test nhãn `[size]`).

## Thử giao diện trước khi nạp

Lấy chuỗi INFO và schema từ log lúc khởi động (hoặc `vph_core_info()`, `vph_core_schema(i)` trong `vph_core.h`), ghép thành file demo theo `app/assets/demo/README.md`, mở bằng VP Hub → **Thiết bị mẫu → Mở file JSON**.

## Test

`firmware/test_app`: Unity test chạy trên chip cho phần lõi (`vph_core.c`, không cần kết nối BLE).

```powershell
powershell -ExecutionPolicy Bypass -File tools/idf.ps1 -Dir firmware/test_app build
powershell -ExecutionPolicy Bypass -File tools/idf.ps1 -Dir firmware/test_app -p COM5 flash
tools/.venv/Scripts/python tools/serial_log.py --port COM5 --seconds 30 --reset --expect TEST_SUMMARY
```
