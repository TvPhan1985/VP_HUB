# CLAUDE.md — vp_hub

App Android **VP Hub** (Flutter): một app quét, đọc, điều khiển mọi thiết bị ESP32 của Phận qua BLE, giao diện **tự vẽ từ schema** thiết bị gửi lên. Kèm component firmware dùng chung `vph_ble` (ESP-IDF, C) để các dự án sau dùng được app mà không làm app mới.

Đọc theo thứ tự trước khi làm:
1. `docs/PROTOCOL.md` — giao thức VPH v1, **nguồn sự thật duy nhất** về BLE
2. `docs/SPEC.md` — đặc tả app
3. `docs/LEGACY.md` — adapter cho 2 thiết bị cũ
4. `docs/PLAN.md` — các phase, làm lần lượt Phần 0 → A → B → C. **Phần D chỉ làm khi người dùng bảo**
5. `docs/QUY_TAC_THIET_BI_MOI.md` — quy tắc cho dự án sau (đừng làm trái)

Dự án tham khảo (CHỈ ĐỌC, không sửa ở Phần 0–C):
- `D:\2026\c3_relay_ctrl` — relay ESP32-C3, app Flutter viết cứng, khung NimBLE đã chạy thật
- `D:\2026\Temp_Max31856-main` — lò nung, app Flutter giao diện sinh từ schema (ý tưởng gốc của VPH)

## Ngôn ngữ
- Trao đổi, báo cáo, hỏi lại người dùng: **tiếng Việt**, từ phổ thông, dễ hiểu. Thuật ngữ (BLE, MTU, schema, commit…) giữ tiếng Anh.
- Chữ hiển thị trong app: **tiếng Anh** (mặc định) dùng các từ ngữ chuyên nghiệp, kèm bản **tiếng Việt có dấu** để người dùng chọn trong menu (Language). Mỗi chữ mới phải có đủ 2 bản trong `lib/l10n/strings.dart` (`tr('English', 'Tiếng Việt')`); schema lưu sẵn có 2 file `.json` (Anh) và `.vi.json` (Việt).
- Comment code và log firmware: tiếng Việt ngắn gọn (log firmware không dấu được), **không emoji**.
- Cuối mỗi phase tóm tắt: đã làm gì, file nào, kết quả kiểm tra, người dùng cần làm gì tiếp.

## Cách làm việc
- Người dùng cho phép tự cài phần mềm còn thiếu, tự nạp firmware, tự cài app lên điện thoại (Phần C).
- Làm liên tục Phần 0, A, B không hỏi lại. SPEC/PROTOCOL chưa rõ thì tự chọn cách hợp lý nhất, ghi vào SPEC §11 (hoặc PROTOCOL §12 nếu đụng giao thức) rồi làm tiếp.
- Chỉ hỏi khi: cần bấm UAC, cần cắm/nhấn nút phần cứng, cần bấm cho phép trên điện thoại, hoặc trước khi làm gì có thể bật đốt lò / đóng relay tải thật.
- Lệnh build, nạp, test: **chạy foreground, đợi xong, đọc kết quả rồi mới làm tiếp**. Không chạy nền rồi bỏ đó.
- Không dùng lệnh không tự thoát (`idf.py monitor`, `flutter run`, `adb logcat` không giới hạn). Dùng `tools/serial_log.py --seconds N`, `adb logcat -d`, hoặc lệnh có timeout.
- Khi nạp firmware / cài APK: in rõ từng bước đang làm và kết quả (người dùng muốn thấy tiến trình nạp).
- Mọi file tạo trong thư mục dự án này. Không xóa file ngoài dự án.
- Đổi giao thức VPH → phải sửa `docs/PROTOCOL.md` trước, ghi lý do §12, giữ tương thích.

## Lệnh hay dùng (Windows)
```powershell
cd app; flutter analyze; flutter test; flutter build apk --debug
adb install -r app/build/app/outputs/flutter-apk/app-debug.apk
powershell -ExecutionPolicy Bypass -File tools/idf.ps1 -Dir firmware/examples/vph_demo build
powershell -ExecutionPolicy Bypass -File tools/find_port.ps1
powershell -ExecutionPolicy Bypass -File tools/idf.ps1 -Dir firmware/examples/vph_demo -p COM5 flash
tools/.venv/Scripts/python tools/serial_log.py --port COM5 --seconds 20 --reset
```

## Quy ước code
- App: `ChangeNotifier`, không thêm thư viện quản lý trạng thái. UI **không bao giờ** `if (model == ...)` — mọi khác biệt nằm trong transport/adapter.
- Firmware `vph_ble`: C, mỗi hàm trả `esp_err_t` hoặc mã lỗi rõ ràng, không biến toàn cục của project, không `vTaskDelay` để chờ phản hồi.
