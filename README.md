# VP Hub

Một app Android cho mọi thiết bị ESP32 của Phận, qua BLE. Giao diện **tự vẽ từ schema** thiết bị gửi lên, nên thiết bị mới không cần app mới.

| Thư mục | Nội dung |
|---|---|
| `app/` | App Flutter `vn.phan.vphub` |
| `firmware/components/vph_ble/` | Component ESP-IDF dùng chung cho thiết bị mới |
| `firmware/examples/vph_demo/` | Firmware mẫu ESP32-C3 |
| `firmware/test_app/` | Unity test của `vph_ble`, chạy trên chip |
| `release/` | APK đã build (`VPHub_<phiên bản>.apk`, không đưa vào git) |
| `tools/` | `idf.ps1`, `find_port.ps1`, `serial_log.py` |
| `docs/PROTOCOL.md` | Giao thức BLE chung VPH v1.1 (nguồn sự thật duy nhất) |
| `docs/SPEC.md` | Đặc tả app, các quyết định khi triển khai (§11) |
| `docs/LEGACY.md` | Adapter cho 2 thiết bị đời cũ |
| `docs/QUY_TAC_THIET_BI_MOI.md` | Quy tắc cho dự án sau |
| `docs/ENV.md` | Môi trường máy build |

## Thiết bị hỗ trợ

| Thiết bị | Cách app nói chuyện |
|---|---|
| Mọi thiết bị nói **VPH v1** (dùng component `vph_ble`) | Trực tiếp, không cần sửa app |
| Bộ relay ESP32-C3 (`c3_relay_ctrl`, firmware cũ 1.0.x) | Adapter `c3relay_v1` |
| Bộ điều khiển lò nung MAX31856 (`Temp_Max31856`, firmware cũ) | Adapter `kiln_v0` |
| Thiết bị mẫu (không cần phần cứng) | Menu **Thiết bị mẫu** ở màn Quét |

## Cài app lên điện thoại

Bật **Gỡ lỗi USB** trên điện thoại, cắm cáp, rồi:

```powershell
adb install -r release/VPHub_1.1.0.apk
```

Hoặc chép file APK vào điện thoại và mở để cài. Lần đầu mở app, bấm **Cho phép** quyền "Thiết bị ở gần" (Bluetooth).

## Build app

Cần Flutter stable (đã thử 3.47.5), JDK 17, Android SDK. Xem `docs/ENV.md`.

```powershell
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug      # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release    # chưa có keystore thì ký bằng khóa debug
```

Đổi icon: sửa `app/assets/icon/generate_icon.py`, chạy nó bằng `tools/.venv/Scripts/python`, rồi `dart run flutter_launcher_icons` trong `app/`.

## Thử giao diện không cần phần cứng

Màn Quét → menu ⋮ → **Thiết bị mẫu**: có 2 thiết bị giả, và mục **Mở file JSON** để thử schema của thiết bị mới mà không build lại app. Định dạng file: `app/assets/demo/README.md`.

## Firmware

```powershell
powershell -ExecutionPolicy Bypass -File tools/idf.ps1 -Dir firmware/examples/vph_demo build
powershell -ExecutionPolicy Bypass -File tools/find_port.ps1
powershell -ExecutionPolicy Bypass -File tools/idf.ps1 -Dir firmware/examples/vph_demo -p COM5 flash
tools/.venv/Scripts/python tools/serial_log.py --port COM5 --seconds 20 --reset
```

Làm thiết bị mới: đọc `docs/QUY_TAC_THIET_BI_MOI.md` và `firmware/components/vph_ble/README.md`.

Kế hoạch thực hiện và nhật ký: `docs/PLAN.md`.
