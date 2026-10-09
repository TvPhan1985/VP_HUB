# VP Hub

Một app Android cho mọi thiết bị ESP32 của Phận, qua BLE. Giao diện **tự vẽ từ schema** thiết bị gửi lên, nên thiết bị mới không cần app mới.

| Thư mục | Nội dung |
|---|---|
| `app/` | App Flutter `vn.phan.vphub` |
| `firmware/components/vph_ble/` | Component ESP-IDF dùng chung cho thiết bị mới |
| `firmware/examples/vph_demo/` | Firmware mẫu ESP32-C3 |
| `firmware/test_app/` | Unity test của `vph_ble`, chạy trên chip |
| `release/` | APK đã build (`VPHub_<bản>_arm64.apk`, `VPHub_<bản>_arm32.apk`, không đưa vào git) và `CHANGELOG.md` |
| `tools/` | `idf.ps1`, `find_port.ps1`, `serial_log.py` |
| `docs/PROTOCOL.md` | Giao thức BLE chung VPH v1.3 (nguồn sự thật duy nhất) |
| `docs/SPEC.md` | Đặc tả app, các quyết định khi triển khai (§11) |
| `docs/LEGACY.md` | Adapter cho 2 thiết bị đời cũ |
| `docs/QUY_TAC_THIET_BI_MOI.md` | Quy tắc cho dự án sau |
| `docs/COPY_STYLE.md` | Quy tắc viết chữ hiển thị (app và firmware) |
| `docs/LICENSES.md` | License của mọi thư viện trong app |
| `docs/ENV.md` | Môi trường máy build |

## Thiết bị hỗ trợ

| Thiết bị | Cách app nói chuyện |
|---|---|
| Mọi thiết bị nói **VPH v1** (dùng component `vph_ble`) | Trực tiếp, không cần sửa app |
| Bộ relay ESP32-C3 (`c3_relay_ctrl`, firmware cũ 1.0.x) | Adapter `c3relay_v1` |
| Bộ điều khiển lò nung MAX31856 (`Temp_Max31856`, firmware cũ) | Adapter `kiln_v0` |
| Thiết bị mẫu (không cần phần cứng) | Settings → bật **Technician mode** → Developer tools → **Demo devices** |

## Cài app lên điện thoại

Bật **Gỡ lỗi USB** trên điện thoại, cắm cáp, rồi:

```powershell
adb install -r release/VPHub_1.4.0_arm64.apk
```

Từ bản 1.4 APK chia theo CPU: `_arm64` là bản chính cho điện thoại hiện nay; `_arm32` cho máy cũ 32 bit.
Hoặc chép file APK vào điện thoại và mở để cài. Lần đầu mở app có màn giới thiệu; bấm **Allow Bluetooth access** rồi **Cho phép** quyền "Thiết bị ở gần" (Bluetooth).

## Build app

Cần Flutter stable (đã thử 3.47.5), JDK 17, Android SDK. Xem `docs/ENV.md`.

```powershell
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug      # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release --split-per-abi   # chưa có keystore thì ký bằng khóa debug
# chép build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   -> release/VPHub_<bản>_arm64.apk
#      build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk -> release/VPHub_<bản>_arm32.apk
```

Thư viện BLE là **`universal_ble`** (BSD-3-Clause) — không còn dùng `flutter_blue_plus` (phải mua license khi dùng thương mại). Chỉ thêm gói có license BSD / MIT / Apache / Zlib; sau khi thêm gói chạy `tools/gen_licenses.py` để cập nhật `docs/LICENSES.md`.

Chữ của app: `app/lib/l10n/app_en.arb` (gốc) và `app_vi.arb`; sửa xong chạy `flutter gen-l10n`. Quy tắc viết chữ: `docs/COPY_STYLE.md`.

Đổi icon / màn khởi động: sửa `app/assets/icon/generate_icon.py`, chạy nó bằng `tools/.venv/Scripts/python`, rồi trong `app/` chạy `dart run flutter_launcher_icons` và `dart run flutter_native_splash:create`.

## Thử giao diện không cần phần cứng

Màn Quét → nút [≡] → **Settings** → bật **Technician mode** → **Developer tools** → **Demo devices**: có 2 thiết bị giả, và mục **Open JSON file** để thử schema của thiết bị mới mà không build lại app. Định dạng file: `app/assets/demo/README.md`.

## Firmware

```powershell
powershell -ExecutionPolicy Bypass -File tools/idf.ps1 -Dir firmware/examples/vph_demo build
powershell -ExecutionPolicy Bypass -File tools/find_port.ps1
powershell -ExecutionPolicy Bypass -File tools/idf.ps1 -Dir firmware/examples/vph_demo -p COM5 flash
tools/.venv/Scripts/python tools/serial_log.py --port COM5 --seconds 20 --reset
```

Làm thiết bị mới: đọc `docs/QUY_TAC_THIET_BI_MOI.md` và `firmware/components/vph_ble/README.md`.

Kế hoạch thực hiện và nhật ký: `docs/PLAN.md`.

## Bắt đầu một dự án thiết bị mới

Đọc `docs/QUY_TAC_THIET_BI_MOI.md` (quy chuẩn). Cần mang đi chỗ khác thì chạy `tools/.venv/Scripts/python tools/make_kit.py` để tạo `release/VPH_KIT_<bản>.zip` (quy chuẩn, giao thức, file mẫu, component `vph_ble`, firmware mẫu, APK).

## Bản phát hành (release)

`release/VPHub_<bản>.apk` là bản **release**, ký bằng khóa riêng `app/android/vphub-release.jks` (mật khẩu trong `app/android/key.properties`). Hai file này **không nằm trong git** — phải tự sao lưu; mất khóa thì máy đã cài không cập nhật đè được nữa. Build: `cd app; flutter build apk --release`. Thiếu `key.properties` thì Gradle ký tạm bằng khóa debug.
