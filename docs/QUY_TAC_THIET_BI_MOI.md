# QUY TẮC CHO DỰ ÁN THIẾT BỊ MỚI — để app VP Hub dùng được ngay, không làm app mới

Áp dụng cho **mọi** dự án ESP32 (ESP-IDF) có điều khiển/cài đặt qua điện thoại từ nay về sau.

## 10 quy tắc

1. **Không làm app Android riêng.** Thiết bị nói giao thức **VPH v1** (`D:\2026\vp_hub\docs\PROTOCOL.md`) là xong phần app.
2. **Dùng component `vph_ble`**, không tự viết GATT/NimBLE. Thêm vào `firmware/main/idf_component.yml`:
   ```yaml
   dependencies:
     vph_ble:
       path: ../../../vp_hub/firmware/components/vph_ble   # dự án nằm trong D:\2026\
   ```
   Dự án ở chỗ khác thì copy nguyên thư mục `vph_ble` vào `components/` và giữ file `VERSION`.
3. **Bắt đầu từ mẫu** `vp_hub/firmware/examples/vph_demo` (cách khai báo màn hình, điền VALUES, xử lý ghi).
4. **Chọn `model` một lần, không đổi**: chữ thường, không dấu, không cách (`growhub`, `lo220v`, `tampon4truc`…). Tên quảng bá mặc định `<TÊN>-<4 hex MAC>`.
5. **Thiết kế màn hình bằng schema**:
   - Màn đầu tiên là "Tổng quan", `save:"live"`, số đo chính có `w:"big"` / `w:"trend"`.
   - Cài đặt có ràng buộc nhau (ngưỡng bật/tắt, giờ bật/tắt…) → màn `save:"batch"`.
   - Nhóm lặp (khung giờ, bước chương trình, kênh) → `rep`, không liệt kê từng ô.
   - Báo động → một trường `flags` có nhãn từng bit, đưa vào `hdr`.
   - Nút nguy hiểm (đốt lò, xóa lỗi, reboot, chạy motor) → có `c` xác nhận.
   - Chỉ dùng các kiểu ở PROTOCOL §5.2. **Cần kiểu mới → sửa PROTOCOL + app trước**, không tự chế kiểu ở firmware.
   - **Giao diện v1.1** (PROTOCOL §5.4, §5.6): số đo chính dùng `tile` + `ic`; công tắc tải chính dùng `hero,btns`; chế độ dùng `seg`; báo động dùng `alarm`; mỗi màn có `ic`; màn cài đặt ít dùng và màn thông tin thiết bị đặt `nav:"menu"` (`vph_nav_menu`) để nằm trong menu hệ thống [≡], chỉ màn dùng hằng ngày làm tab. Mẫu: `firmware/examples/vph_demo/main/main.c`.
6. **Giữ đúng kích thước**: schema mỗi màn ≤ 1920 byte (`vph_ble` tự cắt trang 480 byte), VALUES (kể cả `hdr`) ≤ 240 byte. Có unit test kiểm tra. VALUES quá thì tách màn hoặc rút id.
7. **Firmware tự kiểm tra hợp lệ** mọi lệnh ghi, sai thì từ chối, giữ cấu hình cũ, trả `err` tiếng Việt ngắn.
8. **Cần giờ** (lịch, RTC) → `caps:["time"]`, xử lý `_time`. Đổi tên qua `_name`, khởi động lại qua `_reboot`.
9. **Không làm việc nặng trong callback GATT** — `vph_ble` đã đưa lệnh vào queue, xử lý trong `vph_poll()` ở task chính.
10. **Thử schema trước khi nạp**: xuất JSON demo (INFO + schema + VALUES mẫu, định dạng như `vp_hub/app/assets/demo/`), chép vào điện thoại, mở bằng VP Hub → menu **Thiết bị mẫu → Mở file JSON** để xem giao diện. Không cần build lại app.

## Khi nào thì PHẢI sửa app VP Hub?
Chỉ khi cần **kiểu dữ liệu hoặc gợi ý hiển thị mới** dùng chung được cho nhiều thiết bị (ví dụ `w:"profile"` cho biểu đồ chương trình nhiệt, kiểu `color`). Khi đó: sửa `PROTOCOL.md` (ghi §12), thêm vào app, **giữ tương thích** với thiết bị cũ. Không bao giờ thêm màn hình riêng cho một model.

## Đoạn chép sẵn vào `CLAUDE.md` của dự án mới

```markdown
## App điện thoại
- KHÔNG làm app Android riêng. Thiết bị dùng giao thức BLE chung **VPH v1**: đọc `D:\2026\vp_hub\docs\PROTOCOL.md` và `D:\2026\vp_hub\docs\QUY_TAC_THIET_BI_MOI.md` trước khi làm phần BLE.
- Dùng component `vph_ble` (D:\2026\vp_hub\firmware\components\vph_ble), bắt đầu từ mẫu `vp_hub/firmware/examples/vph_demo`.
- model = `<điền>`; tên quảng bá mặc định `<TÊN>-XXXX`.
- Schema mỗi màn ≤ 1920 byte, mỗi VALUES ≤ 240 byte, có test kiểm tra.
- Kiểm tra bằng app VP Hub trên điện thoại (cài `vp_hub/release/VPHub_*.apk`), không viết app mới.
```

## Chữ hiển thị (từ app 1.2)

App VP Hub hiển thị **tiếng Anh** (mặc định) hoặc tiếng Việt do người dùng chọn. Nhãn (`l`), nhóm (`g`), chú thích (`d`), câu hỏi xác nhận (`c`), nhãn `opt` và chuỗi `err` mà firmware gửi lên nên viết tiếng Anh cho đồng bộ (vd `Temperature`, `Setpoint`, `Alarm thresholds`). App không dịch chữ của thiết bị. Tên màn hình viết kiểu thường (`Overview`); app tự đổi thành chữ in hoa trên thanh tab.
