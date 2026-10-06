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
