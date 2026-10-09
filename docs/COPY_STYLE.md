# COPY_STYLE — quy tắc viết chữ hiển thị

Bản 1.4 (2026-10-09). Áp dụng cho **mọi chữ người dùng nhìn thấy**:

- chữ của app VP Hub (`app/lib/l10n/app_en.arb`, bản dịch `app_vi.arb`);
- chữ **firmware gửi lên** qua schema và RESULT: tên màn, nhãn `l`, nhóm `g`, chú thích `d`, câu hỏi `c`, nhãn `opt`, chuỗi lỗi `err`;
- schema lưu sẵn trong app (relay C3, lò nung, thiết bị mẫu) và các file mẫu `docs/mau/`.

Ngôn ngữ chính là **tiếng Anh**. Bản tiếng Việt dịch theo đúng nghĩa và cùng quy tắc.

---

## 1. Chín quy tắc

1. **Sentence case ở mọi nơi** (nhãn, nút, tiêu đề, mục menu): chỉ viết hoa chữ đầu và tên riêng.
   `Device list`, `Open JSON file`, `Auto-connect to last device`, `Alarm settings`.
   Chỉ viết hoa toàn bộ ở **thanh tab** (app tự đổi, firmware vẫn gửi `Overview`) và chữ trạng thái `ON` / `OFF`.
2. **Không thuật ngữ nội bộ ở chế độ Standard.** Cấm: `schema`, `VPH`, `transport`, `MTU`, `packet`, `legacy`, `adapter`, `GATT`, `UUID`, `bit`.
   Dùng từ người vận hành hiểu: `interface` thay `schema`, `device` thay `peripheral`, `data` thay `packet`. Các từ trên chỉ được xuất hiện ở phần dành cho Technician.
3. **Nút ghi đúng hành động:** `Save`, `Discard`, `Restart`, `Turn on`, `Remove`, `Disconnect`. Không dùng `OK` cho hành động có hậu quả.
   Hộp xác nhận: **tiêu đề là câu hỏi**, nút xác nhận **lặp lại động từ** (`Restart device?` → `Restart device`). Không biết động từ thì dùng `Confirm`. Nút hủy luôn là `Cancel`.
4. **Câu lỗi = chuyện gì xảy ra + làm gì tiếp.**
   `Can't reach the device. Move closer and make sure it's powered on.`
   `Set the on threshold below the off threshold.` (lỗi kiểm tra giá trị: nói thẳng việc cần làm)
   Không đổ lỗi cho người dùng, không mã lỗi, không tên hàm.
5. **Trạng thái trống luôn có hướng dẫn và một nút hành động.**
   `No devices nearby` / `Turn on your device and keep the phone within a few meters.` + `Scan again`.
6. **Số và thời gian:** dấu chấm thập phân; giờ 24h `HH:mm`; ngày `dd MMM yyyy` (theo ngôn ngữ đang chọn); thời lượng `2 h 05 min`, `5 min 12 s`, `3 d 04 h`.
7. **Đơn vị cách số một dấu cách:** `25.4 °C`, `60 %`, `4.2 bar`. Trừ chỗ chật (thẻ `tile`) theo quy chuẩn giao diện hiện có.
8. **Không dấu chấm than, không emoji, không "Please" thừa.** Dùng dấu ba chấm `…` (một ký tự) cho việc đang diễn ra: `Connecting…`.
9. **Nhãn trường ≤ 24 ký tự.** Chú thích `d` là **một câu hướng dẫn, có dấu chấm cuối**. Câu hỏi `c` kết thúc bằng dấu hỏi.

---

## 2. Bảng từ dùng thống nhất

| Việc | Tiếng Anh | Tiếng Việt |
|---|---|---|
| Lưu thay đổi | `Save` | `Lưu` |
| Bỏ thay đổi | `Discard` | `Bỏ thay đổi` |
| Hủy hộp thoại | `Cancel` | `Hủy` |
| Thử lại | `Try again` | `Thử lại` |
| Xóa khỏi danh sách | `Remove` | `Xóa` |
| Hoàn tác | `Undo` | `Hoàn tác` |
| Khởi động lại | `Restart` | `Khởi động lại` |
| Bật / tắt (hành động) | `Turn on` / `Turn off` | `Bật` / `Tắt` |
| Bật / tắt (trạng thái) | `ON` / `OFF` | `BẬT` / `TẮT` |
| Chế độ tay / tự động | `Manual` / `Auto` | `Tay` / `Tự động` |
| Báo động | `Alarm` | `Báo động` |
| Tắt còi | `Silence buzzer` | `Tắt còi` |
| Giá trị đặt | `Setpoint` | `Giá trị đặt` |
| Ngưỡng | `Threshold` | `Ngưỡng` |
| Giao diện của thiết bị | `interface` | `giao diện` |
| Người kỹ thuật | `Technician` | `Kỹ thuật viên` |

Đơn vị viết chuẩn: `°C`, `%`, `bar`, `L/min`, `min`, `s`, `h`, `V`, `A`, `kW`.

---

## 3. Mẫu câu

| Tình huống | Nên viết | Không viết |
|---|---|---|
| Nhãn số đo | `Temperature` | `Temp Value`, `TEMPERATURE` |
| Nhãn công tắc | `Pump`, `Enable alarm` | `Pump On/Off Switch` |
| Nhãn nút lệnh | `Silence buzzer`, `Clear fault` | `OK`, `Execute` |
| Tên màn | `Schedule & auto`, `Alarm settings` | `Settings` (trùng mục của app), `ADVANCED` |
| Chú thích `d` | `Manual switching is available in Manual mode only.` | `manual only!!` |
| Câu hỏi `c` | `Start the burner?` | `Are you sure you want to start the burner?` |
| Lỗi `err` (≤ 80 byte) | `Set the low threshold below the high threshold.` | `ERR_INVALID_ARG`, `Invalid value` |
| Lỗi kết nối | `The device didn't respond. Try again.` | `Timeout (3000 ms)` |
| Thông báo xong việc | `Saved`, `Pump turned on` | `Operation completed successfully!` |
| Ghi chú cảnh báo (`note`) | `No sensor data` | `Sensor has no data or is disconnected` |

---

## 4. Chế độ Standard và Technician

- Chữ ở Standard viết cho người vận hành: ngắn, không thuật ngữ (quy tắc 2).
- Câu lỗi ở Standard chỉ là câu trong bảng lỗi của app; Technician có thêm nút `Details` hiện lỗi gốc.
- Phần chỉ có ở Technician (Device info mở rộng, Developer tools) được dùng thuật ngữ kỹ thuật, nhưng vẫn theo quy tắc 1, 3, 8.

---

## 5. Ghi chú khi áp dụng

- Tiêu đề nhóm nhỏ trong Drawer, màn Quét và Settings cũng viết sentence case (`My devices`, `This device`, `Developer tools`).
- Nhóm trong Drawer của màn Thiết bị tên là `This device` (không phải `Device`) để không trùng với màn `Device` mà nhiều thiết bị khai.
- Chữ do thiết bị VPH tự gửi được app hiện **nguyên văn**, không dịch. Vì vậy firmware phải tự theo file này.
- Thêm chữ mới vào app: thêm khóa vào `app_en.arb` trước, rồi `app_vi.arb` (test sẽ báo nếu thiếu bản dịch).
