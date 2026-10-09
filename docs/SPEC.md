# SPEC — App Android VP Hub

Một app Android duy nhất để **quét, đọc, điều khiển** mọi thiết bị ESP32 của Phận qua BLE.
- Thiết bị mới làm theo `docs/PROTOCOL.md` (VPH v1) → app dùng được ngay, **không sửa app**.
- 2 thiết bị cũ (relay C3, lò nung MAX31856) dùng được ngay qua adapter (`docs/LEGACY.md`).

---

## 1. Công nghệ (theo 2 app cũ để tái dùng kinh nghiệm)

| Mục | Chọn |
|---|---|
| Framework | Flutter stable (máy đã có 3.47.5 ở `D:\flutter`) |
| BLE | `universal_ble` 2.3.0 (BSD-3-Clause), xem §11.49 và `docs/LICENSES.md` |
| Biểu đồ | `fl_chart` |
| Lưu cục bộ | `shared_preferences` (thiết bị đã biết, cache schema) |
| Quyền | `permission_handler` |
| Quản lý trạng thái | `ChangeNotifier` (giống 2 app cũ), không thêm thư viện |
| Package | `vn.phan.vphub`, tên hiển thị **VP Hub** |
| Android tối thiểu | API 23 (Android 6) |
| Ngôn ngữ giao diện | **Tiếng Anh** (mặc định, không theo ngôn ngữ máy) hoặc **Tiếng Việt**, người dùng chọn trong Settings; Flutter gen-l10n, chữ nằm ở `lib/l10n/app_en.arb` và `app_vi.arb` (§11.56) |

Quyền Android: `BLUETOOTH_SCAN` (`neverForLocation`), `BLUETOOTH_CONNECT`; Android ≤ 11: `BLUETOOTH`, `BLUETOOTH_ADMIN`, `ACCESS_FINE_LOCATION` (`maxSdkVersion 30`). Lấy theo `AndroidManifest.xml` của app lò nung.

---

## 2. Kiến trúc

```
lib/
  main.dart, app.dart
  l10n/strings.dart
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

### Giao diện 1.2 theo "Quy chuẩn thiết kế app Công - Nông nghiệp" (PDF trong docs/, 2026-10-08)

Các mục dưới đây thay cho mô tả cũ ở §3, §4 và mục 25, 37 khi có khác nhau.

38. **Bố cục chung**: Top App Bar cao 56dp, nút menu [≡] góc trái, tên thiết bị + dòng trạng thái kết nối, nút tác vụ góc phải. Ngay dưới là thanh tab cuộn ngang (Scrollable Tabs), chữ **in hoa**, không icon; tab đang chọn có nền xanh mờ và gạch chân. Thanh đầu, thanh tab và menu hệ thống luôn nền xám đậm (`#0F172A` / `#1E293B`) ở cả hai chế độ sáng/tối như hình mẫu của quy chuẩn. Trang con (màn `nav:"menu"`, Device Information, About, Demo Devices) dùng mũi tên quay lại thay cho [≡].
39. **Menu hệ thống (Navigation Drawer)** thay menu ⋮: rộng 82% màn hình, tối đa 320dp; nền phía sau phủ `rgba(0,0,0,0.5)`; chạm vùng mờ hoặc vuốt trái để đóng. Khối trên cùng: avatar (2 chữ đầu của tên thiết bị), tên, `model · Firmware x.y.z`, chấm + chữ trạng thái kết nối. Màn Thiết bị có 3 nhóm: **DEVICE** (Device List, các màn `nav:"menu"` của thiết bị, Device Information, Reload Schema), **APP SETTINGS** (Theme), **SUPPORT** (About, Disconnect chữ đỏ). Màn Quét: **DEVICES** (Device List, Demo Devices), **APP SETTINGS** (Theme, Auto-connect on Launch), **SUPPORT** (About). App không có tài khoản người dùng nên khối hồ sơ hiện thiết bị đang kết nối; mục Ngôn ngữ có từ bản 1.2.1 (mục 45); không có đổi đơn vị đo (đơn vị do thiết bị gửi).
40. **Nút tác vụ góc phải**: màn Thiết bị có chuông thông báo kèm số báo động đang bật; bấm mở danh sách "Active Alarms". Số báo động = số bit đang bật của mọi trường `flags` + số trường `bool` có gợi ý `alarm` (hoặc `warn` mà không phải `hero`) đang bật — tính từ schema, không theo model. Màn Quét: nút Scan / Stop (thay nút nổi dưới đáy); khi chưa thấy thiết bị nào có thêm nút Scan giữa màn.
41. **Bảng màu** (`lib/ui/theme.dart`, đúng mã trong mục 5-6 của quy chuẩn): sáng — nền `#F8F9FA`, thẻ `#FFFFFF`, chữ `#1E293B`, chữ phụ `#64748B`, màu nhấn `#0284C7`, tốt `#15803D`; tối — nền `#0F172A`, thẻ `#1E293B`, chữ `#F1F5F9`, chữ phụ `#94A3B8`, màu nhấn `#38BDF8`, tốt `#22C55E`. Cảnh báo: `#FEF3C7`/`#92400E` (sáng), `#451A03`/`#FDE047` (tối) — dùng cho dòng `note`, băng "đang kết nối lại", thanh thay đổi chưa lưu. Dừng khẩn: `#FEE2E2`/`#991B1B` (sáng), `#450A0A`/`#FCA5A5` (tối) — dùng cho thẻ báo động, lỗi, băng mất kết nối. Không dùng đen thuần / trắng thuần ở chế độ tối. Màu đỏ / vàng / xanh giữ nguyên nghĩa ở cả hai chế độ.
42. **Đổi giao diện**: Theme = System default (mặc định, theo hệ điều hành, đổi ngay không cần mở lại app) / Light / Dark; lưu trong kho của app (khóa `theme`).
43. **Thẻ nội dung** theo hình mẫu: thẻ nền phẳng có viền 1px, bo góc 12. Thẻ `hero`: tên + nhãn trạng thái (chip) ở góc phải, dòng phụ `sub` nằm trong khối nền xám có vạch màu bên trái. Thẻ `big`: khối có vạch màu, nhãn nhỏ ở trên, số 40pt đậm canh trái. Thẻ `tile`: nhãn nhỏ màu chữ phụ, số đậm màu nhấn, canh giữa.
44. **Chữ tiếng Anh**: toàn bộ chữ của app, schema lưu sẵn của relay C3 (`assets/legacy/c3relay_v1.json`), nhãn vá cho lò nung và 2 thiết bị mẫu đổi sang tiếng Anh. Chữ do thiết bị tự gửi (schema của thiết bị VPH, chuỗi `err`) app hiện nguyên văn, không dịch.
45. **Ngôn ngữ** (1.2.1, người dùng yêu cầu 2026-10-08): nhóm APP SETTINGS của menu hệ thống có mục Language: English (mặc định) / Tiếng Việt, lưu trong kho của app (khóa `lang`). Chữ của app đổi ngay trên màn đang mở. Chữ thuộc schema (relay C3, nhãn vá của lò nung, thiết bị mẫu) lấy theo ngôn ngữ **lúc kết nối**: đang kết nối mà đổi ngôn ngữ thì phải kết nối lại mới đổi. Schema lưu sẵn có 2 file: `x.json` (Anh) và `x.vi.json` (Việt), test kiểm tra hai file cùng cấu trúc. Chữ do thiết bị VPH tự gửi vẫn hiện nguyên văn.
46. **Nút OFF của gợi ý `btns`** cùng kiểu và cùng màu với nút ON (nút đặc màu nhấn); nút nào không bấm được thì xám.
47. **Hai bộ giao diện theo lĩnh vực** (1.3, người dùng yêu cầu 2026-10-08; PROTOCOL §4 khóa `dom`): thiết bị khai `dom:"agri"` → màn Thiết bị (và các trang con mở từ nó) dùng bộ **nông nghiệp** theo mẫu Smart Farm của quy chuẩn: thanh đầu `#14532D`, thanh tab `#166534`, tab đang chọn và màu nhấn xanh lá (`#15803D` sáng / `#22C55E` tối). Không có `dom` hoặc `dom:"ind"` → bộ **công nghiệp** (mẫu Factory SCADA) như mục 38. Màn Quét và các màn chung của app luôn dùng bộ công nghiệp. UI chỉ đọc `info.domain`, không xét `model`. Adapter relay C3 (`c3relay_v1`) khai `agri` vì phần cứng này dùng cho nông nghiệp; lò nung giữ `ind`; thiết bị mẫu Demo Relay khai `agri`. Màu cảnh báo (vàng) và dừng khẩn (đỏ) giống nhau ở cả hai bộ.
48. **Bộ quy chuẩn cho dự án mới** (2026-10-08): `docs/QUY_TAC_THIET_BI_MOI.md` viết lại thành quy chuẩn đầy đủ (7 bước, bảng "muốn hiện gì thì khai gì", lỗi hay gặp, bảng nghiệm thu). Hai file mẫu `docs/mau/mau_nong_nghiep.json` và `docs/mau/mau_cong_nghiep.json` mở được bằng Demo Devices → Open JSON File; test kiểm tra hai file vẽ đủ mọi màn và VALUES mỗi màn ≤ 240 byte. `tools/make_kit.py` đóng gói quy chuẩn + PROTOCOL + mẫu + `vph_ble` + `vph_demo` + APK thành `release/VPH_KIT_<bản>.zip`. Firmware mẫu `vph_demo` 1.2.0: nhãn tiếng Anh, khai `.domain`.

### Bản 1.4 "Hoàn thiện" (PLAN_HOAN_THIEN, 2026-10-09)

Các mục dưới đây thay cho mô tả cũ ở §1, §3, §4, §5 và mục 13, 34, 38, 39, 45 khi có khác nhau.

49. **Thư viện BLE `universal_ble` 2.3.0** (BSD-3-Clause, Navideck Labs OÜ; đã đọc file LICENSE trong gói và nhãn license trên pub.dev) thay `flutter_blue_plus` 2.x (license riêng, công ty có lợi nhuận phải mua). Lớp `UbGattLink` (`core/transport/ub_gatt_link.dart`) giữ nguyên interface `GattLink`: kết nối timeout 10 s, `requestMtu(512)` trên Android, gắn nơi nhận trước khi bật notify, ghi có phản hồi, thử lại khi "busy". Việc quét gom vào `DeviceScanner` (`core/transport/ble_scanner.dart`; bộ thật `UbScanner`) để màn Quét test được bằng bộ quét giả; thư viện không có timeout quét nên app tự dừng bằng `Timer`. Quyền: gọi `UniversalBle.requestPermissions()` (Android 12+: Nearby devices; Android 11 trở xuống: vị trí), `permission_handler` chỉ còn dùng để mở cài đặt.
    - **Lệnh dài hơn MTU−3**: đã đọc mã nguồn plugin (`UniversalBlePlugin.kt`, `writeValue`): plugin gọi thẳng `BluetoothGatt.writeCharacteristic` với `WRITE_TYPE_DEFAULT`, **không tự chặn** theo độ dài; với kiểu ghi này Android tự chuyển sang long write (prepared write) khi dữ liệu dài hơn MTU−3, tối đa 512 byte. Vì vậy `VphTransport.maxWrite` giữ **500**. Chưa thử được trên phần cứng — có trong `TEST_ON_HW.md` mục "Cần thử cho 1.4".
    - Rà license mọi gói: `docs/LICENSES.md` (sinh bằng `tools/gen_licenses.py`). Hai gói kéo theo `bluez`, `dbus` là MPL-2.0, chỉ dùng cho Linux, đã có từ bản 1.3; ghi đỏ trong file đó.
50. **Hai chế độ người dùng** (`core/app_settings.dart`, lớp `AppSettings` thay `ThemeController`): `userMode` = `standard` (mặc định) | `technician`, lưu khóa `user_mode`. Bật trong Settings → Technician mode; có thể đặt **PIN 4 số** (khóa `tech_pin`, mặc định không có): có PIN thì hỏi PIN khi bật, tắt thì không hỏi. Khi đang ở Technician, thanh đầu màn Thiết bị có chip `TECH` viền vàng. **Ẩn trong app chỉ để giao diện gọn, không phải bảo mật**: PIN lưu dạng thường trong kho của app, và tham số nguy hiểm vẫn phải được firmware kiểm tra (PROTOCOL §1 điều 3). Widget đọc chế độ qua `SettingsScope.technician(context)`; không có `SettingsScope` (test cũ) → Standard.
51. **Khóa `adv`** (PROTOCOL v1.3): màn `adv` bị ẩn khỏi thanh tab và Drawer ở Standard; trường `adv` không vẽ nhưng vẫn nằm trong VALUES nên `if`/`en`, `sub`, `hdr` dùng bình thường. Đổi chế độ thì màn Thiết bị vẽ lại ngay; tab đang mở bị ẩn thì chuyển về tab đầu. Màn batch chỉ gửi trường đã sửa nên trường ẩn không bao giờ bị ghi. Mọi màn đều bị ẩn → hiện câu "không có màn hình".
52. **Phân chia nội dung có sẵn**: relay C3 — màn "Advanced" cũ tách thành **Alarm settings** (`alarms`, Standard thấy) và **Sensor setup** (`sensor`, Modbus, `adv`); nút Restart là trường `adv`, đổi tên thì không. Lò nung — adapter đánh `adv` cho các màn `pid`, `alarm` (ngưỡng cảnh báo lệch nhiệt, coi là cấu hình bảo vệ), `calibration`, `autotune`; `operation`, `program`, `program_steps` để Standard. Thiết bị mẫu, 2 file `docs/mau/`, `vph_demo`: nút Restart, tham số Modbus / hiệu chuẩn / PID đánh `adv`. Màn "Settings" của file mẫu nông nghiệp đổi tên thành "Alarm settings" vì trùng mục Settings của app trong Drawer.
53. **Màn Settings** (`ui/screens/settings_screen.dart`) thay các mục bật/tắt trong Drawer (thay mục 39, 42, 45 phần vị trí): **General** (Theme, Language, Auto-connect to last device, Keep screen on while connected — gói `wakelock_plus` 1.8.0, BSD-3), **Advanced** (Technician mode, Set PIN / Remove PIN), **Developer tools** (chỉ Technician: Demo devices, Open JSON file, Show device addresses, Export diagnostics log, Clear saved interfaces — có hỏi lại), **About** (Version, Open-source licenses). Drawer chỉ còn điều hướng: màn Quét có Device list, Settings, Help & about; màn Thiết bị có Device list, nhóm DEVICE (các màn `nav:"menu"`, Device info, Reload interface — chỉ Technician), nhóm APP (Settings, Help & about, Disconnect).
54. **Màn Quét và Device info theo chế độ**: thẻ thiết bị ở Standard chỉ có icon, tên, model, cột sóng; Technician thêm chip `VPH`/`Legacy`, địa chỉ MAC (tắt được bằng "Show device addresses") và số dBm. Device info ở Standard: Name, Model, Firmware, Hardware, Signal, Status; Technician thêm protocol, schema, MTU, số gói, địa chỉ và các cảnh báo về gói dữ liệu. Signal đọc bằng `GattLink.readRssi()` (hàm thêm vào interface), hiện bằng chữ Excellent / Good / Fair / Weak theo cùng ngưỡng với cột sóng.
55. **Câu chữ theo `docs/COPY_STYLE.md`** (thay mục 32, 44 phần chữ): sentence case mọi nơi; hộp xác nhận lấy câu hỏi `c` của thiết bị làm **tiêu đề**, nút xác nhận lặp lại hành động — nút lệnh `act` dùng chính nhãn của nút, công tắc dùng `Turn on`, còn lại `Confirm`; hộp nhập số / chữ dùng `Apply`. Bit báo động không có nhãn hiện `Alarm N` đếm từ 1. Khối lặp không có nhãn hiện `#1`, `#2`. Thời lượng `2 h 05 min`. Xóa thiết bị đã nhớ có SnackBar `Device removed` + `Undo`. Disconnect làm ngay; còn thay đổi chưa lưu thì hỏi `Disconnect from <name>?`. Thẻ lỗi màn hình chỉ hiện lỗi gốc ở Technician. Màn About: Standard một câu giới thiệu, Technician thêm dòng `Protocol VPH v1.3`.
    - Tiêu đề nhóm trong Drawer và màn Quét **bỏ in hoa toàn bộ** (trước là `DEVICE`, `SAVED DEVICES`) để đúng quy tắc 1; nhóm của màn Thiết bị đặt tên `This device` cho khỏi trùng với màn `Device` của thiết bị.
    - Phía thiết bị: schema relay C3 đổi `Silence` → `Silence buzzer`, `Auto source` → `Control by`, `Measured value` → `Sensor`, `Threshold type` → `Turn on when` (lựa chọn `Value is low` / `Value is high`), `Scale divisor` → `Scale factor`, `Humidity / Temperature index` → `… position`, `Temperature / humidity alarm` → `Enable alarm` (nhãn ≤ 24 ký tự), ghi chú `No sensor data`; mọi `d` là một câu có dấu chấm; câu `_reboot` là `Restart device?`. Bảng lỗi kiểm tra CONFIG của adapter relay C3 viết lại thành câu hướng dẫn (`Enter a Modbus address from 1 to 247.`). `vph_ble` 1.2.0 và `vph_demo` 1.3.0: mọi chuỗi lỗi tiếng Anh (`Command too long`, `Unknown field: <id>`); màn `Settings` của `vph_demo` đổi tên `Thresholds & schedule`.
56. **Ngôn ngữ bằng Flutter gen-l10n** (thay mục 45 phần cách làm): `flutter_localizations` + `intl`; `lib/l10n/app_en.arb` là bản gốc, `app_vi.arb` là bản dịch, `l10n.yaml` sinh `AppLocalizations` vào `lib/l10n/` (file sinh ra được commit để `flutter analyze` chạy ngay). Widget lấy chữ bằng `context.l.<khóa>` (`lib/l10n/l10n.dart`). `MaterialApp` có `supportedLocales: [en, vi]` và `locale` theo `AppSettings.locale`; mặc định **English**, không theo ngôn ngữ của máy. Đã bỏ `strings.dart`, biến toàn cục `Lang.code` và đoạn `markNeedsBuild` cả cây: đổi ngôn ngữ thì `MaterialApp` đổi `locale` nên mọi màn vẽ lại, kể cả hộp chọn giờ / ngày và nút hệ thống của Flutter.
    - **Lõi không còn chữ hiển thị**: transport và `DeviceSession` trả `AppError(kind, detail)` (`core/errors.dart`) và `SessionMessage` có kiểu (`MsgKind`), UI đổi sang chữ bằng `errorText()`. Câu `err` của thiết bị đi trong `AppError.device(text)` và hiện nguyên văn. `DeviceTransport.protoLabel` đổi thành `protoId` (mã), UI tự đổi sang chữ.
    - Schema lưu sẵn (relay C3, nhãn vá của lò nung, thiết bị mẫu) lấy theo ngôn ngữ **lúc kết nối**: `connectTransport(link, cache, lang: ...)`, adapter nhận tham số `lang`. Chữ của thiết bị VPH vẫn hiện nguyên văn.
    - Ngày hiện dạng `dd MMM yyyy` theo ngôn ngữ đang chọn (`dateText`), giá trị gửi xuống thiết bị vẫn là `YYYY-MM-DD`.
    - Test `test/l10n_test.dart`: khóa của hai file ARB khớp nhau, bản dịch giữ đủ tham số, chữ tiếng Anh theo COPY_STYLE, `lib/ui` không còn chuỗi hiển thị viết cứng. Tên app và ký hiệu không dịch (`VP Hub`, `VPH`, `TECH`, `--`) nằm ở `core/consts.dart`.
57. **Mở app và quét** (thay §3 và mục 33 phần tự kết nối): app **không còn nhảy thẳng** vào thiết bị cũ. Mở app → quét 10 s; trong **4 s đầu** nếu thấy thiết bị đã nhớ dùng gần nhất (`lastMs` lớn nhất) trong kết quả quét thì tự kết nối ngay; không thấy thì ở lại màn Quét và quét tiếp cho hết 10 s. Tắt "Auto-connect to last device" thì không tự kết nối.
    - **Lần đầu mở app**: màn `OnboardingScreen` (logo, một câu giới thiệu, lý do cần quyền Bluetooth, nút `Allow Bluetooth access`); bấm nút mới gọi hộp xin quyền của Android; lưu khóa `onboarded`. Bị từ chối vẫn vào màn Quét, ở đó có thẻ hướng dẫn + `Open settings`.
    - **Android 6–11, công tắc Location tắt**: thẻ `Turn on Location to find Bluetooth devices.` + nút mở cài đặt vị trí. App hỏi hệ điều hành qua một `MethodChannel` nhỏ trong `MainActivity.kt` (`vn.phan.vphub/sys`: `sdkInt`, `locationEnabled`, `openLocationSettings`) thay vì thêm gói mới.
    - Kéo xuống để quét lại (`RefreshIndicator`). Thẻ thiết bị đã nhớ: nhấn giữ (hoặc nút ⋮) → `Rename` (chỉ đổi tên hiển thị trong app, cờ `alias`, không bị tên quảng bá ghi đè khi kết nối lại) / `Remove` (có `Undo`).
    - `_open()` dùng `try/finally` nên cờ `_busy` luôn được trả lại.
58. **Báo lỗi** (`core/errors.dart`): mọi exception BLE / transport đổi thành `AppError(kind, detail)`; câu hiện cho người dùng lấy theo bảng ở PLAN_HOAN_THIEN §H6 (`errorText()` trong `lib/l10n/l10n.dart`). Thiết bị từ chối kèm `err` → hiện nguyên văn. Kết nối thất bại (hết 10 s, không thấy thiết bị) → `Can't reach the device…`; thiết bị không có dịch vụ nào trong 3 UUID → `This device isn't supported…`; INFO / schema hỏng → `The device sent invalid data…`. Standard chỉ thấy câu chuẩn; **Technician có thêm nút `Details`** (trên SnackBar lỗi và ở màn "Can't connect") mở hộp hiện lỗi gốc, rút gọn 300 ký tự.
59. **Nhật ký chẩn đoán** (`core/diag_log.dart`): vòng đệm 500 dòng trong bộ nhớ + file `vphub_log.txt` trong thư mục riêng của app (`getApplicationSupportDirectory`, gói `path_provider` BSD-3), tối đa 256 KB; đầy thì viết lại bằng các dòng mới nhất (tối đa nửa giới hạn). Ghi: mở app, kết nối / kết nối lại, đã kết nối (model, fw, giao thức, MTU, nguồn schema), mất kết nối, lỗi, lệnh ghi (`GHI id=giá trị -> ok/loi`; chuỗi người dùng nhập như tên thiết bị ghi thành `<text>`). Technician → Settings → Developer tools → **Export diagnostics log** chia sẻ file qua hộp Share của Android (gói `share_plus` 13.3.1, BSD-3). Nội dung nhật ký là log kỹ thuật, viết tiếng Việt không dấu như log firmware.
