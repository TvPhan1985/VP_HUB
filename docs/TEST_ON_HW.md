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
