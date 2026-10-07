# SPEC — App Android VP Hub

Một app Android duy nhất để **quét, đọc, điều khiển** mọi thiết bị ESP32 của Phận qua BLE.
- Thiết bị mới làm theo `docs/PROTOCOL.md` (VPH v1) → app dùng được ngay, **không sửa app**.
- 2 thiết bị cũ (relay C3, lò nung MAX31856) dùng được ngay qua adapter (`docs/LEGACY.md`).

---

## 1. Công nghệ (theo 2 app cũ để tái dùng kinh nghiệm)

| Mục | Chọn |
|---|---|
| Framework | Flutter stable (máy đã có 3.47.5 ở `D:\flutter`) |
| BLE | `flutter_blue_plus` 2.x, `connect(license: License.nonprofit)` (dùng cá nhân) |
| Biểu đồ | `fl_chart` |
| Lưu cục bộ | `shared_preferences` (thiết bị đã biết, cache schema) |
| Quyền | `permission_handler` |
| Quản lý trạng thái | `ChangeNotifier` (giống 2 app cũ), không thêm thư viện |
| Package | `vn.phan.vphub`, tên hiển thị **VP Hub** |
| Android tối thiểu | API 23 (Android 6) |
| Ngôn ngữ giao diện | **Tiếng Việt** (chữ trong code gom vào `lib/l10n/strings_vi.dart`) |

Quyền Android: `BLUETOOTH_SCAN` (`neverForLocation`), `BLUETOOTH_CONNECT`; Android ≤ 11: `BLUETOOTH`, `BLUETOOTH_ADMIN`, `ACCESS_FINE_LOCATION` (`maxSdkVersion 30`). Lấy theo `AndroidManifest.xml` của app lò nung.

---

## 2. Kiến trúc

```
lib/
  main.dart, app.dart
  l10n/strings_vi.dart
  core/
    model/        vph_info.dart, vph_schema.dart (Screen, Field, Repeat, Cond), vph_value.dart
    transport/
      transport.dart          # interface chung DeviceTransport
      vph_transport.dart      # giao thức VPH v1 thật
      legacy_c3relay.dart     # adapter L1
      legacy_kiln.dart        # adapter L2
      transport_registry.dart # UUID dịch vụ → transport
    device_session.dart       # ChangeNotifier: info, screens, values, lịch sử trend, gửi lệnh, tự kết nối lại
    cond.dart                 # đánh giá if/en
    schema_cache.dart
    known_devices.dart        # thiết bị đã kết nối (id, tên, model, lần cuối)
  ui/
    screens/ scan_screen.dart, device_screen.dart, about_screen.dart, demo_screen.dart
    render/  field_widget.dart (switch theo kiểu), num_field.dart, enum_field.dart,
             time_field.dart, date_field.dart, days_field.dart, flags_field.dart,
             act_button.dart, text_field.dart, trend_chart.dart, header_bar.dart, batch_bar.dart
assets/legacy/c3relay_v1.json
assets/demo/*.json            # thiết bị giả để chạy thử không cần phần cứng
test/
```

**Interface trung tâm** (mọi giao thức, mới hay cũ, đều đi qua đây):

```dart
abstract class DeviceTransport {
  Future<VphInfo> open(BluetoothDevice d);          // kết nối, MTU, tìm char, trả INFO
  Future<List<VphScreen>> loadScreens();            // đọc/cache schema
  Stream<Map<String, dynamic>> get values;          // VALUES đã gộp
  Future<void> select(int screen);
  Future<VphResult> write(String id, dynamic v);    // live
  Future<VphResult> writeBatch(Map<String, dynamic> set);
  Future<void> close();
}
```
Thêm giao thức cũ khác trong tương lai = thêm 1 class transport. **UI không bao giờ biết đang nói chuyện với transport nào.**

---

## 3. Màn hình Quét

- Quét 10 s, lọc theo UUID dịch vụ: VPH + 2 UUID cũ.
- Danh sách: biểu tượng (`icon` hoặc theo loại adapter), tên, RSSI, nhãn nhỏ "VPH" / "Đời cũ".
- Trên cùng: **Thiết bị đã dùng** (nhớ tối đa 20), bấm là kết nối; có nút xóa khỏi danh sách.
- Tùy chọn trong menu: "Tự kết nối thiết bị gần nhất khi mở app" (mặc định bật).
- Bluetooth tắt / thiếu quyền → hướng dẫn bằng tiếng Việt và nút mở cài đặt.

## 4. Màn hình Thiết bị (vẽ hoàn toàn từ schema)

- **AppBar**: tên thiết bị, dòng phụ trạng thái kết nối ("Đã kết nối" xanh / "Đang kết nối lại…" vàng / "Mất kết nối" đỏ), menu (Thông tin thiết bị, Ngắt kết nối, Đọc lại schema).
- **Điều hướng** (v1.1): `TabBar` **ở trên** (dưới tên thiết bị), mỗi tab có icon + chữ; icon lấy từ `ic` của màn (không có thì theo vị trí: dashboard / schedule / tune / info / settings). Từ 4 màn trở lên thì thanh tab cuộn ngang. Người dùng yêu cầu để ở trên (2026-10-07), không dùng `NavigationBar` dưới đáy như bản nháp PLAN_GIAO_DIEN §4.2.
- **Thanh đầu trang** (`hdr`): các trường `hdr` hiện gọn trên mọi tab (số, đèn, cờ báo động đỏ).
- **Tab** = mỗi màn hình trong schema (`l`). Đổi tab → `select(i)`.
- Nội dung tab: trường theo thứ tự; `g` gom thành thẻ; `rep` mỗi lần lặp một thẻ; `if` ẩn/hiện; `en` cho/không cho sửa.
- Gợi ý hiển thị v1.1 (PROTOCOL §5.4): `tile` (thẻ số đo, 2 cột), `mini` (ô nhỏ gom một thẻ), `hero` (thẻ trạng thái lớn), `btns` (2 nút BẬT/TẮT), `seg` (nút chọn cả chiều ngang, có icon), `alarm` (thẻ báo động), `note` (dòng cảnh báo), `dur` (giây → "2 giờ 5 phút"); khóa `ic`, `d`, `sub`. Giữ đúng thứ tự schema, chỉ gom trường liền nhau cùng kiểu.
- Màu, bo góc, cỡ chữ gom ở `lib/ui/theme.dart`; bảng tên icon ở `lib/ui/render/icons.dart`.
- Trường `w:"big"` → thẻ số lớn đầu tab. `w:"trend"` → biểu đồ đường dưới thẻ (lịch sử RAM 1 giờ, lấy mẫu mỗi notify).
- **Màn `live`**: sửa xong gửi ngay; hiện vòng chờ nhỏ trên ô cho đến RESULT; lỗi → SnackBar đỏ hiện `err`, trả ô về giá trị thiết bị.
- **Màn `batch`**: ô sửa được giữ giá trị tạm (viền màu khác), thanh dưới cùng hiện "Có N thay đổi — [Hủy] [Lưu]". Lưu → `writeBatch` → chờ RESULT → báo thành công/lỗi. Đang có thay đổi chưa lưu mà rời tab → hỏi lại.
- Khi đang sửa một ô thì **không** ghi đè ô đó bằng VALUES notify.
- `act` và các trường có `c` → hộp thoại xác nhận trước khi gửi.
- Mất kết nối: banner "Mất kết nối, đang thử lại…", tự kết nối lại với độ trễ 1, 2, 5, 10 s rồi dừng và cho nút "Thử lại" (giống app lò nung). Giao diện giữ giá trị cũ, làm mờ.
- Kiểu/gợi ý chưa biết → hiện chữ chỉ đọc `id: giá trị`. **Không bao giờ crash vì schema lạ** (bọc parse trong try, lỗi schema hiện thành thẻ cảnh báo).

## 5. Thông tin thiết bị
Bảng INFO (model, fw, hw, pv, giao thức thật: VPH / adapter nào), MTU đã thương lượng, kích thước gói VALUES lớn nhất đã nhận (để dò vi phạm §8 của PROTOCOL).

## 6. Chế độ thử (Demo)
Menu ở màn Quét: "Thiết bị mẫu" → nạp `assets/demo/*.json` (INFO + schema + VALUES giả, VALUES đổi ngẫu nhiên nhẹ mỗi giây, ghi luôn `ok`). Thêm mục **Mở file JSON**: chọn file demo từ bộ nhớ điện thoại (gói `file_picker`), cùng định dạng với `assets/demo/`. Dùng để kiểm tra bộ vẽ giao diện mà **không cần phần cứng**, và để thử schema của thiết bị mới **mà không build lại app**. Định dạng file demo ghi rõ trong `assets/demo/README.md`.

## 7. Hiệu năng / độ bền
- Thao tác BLE tuần tự (một hàng đợi), không gọi chồng.
- Đọc schema có cache `model+sch`; thiết bị cũ (không có `sch`) thì cache theo `model+fw` và có nút "Đọc lại schema".
- Notify VALUES hỏng JSON (bị cắt) → bỏ qua gói, đếm số gói hỏng, hiện cảnh báo ở màn Thông tin.

## 8. Kiểm thử bắt buộc
- Unit test parser: schema VPH ngắn, schema khóa dài của lò nung (lấy chuỗi thật từ `main/ble_ui.c`), `rep` cả hai kiểu, kiểu lạ.
- Unit test `cond`: `==`, `!=`, `&&`, thiếu trường.
- Unit test adapter C3: STATUS + CONFIG mẫu (SPEC §6/§7 của c3) → VALUES phẳng; batch → JSON CONFIG đúng; slots luôn đủ 5.
- Unit test adapter lò nung: ghi `{"id","v"}` → `{"id","value"}`; vá schema.
- Widget test: vẽ được toàn bộ demo không lỗi.
- `flutter analyze` sạch.

## 9. Ngoài phạm vi bản đầu
iOS; kết nối nhiều thiết bị cùng lúc; OTA firmware; WiFi/MQTT (để dành cho Grow Hub / HiveMQ sau này — interface `DeviceTransport` đã chừa chỗ).

## 10. Liên quan
- `docs/PROTOCOL.md` — giao thức VPH v1
- `docs/LEGACY.md` — 2 adapter
- `docs/QUY_TAC_THIET_BI_MOI.md` — quy tắc cho dự án sau

## 11. Quyết định khi triển khai
_(Claude Code ghi thêm vào đây)_

1. **Lớp `GattLink`** (`core/transport/gatt_link.dart`) che thư viện BLE: `connect / read / write / subscribe / lost / disconnect`. Transport nhận `GattLink` trong constructor nên test được bằng characteristic giả lập (`test/fake_link.dart`). Vì vậy `DeviceTransport.open()` **không nhận `BluetoothDevice`** như bản nháp ở §2; việc kết nối do `connectTransport()` trong `transport_registry.dart` làm, sau đó chọn transport theo **dịch vụ tìm thấy trên thiết bị** (không chỉ theo gói quảng bá — nên kết nối lại thiết bị đã nhớ không cần quét).
2. **`DeviceTransport` có thêm `start()`** (đăng ký notify, gửi `_time`), `lost` (stream báo mất kết nối), `stats`, `protoLabel`, `legacy`. Thứ tự: `open()` → `loadScreens()` → `start()` → `select()`, đúng PROTOCOL §9.
3. **Tự kết nối lại**: mỗi lần thử tạo transport mới qua hàm `connector`; giá trị cũ, tab đang mở, thay đổi chưa lưu đều giữ nguyên.
4. **Ô số và ô chữ sửa bằng hộp thoại** (bấm vào giá trị), không sửa tại chỗ. Nhờ vậy VALUES notify không bao giờ ghi đè ô đang gõ. Ô số có thêm nút − / + khi schema có `st`.
5. **`c` với công tắc (`bool`)**: chỉ hỏi xác nhận khi **bật**; tắt thì làm ngay (tắt đốt lò không nên bị chặn bởi hộp thoại). Với `act` và kiểu khác: luôn hỏi.
6. **`if`/`en` trên màn batch** tính trên giá trị thiết bị **gộp với giá trị đang sửa**, nên đổi `src` là các ô ngưỡng hiện/ẩn ngay, chưa cần Lưu.
7. **`if`/`en` trong mẫu `rep`**: id nào trùng id một trường trong mẫu thì được hiểu là trường **cùng lần lặp** (`"en":"en==true"` trong mẫu → `s2_en==true` ở thẻ 2). Id khác giữ nguyên.
8. **Nhiều gợi ý `w`** cách nhau dấu phẩy (`"big,trend"`), và gợi ý mới `warn` (đèn `led` màu đỏ khi bật). Đã ghi vào PROTOCOL §5.4 và §12.
9. **Số chữ số thập phân**: dùng `dp`; không có `dp` thì suy từ `st` (0.5 → 1 chữ số); không có cả hai thì số nguyên in nguyên, số lẻ in tối đa 2 chữ số.
10. **Thanh đầu trang**: `flags` chỉ hiện khi ≠ 0 (ô đỏ, ghi cảnh báo đầu tiên `+N`); đèn có `warn` chỉ hiện khi đang bật. Trường `hdr` không có trong schema nào thì đoán kiểu theo giá trị.
11. **Lệnh ghi quá 240 byte** (màn batch đổi quá nhiều ô một lần) bị chặn ở app với thông báo "Lệnh quá dài… Hãy lưu bớt thay đổi mỗi lần". App **không tự tách** lệnh `set` vì sẽ mất tính "kiểm tra cả lô rồi mới lưu". Lưu ý cho Phần D: 5 khung giờ đổi hết một lần ≈ 300 byte — khi chuyển relay C3 sang VPH cần tách khung giờ ra 2 màn hoặc nâng giới hạn WRITE trong PROTOCOL.
12. **Demo**: `DemoTransport` phát VALUES của màn đang chọn + `hdr` mỗi giây như thiết bị thật; chỉ làm nhiễu trường `num` chỉ đọc có phần thập phân.
13. **Quyền**: app xin `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT` bằng `permission_handler`; trên Android ≤ 11 thư viện `flutter_blue_plus` tự xin quyền vị trí khi quét. `permission_handler` ghim 11.x (bản 13 không biên dịch được với AGP/Kotlin của máy, xem pubspec app lò nung).
14. **`kotlin.incremental=false`** trong `android/gradle.properties`: pub cache ở ổ C, dự án ở ổ D làm hỏng cache Kotlin tăng dần.

### Adapter lò nung (`kiln_v0`)
15. **Nhãn tiếng Việt**: firmware cũ gửi nhãn tiếng Anh; adapter đổi tiêu đề tab và nhãn các trường đã biết sang tiếng Việt (bảng trong `legacy_kiln.dart`), đơn vị `min` → `phút`. Chuỗi trạng thái do firmware sinh (`program_info`, `autotune_info`, `safety_reason`) vẫn là tiếng Anh.
16. Vá thêm `sensor_ok` và `safety_latched` (đèn chỉ đọc) vào màn Vận hành để thanh đầu trang có mô tả trường.
17. **Xác nhận ghi**: sau khi ghi, adapter đọc lại VALUES (250 ms, rồi mỗi 500 ms, tối đa 2 s). Số so với sai số `st/2` (tối thiểu 0,06). Không xác nhận với nút lệnh và `autotune_apply` (firmware luôn trả `false`).
18. **Nút lệnh** (`safety_clear`) gửi `"value":true` vì firmware cũ chỉ nhận bool. Lệnh ghi tối đa 63 byte (bộ đệm firmware 64 byte).
19. Khi kết nối, adapter đọc VALUES của **mọi** màn một lần, để màn "Các bước" biết ngay `program_step_count` (nằm ở màn "Chương trình").
20. Cache schema theo khóa cố định `kiln31856/?` (không có `fw`); đổi firmware lò thì bấm **Đọc lại schema**.
21. **Mất so với app cũ**: biểu đồ "profile chương trình" (ProgramProfileChart). Gợi ý tương lai: thêm `w:"profile"` vào PROTOCOL cho khối `rep`, **không** làm màn hình riêng.

### Adapter relay C3 (`c3relay_v1`)
22. `mb_baud` và `mb_fc` là **`enum` giá trị số** (danh sách thả) thay vì `num` như bảng LEGACY, để giống app cũ (chọn từ danh sách, không gõ sai).
23. `sen_act`, `on_at`, `off_at` cũng có `if:"src!=schedule"` (cùng nhóm "Ngưỡng cảm biến" với `sen_type`). `muted` chỉ hiện khi đang có báo động.
24. Kích thước schema lưu sẵn (test in ra, để Phần D biết trước): Tổng quan 1157 byte (3 trang), Lịch & tự động 1073 (3 trang), Nâng cao 1609 (4 trang), Thiết bị 258 (1 trang) — đều dưới 1920.

**Bảng đối chiếu với app cũ `c3_relay_ctrl/app`**

| Chức năng app cũ | VP Hub |
|---|---|
| Quét lọc UUID, nhớ thiết bị gần nhất, tự kết nối lại, MTU 512 | Có (màn Quét, nhớ 20 thiết bị) |
| Gửi giờ ngay khi kết nối | Có (`_time` → CMD `time`) |
| Tổng quan: nhiệt độ, độ ẩm, EC, độ mặn, TDS, giờ thiết bị | Có; thêm biểu đồ nhiệt độ |
| Đổi chế độ Tay/Tự động | `mode` (nút chọn) |
| Bật/tắt relay, khóa khi Tự động | `out`, `en:"mode==manual"` |
| Báo động + nút tắt còi | `alarm` (flags), `silence`, `muted` |
| Khoảng ngày + công tắc "Không giới hạn" | `date_from/date_to`, `nul:1` |
| Nguồn Lịch / Cảm biến / Kết hợp | `src` |
| 5 khung giờ, chọn thứ T2..CN | `rep` 5 thẻ "Khung" (luôn hiện đủ 5; app cũ cho thêm/xóa khung — ở đây khung không dùng thì để tắt) |
| Ngưỡng có vùng trễ, kiểm tra trước khi gửi | `sen_*`, `on_at`, `off_at`; adapter kiểm tra như `app_config.dart` |
| Đổi tên thiết bị | `_name` (tab Thiết bị) |
| Tham số Modbus, ngưỡng báo động | Tab Nâng cao (batch) |
| Khởi động lại (có hỏi lại) | `_reboot` có `c` |
| Lưu: chờ RESULT 3 s, báo tiếng Việt | Có |
| Ghi chú "khung qua đêm" trên thẻ khung giờ | **Không có** (chỉ là chữ gợi ý; firmware vẫn xử lý qua đêm) |

### Giao diện v1.1 (PLAN_GIAO_DIEN)
25. **Thanh đầu trang bỏ bớt trường trùng**: trường `hdr` nào đang hiện ngay trong tab đang mở thì không hiện lại trên thanh đầu trang (tab Tổng quan của relay đã có thẻ nhiệt độ, độ ẩm, Relay… nên thanh này tự ẩn; sang tab khác nó hiện đủ).
26. **Mặc định khi schema không có gợi ý**: ở màn đầu tiên, nếu không trường nào có `w`, tối đa 2 trường `num` chỉ đọc đầu tiên tự hiện dạng `tile`. Chỉ áp cho màn đầu.
27. **`big` vẫn đưa lên đầu tab** như bản 1.0 (lò nung đang dùng); các gợi ý mới thì giữ đúng vị trí trong schema.
28. **`tile` kèm `trend`**: biểu đồ đóng sẵn, chạm vào thẻ thì mở ngay dưới hàng thẻ, chạm lần nữa thì đóng (thẻ có icon biểu đồ nhỏ ở góc).
29. **`mini`**: tối đa 4 ô một hàng; nhiều hơn thì xuống hàng, mỗi hàng 3 ô.
30. **`hero` không có `btns`** và không chỉ đọc → công tắc nằm bên phải thẻ. Dòng `d` trong thẻ `hero` chỉ hiện khi trường đang bị khóa bởi `en`. Dòng phụ `sub` hiện "nhãn: giá trị" của trường được trỏ tới (số có đơn vị, `enum` hiện nhãn lựa chọn).
31. **`alarm` cho `bool`** (ngoài `flags`): true → thẻ đỏ, tiêu đề là nhãn trường; trường `text` cùng nhóm thành gạch đầu dòng. Dùng cho "khóa an toàn" của lò.
32. **Thông báo kết quả**: thành công → nền xanh 2 s ("Đã lưu", "Đã bật Relay", "Đã tắt Relay", "Chế độ: Tự động", "Đã gửi: …"); lỗi → nền đỏ 5 s, hiện nguyên `err`. Ô số, giờ, ngày ghi xong không báo (bấm ± liên tục sẽ bị nhảy thông báo).
33. **Màn Quét**: mỗi thiết bị một thẻ, cột sóng 4 vạch thay số dBm (≥ −60: 4 vạch, ≥ −70: 3, ≥ −80: 2, còn lại 1). Thiết bị đã dùng mà đang thấy quanh đây có chấm xanh + cột sóng, và không lặp lại ở mục "Thiết bị gần đây".
34. **WRITE 500 byte**: `VphTransport.maxWrite = 500`, lớp `FbpGattLink` tự dùng long write khi gói dài hơn MTU−3. Giải quyết ghi chú ở mục 11. Adapter relay C3 và lò nung giữ giới hạn riêng của firmware cũ.
35. **Lò nung**: `pv` thêm `ic:"fire"`; `running` thành `hero` với chữ "Dừng / Đang đốt", dòng phụ là nhiệt độ đặt; `safety_latched` thành thẻ `alarm`, gom `safety_reason` và nút `safety_clear`.
36. **Relay C3**: màn Tổng quan theo ví dụ PROTOCOL §11 (v1.1); giữ thêm đèn "Đã tắt còi" trong thẻ báo động khi còi đã tắt (app cũ hiện nút mờ "Đã tắt còi").
37. **Màn trong menu ⋮** (`nav:"menu"`, PROTOCOL §5): màn có khóa này không làm tab; tên và icon của nó hiện ở đầu menu ⋮ của màn Thiết bị, bấm thì mở thành trang riêng (có nút quay lại, thanh Lưu của màn batch, hỏi lại khi còn thay đổi chưa lưu). Vào trang thì app SELECT màn đó, thoát ra thì SELECT lại tab đang mở. Nếu **mọi** màn đều là `menu` thì coi tất cả là tab (không để màn Thiết bị trống). Relay C3: "Nâng cao" và "Thiết bị" nằm trong menu, còn 2 tab "Tổng quan", "Lịch & tự động".
