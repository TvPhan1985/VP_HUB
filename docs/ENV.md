# ENV — Kết quả kiểm tra môi trường (2026-10-06)

Máy đã có đủ công cụ từ dự án `c3_relay_ctrl`, **không phải cài thêm gì**.

| Công cụ | Kết quả | Ghi chú |
|---|---|---|
| Git | 2.55.0.windows.5 | |
| Flutter | 3.47.5 stable (Dart 3.13.4) tại `D:\flutter` | |
| Android toolchain | SDK 37.0.0 tại `D:\Android\Sdk`, JDK 17 tại `D:\jdk17` | `flutter doctor` ✓ |
| adb | Thấy `moto g86 power 5G` (ZY32MCZVB2), Android 16 / API 36, trạng thái `device` | |
| ESP-IDF | v5.5.5 tại `C:\Espressif\frameworks\esp-idf-v5.5.5` | `tools/idf.ps1 --version` → `ESP-IDF v5.5.5` |
| ESP32-C3 | COM5 (USB VID 303A) | `tools/find_port.ps1` |
| Python | Không có Python hệ thống; `tools/.venv` tạo từ Python 3.11.2 của Espressif | Gói: `pyserial 3.5`, `pillow` (vẽ icon app) |
| Bluetooth PC | Không dùng được (xem ENV của c3_relay_ctrl) | BLE chỉ thử qua điện thoại |

`flutter doctor`: Flutter ✓, Android toolchain ✓, Connected device ✓. Chrome và Visual Studio thiếu (không liên quan, chỉ cần cho web / Windows desktop).

Công cụ trong `tools/` (copy từ `c3_relay_ctrl/tools`):
- `idf.ps1` — kích hoạt ESP-IDF rồi chạy `idf.py`; thư mục mặc định là `firmware/examples/vph_demo`, đổi bằng `-Dir`.
- `find_port.ps1` — tìm cổng COM của ESP32-C3.
- `serial_log.py` — đọc log serial có giới hạn thời gian (thay cho `idf.py monitor`).
