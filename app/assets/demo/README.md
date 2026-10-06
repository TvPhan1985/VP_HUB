# File demo của VP Hub

File demo là một **thiết bị giả** để xem giao diện mà không cần phần cứng. Dùng để:
- kiểm tra bộ vẽ giao diện của app (2 file có sẵn trong thư mục này);
- **thử schema của thiết bị mới trước khi nạp firmware**: chép file `.json` vào điện thoại, mở VP Hub → menu **Thiết bị mẫu → Mở file JSON**. Không cần build lại app.

## Định dạng

Một object JSON có 3 khóa:

```json
{
  "info":    { ...INFO như PROTOCOL §4... },
  "screens": [ { ...SCHEMA màn 0, PROTOCOL §5... }, { ...màn 1... } ],
  "values":  { "id": giá_trị, ... }
}
```

| Khóa | Bắt buộc | Ghi chú |
|---|---|---|
| `info` | không | Thiếu thì app tự điền `model:"demo"`, `name:"DEMO"`. `n` luôn được tính lại theo số màn hình. Nên có `hdr` để xem thanh đầu trang |
| `screens` | **có** | Mảng schema, đúng định dạng thiết bị gửi qua characteristic SCHEMA (nhận cả khóa ngắn và khóa dài). Không bị giới hạn 480 byte vì không đi qua BLE |
| `values` | không | Giá trị ban đầu của **tất cả** màn hình gộp chung (kể cả id sinh từ `rep`, ví dụ `s1_en`). Trường nào thiếu thì app hiện `--` |

## Cách thiết bị giả chạy

- Mỗi giây phát VALUES của màn đang chọn + các trường `hdr` (giống thiết bị thật).
- Trường `num` **chỉ đọc** có phần thập phân (`dp` ≥ 1, hoặc không có `dp`) tự đổi ngẫu nhiên nhẹ, kẹp trong `min`/`max` nếu có.
- Mọi lệnh ghi (đơn, lô, nút lệnh) đều trả `ok` và cập nhật giá trị. Thiết bị giả **không kiểm tra hợp lệ** — việc đó là của firmware thật.

## Lấy file demo từ firmware

Trong firmware dùng `vph_ble`, in chuỗi INFO và schema từng màn ra log (xem `firmware/examples/vph_demo`), ghép lại theo định dạng trên, thêm `values` mẫu.
