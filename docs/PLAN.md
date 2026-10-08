# PLAN — VP Hub

Claude Code làm lần lượt **Phần 0 → A → B → C**. **Phần D chỉ làm khi người dùng bảo.**
- Phần 0, A, B: không cần phần cứng, làm liên tục không hỏi.
- Phần C: cần điện thoại + board cắm sẵn.

Quy tắc chung:
- Mỗi phase xong: đánh dấu `[x]`, chạy `flutter analyze` + `flutter test` (với phần app) hoặc build (với firmware), commit `phaseN: <tóm tắt>`.
- Một bước bị chặn, thử 3 cách khác nhau không được: ghi vào **Vướng mắc** cuối file, làm tiếp phần không phụ thuộc, cuối cùng báo người dùng.
- Ghi giờ bắt đầu/kết thúc từng phase ở cuối file.
- **Không sửa gì** trong `D:\2026\c3_relay_ctrl` và `D:\2026\Temp_Max31856-main` ở Phần 0–C (chỉ đọc để đối chiếu).

---

## PHẦN 0 — MÔI TRƯỜNG

### Phase 0
- [x] Kiểm tra nhanh (máy đã có đủ theo `D:\2026\c3_relay_ctrl\docs\ENV.md`): `flutter --version`, `flutter doctor`, `adb devices`, ESP-IDF v5.5.5 ở `C:\Espressif\frameworks\esp-idf-v5.5.5`. Ghi kết quả vào `docs/ENV.md`.
- [x] Copy `tools/idf.ps1`, `tools/find_port.ps1`, `tools/serial_log.py` từ `c3_relay_ctrl/tools` sang `tools/` của dự án này, sửa đường dẫn thư mục firmware cho đúng. Tạo `tools/.venv` (Python 3.11 của Espressif) với `pyserial`.
- [x] Thiếu gì mới cài (cách cài như PLAN Phần 0 của c3_relay_ctrl).
- **Xong khi:** `flutter doctor` không lỗi đỏ ở Flutter + Android toolchain; `tools/idf.ps1 --version` ra v5.5.x.

---

## PHẦN A — APP ANDROID (không cần phần cứng)

### Phase 1 — Khung dự án
- [x] `git init`, `.gitignore` (build/, .dart_tool/, firmware/**/build, sdkconfig, managed_components/, tools/.venv, android/key.properties, *.jks)
- [x] `flutter create --org vn.phan --project-name vphub --platforms android app`
- [x] `pubspec.yaml`: `flutter_blue_plus ^2.3`, `fl_chart`, `shared_preferences`, `permission_handler`, `package_info_plus`, `file_picker`. Tên app "VP Hub", minSdk 23.
- [x] `AndroidManifest.xml`: quyền theo SPEC §1.
- **Xong khi:** `flutter build apk --debug` thành công.

### Phase 2 — Model + parser + điều kiện
- [x] `core/model/*`: `VphInfo`, `VphScreen`, `VphField`, `VphRepeat`, đọc được **cả khóa ngắn và khóa dài** (PROTOCOL §5), kiểu `float/int` → `num`.
- [x] Mở rộng `rep` thành danh sách trường + thông tin nhóm thẻ (PROTOCOL §5.3), hỗ trợ `cnt`.
- [x] `core/cond.dart` (PROTOCOL §5.5).
- [x] Test: theo SPEC §8 (dùng chuỗi schema thật của lò nung chép từ `Temp_Max31856-main/main/ble_ui.c`).
- **Xong khi:** test qua hết.

### Phase 3 — Transport VPH + Demo
- [x] `DeviceTransport` (SPEC §2) và `VphTransport` theo PROTOCOL §9 (đọc schema theo trang §8.1): hàng đợi thao tác BLE tuần tự, `q` tăng dần, chờ RESULT 3 s, cache schema `model+sch`.
- [x] `DemoTransport` đọc `assets/demo/*.json`. Tạo 2 file demo: `demo_relay.json` (giống ví dụ PROTOCOL §11 + 1 màn batch có `rep` khung giờ) và `demo_all_types.json` (đủ mọi kiểu, mọi `w`, `if/en`, một kiểu lạ `"t":"xyz"`).
- [x] `DeviceSession` (ChangeNotifier): info, screens, values, lịch sử trend, giá trị đang sửa, trạng thái kết nối, tự kết nối lại (1, 2, 5, 10 s).
- **Xong khi:** unit test của transport (giả lập characteristic) qua.

### Phase 4 — Bộ vẽ giao diện
- [x] `ui/render/*`: mỗi kiểu một widget (SPEC §4), `header_bar`, `batch_bar`, `trend_chart`.
- [x] `device_screen.dart`: tab theo schema, thẻ nhóm/lặp, xác nhận `c`, banner mất kết nối.
- [x] Màn Demo chạy được cả 2 file demo.
- [x] Widget test: vẽ hết 2 demo không lỗi; màn batch: sửa → Lưu → gửi đúng 1 lệnh `set`.
- **Xong khi:** test qua; chụp ảnh màn hình demo trên emulator nếu có (không có thì bỏ qua).

### Phase 5 — Màn Quét + thiết bị đã dùng
- [x] Xin quyền, quét lọc 3 UUID, danh sách đã dùng, tự kết nối thiết bị gần nhất (SPEC §3).
- [x] `transport_registry.dart`: chọn transport theo UUID dịch vụ trong kết quả quét.
- [x] Màn Thông tin thiết bị (SPEC §5).

### Phase 6 — Adapter lò nung (`docs/LEGACY.md` L2)
- [x] `legacy_kiln.dart` + vá schema + xác nhận ghi qua VALUES.
- [x] Test theo SPEC §8.

### Phase 7 — Adapter relay C3 (`docs/LEGACY.md` L1)
- [x] `assets/legacy/c3relay_v1.json` (4 màn hình, đúng định dạng VPH; test in ra kích thước từng màn để Phần D biết trước).
- [x] `legacy_c3relay.dart`: gộp STATUS + CONFIG → VALUES, ánh xạ ghi, hàng đợi 1 lệnh chờ RESULT, `_time` khi kết nối.
- [x] So từng chức năng với app cũ (`c3_relay_ctrl/app/lib/ui/*_tab.dart`), ghi bảng đối chiếu vào SPEC §11.
- [x] Test theo SPEC §8.

### Phase 8 — Đóng gói
- [x] Icon app (tự sinh bằng script như `Temp_Max31856-main/app/assets/icon/generate_icon.py`).
- [x] `flutter build apk --release` (chưa có keystore thì dùng khóa debug như app lò nung). Copy APK vào `release/VPHub_<version>.apk`.
- [x] `README.md`: cách build, cách cài, danh sách thiết bị hỗ trợ.

---

## PHẦN B — COMPONENT FIRMWARE DÙNG CHUNG `vph_ble` (không cần phần cứng)

### Phase 9 — Component `vph_ble`
- [x] `firmware/components/vph_ble/` (C, NimBLE, ESP-IDF v5.5, giữ tương thích v6.x — lò nung từng dùng v6.1): API theo PROTOCOL §10. Lấy khung NimBLE từ `c3_relay_ctrl/firmware/components/ble_svc/ble_svc.c` (đã chạy thật, có SUBSCRIBE, MTU 512, quảng bá UUID + tên ở scan response) và cách dựng schema của `Temp_Max31856-main/main/ble_ui.c`.
- [x] Lệnh ghi đi qua queue, xử lý trong `vph_poll()` ở task của project. Không ghi NVS hay quảng bá lại trong callback GATT.
- [x] Tự tính `sch` (CRC16 các chuỗi schema), tự cắt trang schema (PROTOCOL §8.1), tự ghép `hdr` vào VALUES, cảnh báo log khi vượt PROTOCOL §8.
- [x] `firmware/components/vph_ble/README.md`: cách thêm vào dự án mới (xem `docs/QUY_TAC_THIET_BI_MOI.md`), file `VERSION` = `1.0.0`.
- [x] `firmware/test_app/`: Unity test chạy trên chip: dựng schema, kích thước, ghép VALUES, parse WRITE đơn/lô, id dành riêng, CRC.

### Phase 10 — Firmware mẫu `vph_demo` (ESP32-C3 SuperMini)
- [x] `firmware/examples/vph_demo/`: dùng `vph_ble` qua `idf_component.yml` đường dẫn tương đối. Model `vphdemo`, 2 màn hình: "Tổng quan" (live: nhiệt độ giả `w:trend`, công tắc LED WS2812 GPIO8, enum màu, act "Bíp") và "Cài đặt" (batch: `rep` 3 khung giờ, 2 ngưỡng ràng buộc nhau, trả lỗi tiếng Việt khi sai). Có `caps:["time"]`.
- [x] Đây là **mẫu chuẩn** để copy khi làm dự án mới.
- **Xong khi:** `tools/idf.ps1 -Dir firmware/examples/vph_demo build` và build `test_app` thành công.

---

## PHẦN C — THỬ TRÊN PHẦN CỨNG (cần người dùng)

Hỏi người dùng cắm: điện thoại (USB debugging), ESP32-C3 trống để nạp `vph_demo`, bộ relay C3 và bộ lò nung (đang chạy firmware cũ).

### Phase 11
- [ ] Nạp `test_app`, đọc log `--expect TEST_SUMMARY`, phải 0 lỗi.
- [ ] Nạp `vph_demo`. Cài APK: `adb install -r`. Kiểm tra: quét thấy, đọc schema, notify chạy, live + batch + lỗi tiếng Việt + act + `_time` + `_name` + `_reboot`, mất kết nối/kết nối lại, cache schema (lần 2 vào nhanh hơn).
- [ ] Bộ relay C3 (firmware cũ): chạy lại kịch bản trong `c3_relay_ctrl/docs/TEST_ON_HW.md` bằng VP Hub thay cho app cũ.
- [ ] Bộ lò nung (firmware cũ): đọc nhiệt độ, đổi setpoint, PID, chương trình nhiều bước. **Không bật đốt lò** khi chưa hỏi người dùng.
- [ ] Lấy log app bằng `adb logcat -d` (không chạy logcat không giới hạn). Ghi kết quả vào `docs/TEST_ON_HW.md`.

---

## PHẦN D — CHUYỂN 2 FIRMWARE CŨ SANG VPH (chỉ làm khi người dùng bảo)

Làm trên nhánh git riêng `vph` của từng dự án, không đụng nhánh chính.
- [ ] **c3_relay_ctrl**: thay `ble_svc` bằng `vph_ble`, schema y như `assets/legacy/c3relay_v1.json` (khác: id thật, RESULT có `q`), lệnh `mode/out/silence/time/reboot` thành ghi trường, CONFIG thành các màn `batch`. Firmware `1.1.0`. Chạy lại 36 test cũ + test mới.
- [ ] **Temp_Max31856**: hỏi người dùng thư mục firmware thật (tài liệu cũ ghi `C:\data\Project\Control_Temp_MAX31856`) và phiên bản ESP-IDF. Thay `main/ble_ui.c` bằng `vph_ble`, chuyển khóa sang dạng ngắn, thêm RESULT, `safety_clear` thành `act` có `if`.
- Lưu ý: gói quảng bá 31 byte chỉ chứa được một UUID 128-bit, nên firmware mới **chỉ** quảng bá UUID VPH → app cũ sẽ không quét thấy nữa. Từ đó dùng VP Hub.

---

## Vướng mắc
_(ghi vào đây)_

- **Phase 11 đang chờ người dùng** (chi tiết: `docs/TEST_ON_HW.md`): (1) chưa bấm "Cho phép" quyền Bluetooth trên điện thoại; (2) board ở COM5 là bộ relay thật đang chạy firmware `c3_relay_ctrl`, cần một ESP32-C3 trống để nạp `test_app`/`vph_demo`; (3) cần cho phép trước khi đóng/cắt relay thật và trước khi thử lò.
- Phase 9: tương thích ESP-IDF v6.x mới chỉ chuẩn bị trong `CMakeLists.txt`/`idf_component.yml` (đổi `json` → `espressif/cjson`), **chưa build thử** vì máy chỉ có v5.5.5.
- Phase 4: máy không có emulator Android nên không chụp ảnh demo trên emulator; thay bằng chạy thật trên điện thoại ở Phần C.
- Phase 2/6: bản `Temp_Max31856-main/main/app_config.h` trên máy **không có** `TC_OFFSET_MIN_C/MAX_C/STEP_C` (mà `ble_ui.c` dùng), nên chuỗi schema màn "calibration" trong `app/test/kiln_schemas.dart` dùng giá trị giả định. 6 màn còn lại dựng đúng từ hằng số thật. Không ảnh hưởng app (schema đọc thật từ thiết bị).

## Nhật ký thời gian
_(ghi vào đây)_

| Phase | Bắt đầu | Kết thúc | Ghi chú |
|---|---|---|---|
| 0 | 2026-10-06 21:58 | 22:02 | Máy đã đủ công cụ, chỉ tạo `tools/.venv` |
| 1 | 22:02 | 22:06 | `flutter create`, pubspec, manifest |
| 2–7 | 22:06 | 22:30 | Lõi + giao diện + 2 adapter viết liền một mạch; `flutter analyze` sạch, 77 test qua |
| 8 | 22:30 | 22:50 | Icon, APK debug + release (`release/VPHub_1.0.0.apk`), README |
| 9–10 | 22:50 | 23:20 | `vph_ble` (lõi + NimBLE), `test_app` 24 test, `vph_demo`; cả hai build thành công với ESP-IDF v5.5.5 |
| U1–U7 | 2026-10-07 | 2026-10-07 | `docs/PLAN_GIAO_DIEN.md`: PROTOCOL v1.1, widget mới, NavigationBar, màn Quét, WRITE 500 byte, `vph_ble` 1.1.0. 88 test app + 27 test Unity trên chip qua; `release/VPHub_1.1.0.apk` đã cài; `vph_demo` 1.1.0 đang nằm trên board COM5 (xem `docs/TEST_ON_HW.md`) |
| UI 1.2 | 2026-10-08 | 2026-10-08 | Làm lại giao diện theo PDF quy chuẩn (Top App Bar + tab trên + Navigation Drawer + bảng màu sáng/tối WCAG), chữ app sang tiếng Anh; SPEC §11 mục 38–44; 94 test qua; `release/VPHub_1.2.0.apk`. 1.2.1: thêm chọn ngôn ngữ Anh/Việt, nút OFF cùng màu nút ON (SPEC §11 mục 45–46), 96 test qua, `release/VPHub_1.2.1.apk` |
