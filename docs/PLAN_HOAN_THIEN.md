# PLAN_HOAN_THIEN — VP Hub 1.4 "Hoàn thiện"

> Giao cho Claude Code. Viết ngày 2026-10-09 sau khi rà soát toàn bộ app 1.3.0.
> Đọc kèm: `CLAUDE.md`, `docs/PROTOCOL.md`, `docs/SPEC.md`, `docs/QUY_TAC_THIET_BI_MOI.md`.
> Mục tiêu: app **giữ nguyên phong cách giao diện 1.3**, nhưng hoàn chỉnh và chuyên nghiệp ở 5 chỗ:
> thư viện BLE sạch bản quyền, hai chế độ người dùng, câu chữ, cách xử lý tình huống xấu, đóng gói.

---

## 0. Quy tắc cho đợt này

- **Không làm lại giao diện.** Không đổi bảng màu, bố cục thẻ, thanh tab, Drawer ngoài những gì ghi trong file này.
- **Ngôn ngữ chính của app là tiếng Anh.** Mọi chữ mới viết tiếng Anh trước, rồi mới thêm bản tiếng Việt (§H4).
- Làm lần lượt H1 → H10. Mỗi phase xong: `flutter analyze` sạch, `flutter test` qua, commit `hN: <tóm tắt>`, đánh dấu `[x]`.
- Quyết định tự chọn khi file này chưa rõ: ghi vào SPEC §11 (mục mới từ 49). Đụng giao thức: sửa PROTOCOL trước, ghi §12.
- **Phần thử trên phần cứng người dùng tự làm.** Claude Code chỉ build APK, không cần hỏi cắm board. Cuối đợt, cập nhật `docs/TEST_ON_HW.md` thành **danh sách việc người dùng cần thử** (mục "Cần thử cho 1.4").
- Phiên bản cuối đợt: app `1.4.0+6`, `vph_ble` `1.2.0`, `vph_demo` `1.3.0`.

---

## H1. Đổi thư viện BLE sang loại không vướng bản quyền (làm đầu tiên)

**Lý do:** `flutter_blue_plus` 2.x miễn phí chỉ cho cá nhân, tổ chức phi lợi nhuận, trường học. Mọi công ty có lợi nhuận phải mua license, kể cả công ty 1 người. Code hiện khai `License.nonprofit` trong `fbp_gatt_link.dart`.

**Chọn:** `universal_ble` (BSD-3-Clause, publisher navideck.com, bản 2.3.0 phát hành 2026-09). Dự phòng: `flutter_reactive_ble` (BSD-3, Philips Hue).

- [x] Trước khi thêm: mở trang pub.dev và file LICENSE của bản sẽ dùng. **Phải** là BSD/MIT/Apache. Ghi tên bản + license vào SPEC §11. License khác → dừng, dùng phương án dự phòng.
- [x] Viết `core/transport/ub_gatt_link.dart` (lớp `UbGattLink implements GattLink`) thay `FbpGattLink`. Giữ nguyên interface `GattLink`, `OpQueue`, cách thử lại khi "busy".
  - Kết nối có timeout 10 s; `requestMtu(512)` sau khi kết nối (Android); `discoverServices`; luồng `connectionStream` → `lost`.
  - `subscribe`: gắn `onValueReceived` **trước** khi bật notify (như bản cũ).
  - Ghi có phản hồi (`withResponse: true`).
- [x] **Lệnh dài hơn MTU−3 (đến 500 byte):** Android tự dùng long write cho ghi có phản hồi. Kiểm tra bằng đọc mã nguồn plugin. Nếu plugin tự chặn gói > MTU−3: trong `VphTransport` đặt giới hạn thực = `min(500, mtu − 3)`, báo lỗi rõ khi vượt (§H6), ghi vào SPEC §11 và `TEST_ON_HW.md` để người dùng thử.
- [x] Màn Quét dùng `UniversalBle.startScan(scanFilter: ScanFilter(withServices: ...))`, trạng thái adapter, bật Bluetooth.
- [x] Bỏ `flutter_blue_plus` khỏi `pubspec.yaml`. `grep -r flutter_blue_plus app/` không còn kết quả.
- [x] Rà license **mọi** gói trong `pubspec.lock` (chạy `dart pub deps` + đọc LICENSE). Tạo `docs/LICENSES.md`: tên gói, bản, license. Gói nào không phải BSD/MIT/Apache/Zlib → ghi đỏ, báo người dùng.
- [x] Màn About có mục "Open-source licenses" gọi `showLicensePage()` của Flutter.
- **Xong khi:** test transport (dùng `fake_link.dart`) qua hết; demo chạy; APK build được.

---

## H2. Hai chế độ người dùng: Standard và Technician

Người vận hành (công nhân, nông dân) chỉ cần: xem số đo, bật/tắt, chế độ, lịch, báo động. Người kỹ thuật cần thêm: tham số Modbus, PID, hiệu chuẩn, chẩn đoán BLE, schema.

### H2.1 Chế độ của app
- [x] Cài đặt `userMode`: `standard` (mặc định) | `technician`. Lưu khóa `user_mode`.
- [x] Bật Technician: Settings → "Technician mode". Có thể đặt **PIN 4 số** (tùy chọn, mặc định không có PIN). Có PIN thì hỏi PIN khi bật. Tắt thì không hỏi.
- [x] Khi đang ở Technician: thanh đầu màn Thiết bị có chip nhỏ `TECH` (màu vàng cảnh báo), để người dùng biết đang ở chế độ có thể đổi tham số quan trọng.
- [x] **GHI CHÚ trong SPEC:** ẩn trong app chỉ để gọn, không phải bảo mật. Tham số nguy hiểm vẫn phải được firmware kiểm tra.

### H2.2 Giao thức: khóa `adv` (PROTOCOL v1.3, tương thích ngược)
- [x] Màn hoặc trường có `"adv":1` → chỉ hiện ở Technician. App cũ bỏ qua khóa lạ → hiện hết (không hỏng).
- [x] Màn `adv` ẩn khỏi tab và Drawer. Trường `adv` ẩn, nhưng vẫn dùng được trong `if`/`en`, `sub`, `hdr`.
- [x] Màn batch có trường `adv` đang ẩn: lệnh `set` chỉ gửi trường đã sửa (như hiện nay), không đụng trường ẩn.
- [x] `vph_ble` 1.2.0: hàm `vph_advanced(x)` dùng cho cả màn và trường; README component; test Unity cho chuỗi schema có `adv`.
- [x] Ghi PROTOCOL §5 + §12; QUY_TAC_THIET_BI_MOI thêm quy tắc: "Tham số cài đặt phần cứng, giao tiếp, hiệu chuẩn, PID, bảo vệ → `adv`".

### H2.3 Phân chia nội dung có sẵn
| Nội dung | Standard | Technician |
|---|---|---|
| Relay C3 — Overview, Schedule & Auto | Có | Có |
| Relay C3 — Alarm thresholds | Có (màn riêng "Alarm settings", `nav:"menu"`) | Có |
| Relay C3 — Modbus RTU sensor | Không | Có (màn "Sensor setup", `adv`) |
| Relay C3 — Device: đổi tên, restart | Đổi tên: có. Restart: không | Có |
| Lò nung — Operation, Program, Steps | Có | Có |
| Lò nung — PID, autotune, calibration, safety config | Không | Có |
| Mẫu `docs/mau/*.json`, demo, `vph_demo` | Đánh `adv` theo cùng nguyên tắc | |

- [x] Sửa `assets/legacy/c3relay_v1.json` (+ `.vi.json`), bảng vá trong `legacy_kiln.dart`, 2 file demo, 2 file mẫu, `vph_demo` cho đúng bảng trên.

### H2.4 Phân chia phần của app
| Phần | Standard | Technician |
|---|---|---|
| Thẻ thiết bị ở màn Quét | Icon, tên, model, cột sóng | Thêm địa chỉ MAC, chip `VPH`/`Legacy`, số dBm |
| Device Information | Name, Model, Firmware, Hardware, Signal, Status | Thêm: protocol, transport, schema ID, schema source, MTU, packets, corrupt packets, capabilities, MAC |
| Reload interface (tên mới của Reload Schema) | Không | Có |
| Demo Devices, Open JSON File | Không | Có (nhóm "Developer tools") |
| Câu báo lỗi | Câu dễ hiểu (§H6) | Thêm nút "Details" hiện lỗi gốc |
| Diagnostics log (xuất file) | Không | Có (§H6) |
| Clear saved interfaces (xóa cache schema) | Không | Có, hỏi lại trước khi xóa |

### H2.5 Màn Settings riêng (thay các mục bật/tắt nằm trong Drawer)
Drawer chỉ còn điều hướng: **Devices** (Device List), **Settings**, **Help & About**. Màn Thiết bị giữ thêm các màn `nav:"menu"` của thiết bị và Disconnect.

Màn `SettingsScreen`:
- **General**: Theme · Language · Auto-connect to last device · Keep screen on while connected (tùy chọn; dùng `wakelock_plus` nếu license đạt H1).
- **Advanced**: Technician mode (+ Set PIN / Remove PIN).
- **Developer tools** (chỉ hiện ở Technician): Demo devices · Open JSON file · Show device addresses · Export diagnostics log · Clear saved interfaces.
- **About**: Version, Open-source licenses.

- **Xong khi:** widget test: Standard không thấy màn/trường `adv`; Technician thấy đủ; đổi chế độ thì màn đang mở cập nhật ngay; tab đang mở bị ẩn thì chuyển về tab đầu.

---

## H3. Câu chữ (UX copy) — chuẩn chuyên nghiệp

### H3.1 Quy tắc chung (ghi vào `docs/COPY_STYLE.md`, áp cho app **và** firmware)
1. **Sentence case** mọi nơi (nhãn, nút, tiêu đề, mục menu): `Device list`, `Open JSON file`, `Auto-connect to last device`. Chỉ viết hoa toàn bộ ở thanh tab và chữ trạng thái `ON`/`OFF`.
2. **Không thuật ngữ nội bộ ở chế độ Standard:** cấm `schema`, `VPH`, `transport`, `MTU`, `packet`, `legacy`, `adapter`, `GATT`, `UUID`, `bit`.
3. **Nút ghi đúng hành động:** `Save`, `Discard`, `Restart`, `Turn on`, `Remove`. Không dùng `OK` cho hành động có hậu quả. Hộp xác nhận: tiêu đề là câu hỏi, nút xác nhận lặp lại động từ (`Restart device?` → `Restart`).
4. **Câu lỗi = chuyện gì xảy ra + làm gì tiếp:** `Can't reach the device. Move closer and make sure it's powered on.`
5. **Trạng thái trống luôn có hướng dẫn** và một nút hành động.
6. Số: dấu chấm thập phân; giờ 24h `HH:mm`; ngày `dd MMM yyyy` (theo locale); thời lượng `2 h 05 min`.
7. Đơn vị cách số một dấu cách (`25.4 °C`, `60 %`), trừ chỗ chật (tile) theo quy chuẩn hiện có.
8. Không dùng dấu chấm than, không emoji, không "Please" thừa.
9. Nhãn trường ≤ 24 ký tự; chú thích `d` là một câu hướng dẫn, có dấu chấm.

### H3.2 Sửa chữ cụ thể trong app (`lib/l10n/strings.dart` → file ARB, §H4)
| Hiện tại | Sửa thành |
|---|---|
| `BLE Device Manager` (tagline) | `Monitor and control your devices` |
| `Saved Devices` / `Nearby Devices` | `My devices` / `Nearby` |
| `No devices found` + hint | `No devices nearby` / `Turn on your device and keep the phone within a few meters.` + nút `Scan again` |
| `Remove from list` (xóa ngay) | `Remove device` → SnackBar `Device removed` + `Undo` |
| `Connection failed` + lỗi thô | Theo bảng §H6 |
| `Loading the interface from the device...` | `Loading device…` |
| `Connection lost, reconnecting…` / `Connection to the device was lost.` | `Connection lost. Reconnecting…` / `Can't reconnect to the device.` + `Try again` |
| `Reload Schema` | `Reload interface` (chỉ Technician) |
| `Device Information` | `Device info` |
| `Disconnect` (làm ngay) | `Disconnect` → hỏi `Disconnect from <name>?` khi có thay đổi chưa lưu; không có thì làm ngay |
| `Transport` / `Corrupt (truncated) packets` / `Largest VALUES packet` | `Protocol` / `Corrupted packets` / `Largest data packet` (chỉ Technician) |
| `The schema of this screen is invalid and cannot be rendered` | `This screen can't be displayed. Update the device firmware or contact support.` (Technician: thêm Details) |
| `This device uses a newer protocol. Please update VP Hub.` | `This device needs a newer version of VP Hub.` |
| `Sent: <label>` | `<label>: command sent` |
| `Alarm bit 3` | `Alarm 4` (đếm từ 1) |
| `Collecting chart data...` | `Collecting data…` |
| `Item 1` (rep mặc định) | `#1` |
| Về `About`: đoạn nói "schema", "VPH protocol v1.1" | Standard: `VP Hub connects to your sensors and controllers over Bluetooth.` Technician: thêm dòng `Protocol VPH v1.3` |
| Hộp xác nhận: nút `OK` | Động từ của hành động; nếu không biết thì `Confirm` |

- [x] Rà **mọi** chuỗi còn lại theo H3.1, sửa cả bản tiếng Việt cho khớp nghĩa.

### H3.3 Sửa chữ phía thiết bị (schema có sẵn, firmware mẫu, `vph_ble`)
- [x] `c3relay_v1.json`: `Silence` → `Silence buzzer`; `Auto source` → `Control by`; `Measured value` → `Sensor`; `Threshold type` → `Turn on when`; `Scale divisor` → `Scale factor`; `Index` → `Register position`; chú thích `src` tách ngắn từng lựa chọn; câu `_reboot` theo H3.1-3.
- [x] Bảng vá lò nung, 2 demo, 2 mẫu, `vph_demo`: rà theo H3.1.
- [x] `vph_ble`: mọi chuỗi lỗi có sẵn còn tiếng Việt (lệnh quá dài, trường không tồn tại, v.v.) → tiếng Anh (`Command too long`, `Unknown field: <id>`). Cập nhật test Unity.
- [x] Adapter relay C3: bảng dịch lỗi firmware cũ giữ, nhưng câu tiếng Anh phải theo H3.1.

---

## H4. Ngôn ngữ: tiếng Anh là chính

- [x] Chuyển `lib/l10n/strings.dart` sang **Flutter gen-l10n** (`flutter_localizations` + `intl`, file `lib/l10n/app_en.arb` là bản gốc, `app_vi.arb` là bản dịch). Bỏ biến toàn cục `Lang.code` và đoạn `markNeedsBuild` đi qua cả cây widget.
- [x] `MaterialApp`: `supportedLocales: [en, vi]`, `locale` theo cài đặt; mặc định **English** (không theo ngôn ngữ máy), người dùng chọn Tiếng Việt trong Settings.
- [x] Nhờ `flutter_localizations`, hộp chọn giờ/ngày, nút hệ thống, định dạng ngày theo đúng ngôn ngữ đang chọn.
- [x] Chữ của thiết bị VPH vẫn hiện nguyên văn (tiếng Anh theo quy chuẩn). Schema lưu sẵn trong app (relay C3, lò, demo) vẫn có 2 bản `.json`/`.vi.json`.
- [x] Test: mọi khóa có ở `app_en.arb` đều có ở `app_vi.arb`; không còn chuỗi hiển thị viết cứng trong `lib/ui` (test grep đơn giản hoặc lint).

---

## H5. Mở app và quét

- [x] **Bỏ nhảy thẳng vào thiết bị cũ.** Khi mở app: quét 4 s. Thấy thiết bị đã nhớ gần nhất (theo `lastMs`) trong kết quả → tự kết nối. Không thấy → ở lại màn Quét, quét tiếp đến hết 10 s.
- [x] **Lần đầu mở app (onboarding 1 màn):** logo, 1 câu giới thiệu, giải thích vì sao cần quyền Bluetooth, nút `Allow Bluetooth access` → mới gọi hộp xin quyền của Android. Lưu khóa `onboarded`.
- [x] Quyền bị từ chối vĩnh viễn → thẻ hướng dẫn + `Open settings` (đã có, sửa chữ theo H3).
- [x] Android 6–11: quét mà công tắc Location đang tắt → thẻ `Turn on Location to find Bluetooth devices` + nút mở cài đặt vị trí.
- [x] Kéo xuống để quét lại (`RefreshIndicator`).
- [x] Thẻ thiết bị đã nhớ: nhấn giữ → menu `Rename` (chỉ đổi tên hiển thị trong app) / `Remove`.
- [x] Sửa `_busy` trong `_open()` bằng `try/finally`.

---

## H6. Báo lỗi và nhật ký chẩn đoán

- [x] Lớp `core/errors.dart`: đổi mọi exception BLE/transport thành `AppError(kind, detail)`. Bảng tối thiểu:

| Tình huống | Câu hiện cho người dùng |
|---|---|
| Bluetooth tắt | `Bluetooth is off. Turn it on to connect.` |
| Thiếu quyền | `VP Hub needs Bluetooth access to connect.` |
| Hết thời gian kết nối / không thấy thiết bị | `Can't reach the device. Move closer and make sure it's powered on.` |
| Thiết bị không có dịch vụ hỗ trợ | `This device isn't supported by VP Hub.` |
| INFO sai, schema hỏng | `The device sent invalid data. Restart the device and try again.` |
| Không nhận RESULT trong 3 s | `The device didn't respond. Try again.` |
| Thiết bị từ chối (có `err`) | nguyên văn `err` của thiết bị |
| Lệnh quá dài | `Too many changes at once. Save fewer changes and try again.` |
| Lỗi khác | `Something went wrong. Try again.` |

- [x] Standard: chỉ hiện câu trên. Technician: thêm nút `Details` hiện `detail` (lỗi gốc, rút gọn 300 ký tự).
- [x] **Nhật ký chẩn đoán:** ghi vòng (ring buffer) 500 dòng gần nhất trong bộ nhớ + file `vphub_log.txt` trong thư mục app (tối đa 256 KB, xoay vòng): kết nối, mất kết nối, MTU, lỗi, lệnh ghi (id, không ghi giá trị `str`). Technician → `Export diagnostics log` chia sẻ file qua hộp Share của Android (`share_plus`, kiểm tra license theo H1).

---

## H7. Độ tin cậy số liệu

- [x] `DeviceSession` lưu thời điểm nhận VALUES cuối (`lastValuesAt`).
- [x] Dưới tên thiết bị (dòng trạng thái): `Connected · updated 3 s ago` khi > 5 s; > 15 s → chữ vàng `No new data for 20 s`; số trên các thẻ mờ đi (opacity 0.6). Ngưỡng: 15 s mặc định.
- [x] Biểu đồ: bật chạm để xem giá trị + giờ (`LineTouchData`), định dạng theo `dp`, đơn vị.
- [x] Lịch sử biểu đồ giữ theo **thiết bị** trong suốt lúc app còn chạy (lưu ở một kho nhớ theo `deviceId`, không mất khi thoát màn rồi vào lại). Giới hạn 1 giờ như cũ.

---

## H8. Thao tác

- [x] Màn Thiết bị: nút `←` ở góc trái (về danh sách), nút `[≡]` chuyển sang bên phải cạnh chuông, hoặc mở Drawer bằng vuốt từ cạnh trái. Ghi quyết định vào SPEC §11 (thay mục 38 phần nút).
- [x] Rung nhẹ (`HapticFeedback.lightImpact`) khi bấm ON/OFF, nút lệnh, Save.
- [x] Nút lệnh và ON/OFF: trong lúc chờ RESULT, nút hiện vòng chờ nhỏ ngay trên nút (không chỉ ở hàng).
- [x] Nút xác nhận của hộp hỏi lại dùng màu đỏ khi hành động là dừng/khởi động lại/xóa.
- [x] Sửa `_syncTabs()`: không tạo `TabController` trong `build()`. Tạo lại trong listener của session (hoặc `didUpdateWidget`), rồi `setState`.

---

## H9. Đóng gói

- [x] **Icon thích ứng:** `flutter_launcher_icons` với `adaptive_icon_background` (màu `#0F172A`) + `adaptive_icon_foreground` (hình hub, vùng an toàn 66%), + `adaptive_icon_monochrome` (Android 13 themed icon). Màu icon theo app: nền xám đậm `#0F172A`, nút trung tâm `#38BDF8`, các nút vệ tinh trắng. Sửa `generate_icon.py` sinh 3 lớp.
- [x] **Màn khởi động:** `flutter_native_splash` (kiểm tra license), nền `#0F172A` ở cả sáng/tối, logo giữa; Android 12+ dùng API splash hệ thống. Không còn chớp trắng.
- [x] **Build:** `flutter build apk --release --split-per-abi`; chép `app-arm64-v8a-release.apk` thành `release/VPHub_1.4.0_arm64.apk` (bản chính) và `armeabi-v7a` thành `release/VPHub_1.4.0_arm32.apk` (máy cũ). Bật `minifyEnabled` + `shrinkResources` cho release nếu build và test vẫn qua.
- [x] Ghi kích thước APK cũ/mới vào PLAN (Nhật ký).
- [x] `release/CHANGELOG.md`: thay đổi 1.4.0 viết cho người dùng (tiếng Anh, ngắn).
- [x] `tools/make_kit.py`: thêm `COPY_STYLE.md`, `LICENSES.md`, APK mới.

---

## H10. Cập nhật tài liệu và kết thúc

- [x] PROTOCOL v1.3 (`adv`), SPEC (§3, §4, §5, §11 mục mới), QUY_TAC_THIET_BI_MOI (§5 câu chữ trỏ sang `COPY_STYLE.md`, quy tắc `adv`, bảng nghiệm thu thêm dòng "Standard mode không thấy tham số kỹ thuật"), README (thư viện BLE mới, APK chia theo CPU).
- [x] `docs/TEST_ON_HW.md` → mục **"Cần thử cho 1.4"** (người dùng tự làm), ít nhất:
  - Kết nối, đọc, ghi trên `vph_demo`, relay C3 (firmware cũ), lò nung (firmware cũ) bằng thư viện BLE mới.
  - Lưu màn batch có lệnh 300–500 byte (5 khung giờ đổi hết một lần).
  - Mở app khi thiết bị đã nhớ đang tắt: phải ở lại màn Quét, không treo.
  - Rút điện thiết bị khi đang kết nối: dòng "No new data", rồi "Reconnecting", cắm lại tự vào.
  - Standard / Technician: màn Modbus, PID ẩn/hiện đúng; PIN đúng/sai.
  - Icon trên launcher, màn khởi động ở chế độ sáng và tối.
  - Điện thoại Android 11 trở xuống: tắt Location rồi quét.
- [x] Báo cáo cuối đợt (tiếng Việt): đã làm gì, file nào, kết quả test, kích thước APK, license các gói, việc người dùng cần thử.

---

## Nhật ký

**2026-10-09 — làm xong H1 → H10.** Mỗi phase một commit `hN: ...`, `flutter analyze` sạch, `flutter test` qua (100 test lúc bắt đầu → 142 test).

| Phase | Kết quả chính |
|---|---|
| H1 | `universal_ble` 2.3.0 (BSD-3) thay `flutter_blue_plus`; `UbGattLink`, `DeviceScanner`; `docs/LICENSES.md`; mục Open-source licenses |
| H2 | `AppSettings` (Standard / Technician, PIN), khóa `adv` (PROTOCOL v1.3, `vph_ble` 1.2.0, `vph_demo` 1.3.0), màn Settings, Drawer chỉ còn điều hướng |
| H3 | `docs/COPY_STYLE.md`; viết lại toàn bộ chữ của app, schema lưu sẵn, bảng lỗi relay C3, chuỗi lỗi `vph_ble` sang tiếng Anh |
| H4 | Flutter gen-l10n (`app_en.arb` gốc, `app_vi.arb`), bỏ `Lang.code`; lõi trả `AppError` thay vì chuỗi |
| H5 | Mở app quét 4 s rồi mới tự kết nối; onboarding; thẻ Location (Android 6–11); kéo để quét lại; Rename / Remove |
| H6 | Bảng lỗi + nút Details (Technician); nhật ký chẩn đoán 500 dòng / 256 KB; Export diagnostics log |
| H7 | `lastValuesAt`, dòng `updated N s ago` / `No new data`; biểu đồ chạm xem giá trị; lịch sử biểu đồ theo thiết bị |
| H8 | Nút ← bên trái, ≡ bên phải; rung nhẹ; vòng chờ trên nút; nút xác nhận đỏ; `_syncTabs()` ra khỏi `build()` |
| H9 | Icon thích ứng 3 lớp, màn khởi động, APK chia theo CPU + thu gọn mã, `CHANGELOG.md`, `make_kit.py` |
| H10 | PROTOCOL v1.3, SPEC §11 mục 49–63, QUY_TAC, README, TEST_ON_HW mục "Cần thử cho 1.4" |

**Kích thước APK**

| Bản | File | Kích thước |
|---|---|---|
| 1.3.0 | `VPHub_1.3.0.apk` (một file cho mọi CPU) | 54,6 MB |
| 1.4.0 | `VPHub_1.4.0_arm64.apk` (bản chính) | **20,8 MB** |
| 1.4.0 | `VPHub_1.4.0_arm32.apk` (máy cũ) | 18,5 MB |

Nhỏ đi khoảng 62% nhờ chia theo CPU, thu gọn mã (R8) và bỏ tài nguyên không dùng. Bộ quy chuẩn `VPH_KIT_1.4.0.zip`: 19,4 MB.

**License**: mọi gói trong `pubspec.lock` là BSD / MIT / Apache, trừ `bluez` và `dbus` (MPL-2.0, chỉ dùng cho Linux desktop, đã có sẵn từ bản 1.3, không phải gói mới thêm) — ghi đỏ trong `docs/LICENSES.md`. Gói thêm trong đợt này: `universal_ble`, `wakelock_plus`, `path_provider`, `share_plus`, `intl`, `flutter_localizations` (BSD-3); `flutter_native_splash` (MIT, chỉ lúc phát triển).

**Chưa làm được / cần người dùng**

- Không có điện thoại cắm vào máy lúc làm (`adb devices` trống) nên **chưa cài và chưa chạy bản 1.4.0 trên máy thật**, chưa thử BLE với thư viện mới, chưa thử bản đã thu gọn mã. Danh sách việc cần thử: `docs/TEST_ON_HW.md` → "Cần thử cho 1.4".
- Firmware `test_app` và `vph_demo` 1.3.0 chỉ mới build, chưa nạp.
- Chưa đẩy lên GitHub và chưa tạo bản phát hành (chờ thử xong trên máy thật).

