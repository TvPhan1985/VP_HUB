# TEST_ON_HW — Thử trên phần cứng (Phần C)

Trạng thái ngày 2026-10-06: **mới làm được phần cài app**, các bước còn lại đang chờ người dùng (xem "Đang chờ").

## Đã làm

| Bước | Kết quả |
|---|---|
| Cài `release/VPHub_1.0.0.apk` lên moto g86 power 5G (Android 16) bằng `adb install -r` | `Success`, `versionName=1.0.0` |
| Mở app | App chạy, hiện màn Quét bằng tiếng Việt, rồi hộp xin quyền "Thiết bị ở gần" của Android |
| Đọc log board đang cắm ở COM5 (không reset) | Board đang chạy firmware **c3_relay_ctrl** (log `main: Coi bao dong 3 bip`, đã chạy ~16 giờ) → đây là **bộ relay thật**, không phải board trống |

## Đang chờ người dùng

1. **Bấm "Cho phép"** ở hộp xin quyền Bluetooth trên điện thoại. Chưa có quyền thì app chưa quét/kết nối được, nên chưa thử được gì qua BLE.
2. **Cắm một ESP32-C3 SuperMini trống** để nạp `test_app` và `vph_demo`. Không nạp vào board ở COM5 vì sẽ xóa firmware relay đang chạy và chân relay (GPIO10, mức thấp = đóng) không còn được điều khiển.
3. **Cho phép đóng/cắt relay thật** trước khi thử `out` / đổi chế độ trên bộ relay C3 (đọc số liệu thì không cần hỏi).
4. Bộ lò nung: cắm điện để thử; **không bật đốt lò** khi chưa hỏi.

## Chưa làm (theo PLAN Phase 11)

- [ ] `test_app`: nạp, `serial_log.py --expect TEST_SUMMARY`, phải 0 lỗi (24 test).
- [ ] `vph_demo`: quét thấy, đọc schema, notify, live + batch + lỗi tiếng Việt + act + `_time` + `_name` + `_reboot`, mất kết nối/kết nối lại, cache schema.
- [ ] Bộ relay C3 firmware cũ: chạy kịch bản `c3_relay_ctrl/docs/TEST_ON_HW.md` bằng VP Hub.
- [ ] Bộ lò nung firmware cũ: đọc nhiệt độ, đổi setpoint, PID, chương trình nhiều bước.
- [ ] Chế độ Demo trên điện thoại (không cần BLE, nhưng hộp xin quyền đang che màn hình).

## Đã kiểm tra không cần phần cứng

- `flutter analyze`: sạch. `flutter test`: 77 test qua (parser, điều kiện, transport VPH với characteristic giả lập, 2 adapter, session, widget vẽ 2 demo).
- `firmware/test_app` và `firmware/examples/vph_demo`: build thành công với ESP-IDF v5.5.5 (chưa chạy trên chip).

---

## Cập nhật 2026-10-07 — giao diện v1.1 (PLAN_GIAO_DIEN, U1–U7)

Người dùng cho phép dùng ESP32-C3 ở COM5 để thử. **Board này trước đó chạy firmware relay `c3_relay_ctrl`; nay đã bị nạp đè bằng `vph_demo` 1.1.0.** Muốn dùng lại làm bộ relay thì nạp lại firmware từ `D:\2026\c3_relay_ctrl` (cấu hình trong NVS của relay không bị xóa vì chỉ nạp đè phần app).

| Bước | Kết quả |
|---|---|
| `flutter analyze` / `flutter test` | Sạch / 88 test qua |
| Build + cài `release/VPHub_1.1.0.apk` (`adb install -r`) | `Success`, `versionName=1.1.0` |
| Thiết bị mẫu → Relay mẫu trên điện thoại | Thẻ nhiệt độ/độ ẩm 2 cột, thẻ EC/Độ mặn/TDS, thẻ Relay xanh + nút BẬT/TẮT, nút chọn chế độ có icon, thẻ báo động đỏ + nút Tắt còi, thanh điều hướng dưới |
| Nạp `test_app` vào COM5, `serial_log.py --reset --expect TEST_SUMMARY` | `27 Tests 0 Failures` (24 test cũ + 3 test v1.1). Sửa 1 test cũ sai giả định (màn 0 của test dài hơn 1 trang) |
| Nạp `vph_demo` 1.1.0 vào COM5 | Nạp xong, hash đúng. Log khởi động không đọc được qua `serial_log.py --reset` (log chỉ in trong giây đầu, lúc cổng USB vừa nối lại) |
| VP Hub kết nối `VPH-DEMO-3DAA` | Đọc schema v1.1, vẽ đúng tile / hero+btns / seg / alarm / dur, giờ thiết bị được đặt (`_time`) |
| Ghi live: bấm BẬT đèn | RESULT ok, thẻ đổi xanh, thông báo "Đã bật Đèn LED" |
| Ghi batch: đổi 2 ngưỡng + thứ của Khung 1 → Lưu | "Đã lưu", giá trị giữ đúng |

Chưa thử trên phần cứng:
- [ ] Lệnh `set` dài hơn 240 byte gửi thật qua BLE (đã có test trên chip cho 300 và 500 byte ở lõi `vph_core`, và test app gửi 5 khung giờ một lệnh; chưa bấm tay đủ nhiều ô trên điện thoại).
- [ ] Bộ relay C3 firmware cũ qua adapter với giao diện mới (board relay đang chạy `vph_demo`).
- [ ] Bộ lò nung firmware cũ với thẻ `hero` / `alarm` mới.
- [ ] `_name`, `_reboot`, mất kết nối / kết nối lại trên `vph_demo`.

## 2026-10-08 — app 1.2.0 (giao diện theo quy chuẩn Top Navigation & Theme System)

| Bước | Kết quả |
|---|---|
| `flutter analyze`, `flutter test` | sạch, 94 test qua |
| Cài `release/VPHub_1.2.0.apk` lên điện thoại ZY32MCZVB2 | `Success` |
| Màn Quét: Top App Bar, nút [≡], nút Scan, Drawer (Devices / App Settings / Support) | đúng |
| Thiết bị mẫu Demo Relay: tab in hoa ở trên, chuông có số 1, thẻ tile / hero / alarm, Drawer có Advanced + Device | đúng |
| Theme: System default (máy đang tối) → Light → trả lại System default | đổi ngay, không cần mở lại app |
| Chưa thử | kết nối thiết bị thật với bản 1.2 (relay C3, lò nung); bật/tắt relay thật |

---

## Cần thử cho 1.4 (người dùng tự làm)

Đợt "Hoàn thiện" (PLAN_HOAN_THIEN, H1–H10) **chưa thử trên phần cứng và chưa cài lên điện thoại**: lúc làm không có điện thoại nào cắm vào máy (`adb devices` trống). Mọi thứ dưới đây mới chỉ được kiểm tra bằng `flutter analyze`, `flutter test` và build APK / firmware.

Cài bản mới: `adb install -r release/VPHub_1.4.0_arm64.apk` (máy 32 bit: `_arm32`). Firmware `vph_demo` 1.3.0 và `test_app` cần nạp lại nếu muốn thử khóa `adv` và chuỗi lỗi tiếng Anh.

### A. Thư viện BLE mới (`universal_ble`) — quan trọng nhất

- [ ] Lần đầu mở app: màn giới thiệu → `Allow Bluetooth access` → hộp xin quyền của Android → vào màn Quét.
- [ ] Quét thấy `vph_demo`, relay C3 (firmware cũ), lò nung (firmware cũ). Mỗi thiết bị: kết nối, đọc số liệu, số đổi mỗi giây.
- [ ] Ghi trên từng thiết bị: `vph_demo` (bật LED, đổi màu, đổi ngưỡng rồi Save); relay C3 (đổi chế độ, **hỏi trước khi đóng relay tải thật**); lò nung (đổi setpoint, **không bật đốt lò khi chưa sẵn sàng**).
- [ ] Device info (bật Technician): MTU phải lớn hơn 23 (thường 247 hoặc 512), `Corrupted packets` = 0.
- [ ] **Lệnh dài 300–500 byte**: relay C3 hoặc `vph_demo`, màn lịch — đổi hết cả 5 (hoặc 3) khung giờ rồi bấm Save **một lần**. Phải báo `Saved`. Nếu báo lỗi hoặc treo: ghi lại MTU ở Device info và xuất nhật ký (mục D). Đây là chỗ app dựa vào việc Android tự gửi long write (SPEC §11.49), chưa kiểm chứng trên máy thật.
- [ ] Đổi tên thiết bị (`_name`), khởi động lại (`_reboot`, chỉ thấy ở Technician): app tự kết nối lại.

### B. Mở app, mất kết nối

- [ ] Mở app khi thiết bị đã nhớ **đang tắt**: phải ở lại màn Quét, không treo, không nhảy vào màn thiết bị; sau 10 s thanh quét dừng.
- [ ] Mở app khi thiết bị đã nhớ **đang bật**: trong khoảng 4 s tự vào thiết bị dùng gần nhất. Tắt "Auto-connect to last device" trong Settings thì không tự vào.
- [ ] Đang kết nối thì **rút điện thiết bị**: dòng trạng thái đổi thành `Connected · updated N s ago`, rồi `No new data for N s` màu vàng và số mờ đi (hoặc chuyển thẳng sang `Connection lost. Reconnecting…` nếu điện thoại báo mất kết nối sớm). Cắm điện lại trong vòng ~18 s: app tự vào lại. Để lâu hơn: `Can't reconnect to the device.` + `Try again`.
- [ ] Kéo xuống ở màn Quét để quét lại. Nhấn giữ thẻ thiết bị: `Rename`, `Remove` (có `Undo`).
- [ ] **Điện thoại Android 11 trở xuống** (nếu có): tắt Location rồi mở app → phải có thẻ `Turn on Location to find Bluetooth devices.` và nút mở cài đặt vị trí; bật Location, kéo xuống quét lại thì thấy thiết bị.
- [ ] Từ chối quyền Bluetooth: có thẻ hướng dẫn + `Open settings`.

### C. Standard / Technician

- [ ] Mặc định Standard: relay C3 **không** thấy `Sensor setup` (Modbus) và nút `Restart device`, **có** `Alarm settings`; lò nung **không** thấy tab PID, Alarm, Calibration, Auto-tune; màn Quét không hiện địa chỉ MAC.
- [ ] Settings → Technician mode: các màn trên hiện ngay, thanh đầu có chip `TECH`, Drawer có `Reload interface`, Settings có nhóm `Developer tools`.
- [ ] Set PIN (ví dụ 1234) → tắt Technician → bật lại: hỏi PIN; nhập sai báo `Incorrect PIN. Try again.`; nhập đúng thì bật. Remove PIN.
- [ ] `vph_demo` 1.3.0: nút `Restart device` chỉ thấy ở Technician.
- [ ] Đổi Language sang Tiếng Việt: chữ của app đổi ngay, hộp chọn giờ / ngày cũng bằng tiếng Việt; relay C3 đổi chữ sau khi kết nối lại.

### D. Báo lỗi và nhật ký

- [ ] Kết nối tới thiết bị đang tắt (bấm vào thẻ trong My devices): `Can't connect` + `Can't reach the device…`; ở Technician có nút `Details`.
- [ ] Ghi một giá trị sai (ví dụ ngưỡng thấp > ngưỡng cao trên `vph_demo`): SnackBar đỏ hiện đúng câu tiếng Anh của thiết bị.
- [ ] Settings → Developer tools → `Export diagnostics log`: hộp Share của Android mở ra, gửi được file `vphub_log.txt`; trong file có dòng kết nối, MTU, các lệnh `GHI`.

### E. Giao diện và đóng gói

- [ ] Icon trên launcher: nền xám đậm, hub xanh dương + trắng, không bị cắt mất nút nào ở launcher bo tròn. Android 13+: bật "Themed icons" thì icon đổi theo màu hệ thống.
- [ ] Màn khởi động: nền xám đậm + logo ở **cả chế độ sáng và tối** của máy, không chớp trắng trước khi vào app.
- [ ] Màn Thiết bị: nút ← góc trái về danh sách, nút ≡ bên phải cạnh chuông, vuốt từ cạnh trái mở menu.
- [ ] Bấm ON / OFF, nút lệnh, Save: máy rung nhẹ; vòng chờ hiện ngay trên nút.
- [ ] Chạm vào biểu đồ nhiệt độ: hiện giá trị + giờ. Thoát ra màn Quét rồi vào lại cùng thiết bị: đường biểu đồ cũ vẫn còn.
- [ ] Bật "Keep screen on while connected": màn hình không tự tắt khi đang ở màn Thiết bị.
- [ ] Bản release đã bật thu gọn mã (R8). Nếu app **thoát ngay khi mở hoặc khi bắt đầu quét / kết nối**, báo lại để tắt `isMinifyEnabled` trong `app/android/app/build.gradle.kts` và build lại — lỗi kiểu này chỉ lộ ra trên máy thật.

### F. Firmware

- [ ] Nạp `firmware/test_app` vào một ESP32-C3 trống: `serial_log.py --reset --expect TEST_SUMMARY` phải `28 Tests 0 Failures` (thêm 1 test `adv`, các chuỗi lỗi đã đổi sang tiếng Anh).
- [ ] Nạp `vph_demo` 1.3.0: Device info hiện Firmware 1.3.0; tab thứ hai tên `THRESHOLDS & SCHEDULE`.

### Đã kiểm tra không cần phần cứng (2026-10-09)

| Bước | Kết quả |
|---|---|
| `flutter analyze` | sạch |
| `flutter test` | 142 test qua (thêm test chế độ người dùng, màn Quét với bộ quét giả, bảng lỗi, nhật ký, độ mới số liệu, thao tác, l10n) |
| `flutter build apk --release --split-per-abi` | xem kích thước ở PLAN_HOAN_THIEN → Nhật ký |
| `firmware/test_app`, `firmware/examples/vph_demo` | build thành công với ESP-IDF v5.5 (chưa nạp) |
