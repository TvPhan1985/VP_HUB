# PLAN_GIAO_DIEN — Nâng giao diện VP Hub lên phong cách c3_relay_ctrl + chuẩn hóa VPH v1.1

> File này giao cho Claude Code làm. Đọc kèm `docs/PROTOCOL.md`, `docs/SPEC.md`, `CLAUDE.md`.
> Mục tiêu: VP Hub vẫn **vẽ giao diện từ schema** (không màn riêng cho model nào), nhưng **trông chuyên nghiệp như app c3_relay_ctrl**: thẻ số đo có icon, thẻ trạng thái lớn, nút BẬT/TẮT, thanh điều hướng dưới có icon, thẻ báo động đỏ.

---

## 1. Hiện trạng (đã đọc code 2026-10-07)

| | c3_relay_ctrl (app viết cứng) | vp_hub (app vẽ từ schema) |
|---|---|---|
| Điều hướng | `NavigationBar` dưới đáy, có icon | `TabBar` trên, chỉ chữ |
| Thanh tiêu đề | Tên + dòng "Đã kết nối" xanh | Chấm màu + tên |
| Số đo chính | 2 thẻ cạnh nhau: icon + nhãn + số to | Hàng "nhãn ← → giá trị", hoặc `big` chiếm cả dòng |
| Số đo phụ | 1 thẻ chia 3 cột (EC / Độ mặn / TDS) | Mỗi số một hàng |
| Relay | Thẻ lớn "Relay: BẬT/TẮT", icon nguồn, đổi màu khi bật, dòng phụ chế độ | Một công tắc `Switch` |
| Chế độ | `SegmentedButton` có icon | Nút chọn không icon |
| Bật/tắt tay | 2 nút BẬT / TẮT + dòng giải thích khi bị khóa | Công tắc mờ, không giải thích |
| Báo động | Thẻ đỏ, gạch đầu dòng, nút "Tắt còi" ở góc | Danh sách flags + nút rời |
| Thời gian chạy | "2 giờ 5 phút" | "7500 s" |
| Kết quả lệnh | SnackBar xanh khi OK, đỏ khi lỗi | SnackBar mặc định / đỏ |

Kết luận: phần lõi vp_hub (transport, cache, batch, adapter, `vph_ble`) **đã tốt, giữ nguyên**. Thiếu là **từ vựng hiển thị** trong schema — firmware chưa có cách nói "số này là thẻ có icon", "công tắc này là thẻ trạng thái lớn". Nên việc chính là bổ sung gợi ý hiển thị vào giao thức rồi viết thêm widget.

---

## 2. Các phương án (đã chọn A)

- **A. Bổ sung gợi ý hiển thị vào schema (CHỌN).** Thêm `ic`, `d`, `sub` và vài giá trị `w` mới. Thiết bị nào cũng dùng được, thiết bị cũ không ảnh hưởng, app cũ bỏ qua gợi ý lạ (đúng PROTOCOL §1.7).
- B. App tự đoán bố cục (mọi `num` chỉ đọc → thẻ…). Nhanh nhưng không điều khiển được, dễ xấu với thiết bị khác. Chỉ dùng làm **mặc định khi schema không có gợi ý** (xem §4.8).
- C. Màn riêng theo `model`. **Cấm** (trái quy tắc vàng của PROTOCOL).

---

## 3. Bổ sung giao thức — VPH v1.1 (giữ `pv:1`, tương thích ngược)

Ghi toàn bộ mục này vào `PROTOCOL.md` (các mục tương ứng) và §12 lịch sử. Không đổi gì trên đường truyền với thiết bị cũ.

### 3.1 Khóa mới

| Ở đâu | Khóa | Ý nghĩa |
|---|---|---|
| Màn hình | `ic` | Icon của tab ở thanh điều hướng dưới |
| Trường | `ic` | Icon của trường (thẻ số, thẻ trạng thái, nút) |
| Trường | `d` | Dòng chú thích nhỏ dưới trường. Nếu trường bị khóa do `en` sai thì chú thích hiện rõ hơn (giải thích vì sao khóa) |
| Trường | `sub` | Id một trường khác; giá trị của nó hiện làm dòng phụ (vd thẻ Relay hiện "Chế độ: Tự động") |
| `opt` của `enum` | phần tử thứ 3 | Icon cho từng lựa chọn: `["auto","Tự động","auto"]` |
| `opt` của `bool` | `["Tắt","Bật"]` | Chữ hiển thị cho 2 trạng thái (mặc định "TẮT"/"BẬT"). Vd lò: `["Dừng","Đang đốt"]` |

### 3.2 Bộ icon chuẩn (tên cố định, app ánh xạ sang Material Icons)

`dashboard, schedule, settings, tune, info, device, temp, hum, water, soil, light, sun, fan, pump, motor, fire, heater, bolt, power, plug, speed, gauge, timer, clock, calendar, alarm, warning, mute, bell, hand, auto, sensor, wifi, ble, battery, chip, play, pause, stop, refresh, reset, check, save`

Tên lạ → không hiện icon (không lỗi). Thêm icon mới = sửa danh sách này + app.

### 3.3 Gợi ý hiển thị `w` mới

| `w` | Áp cho | Hiển thị |
|---|---|---|
| `tile` | `num`, `text`, `enum` | Thẻ số đo: icon + nhãn + số to + đơn vị. **Các `tile` liền nhau xếp 2 cột** |
| `mini` | `num`, `text` | Ô số nhỏ. **Các `mini` liền nhau gom vào 1 thẻ, chia 3 cột** (tối đa 4) |
| `hero` | `bool` | Thẻ trạng thái lớn: icon + "`l`: BẬT/TẮT" + dòng `sub`; nền màu xanh khi bật (`warn` → đỏ) |
| `btns` | `bool` | 2 nút **BẬT / TẮT** thay công tắc. Đi với `hero` thì nút nằm trong thẻ hero |
| `seg` | `enum` | Nút chọn kiểu segmented, có icon từ `opt[2]`, chiếm cả chiều ngang |
| `alarm` | `flags` | Thẻ báo động: ≠0 → nền đỏ, icon cảnh báo, gạch đầu dòng từng lỗi; =0 → "Không có báo động" dấu tích xanh. **Trường `act`/`led` cùng nhóm `g`** được đặt vào góc phải thẻ |
| `note` | `bool`, `text` | Một dòng chữ màu cảnh báo (nhãn của trường), dùng với `if` (vd "Cảm biến mất kết nối" khi `sok==false`) |
| `dur` | `num` (giây) | Hiện "2 giờ 5 phút" / "5 phút 12 giây" |

Gợi ý vẫn ghép được bằng dấu phẩy: `"w":"tile,trend"`, `"w":"hero,btns"`.

### 3.4 Sửa giới hạn WRITE (vấn đề đã ghi ở SPEC §11.11)

Lưu 5 khung giờ một lần ≈ 300 byte > 240 → hiện bị chặn. Đề xuất:
- WRITE tối đa **500 byte**. App gửi bằng **long write** (`flutter_blue_plus`: `write(..., allowLongWrite: true)`, chỉ với write có phản hồi). NimBLE tự ghép prepared write.
- `vph_ble`: bộ đệm WRITE 512 byte, từ chối > 500 bằng RESULT `"err":"Lệnh quá dài"`.
- Thiết bị cũ (adapter) giữ giới hạn cũ trong adapter.
- Ghi vào PROTOCOL §8 + §12.

### 3.5 Ví dụ: màn "Tổng quan" relay C3 viết theo v1.1

```json
{"id":"overview","l":"Tổng quan","ic":"dashboard","save":"live","f":[
 {"id":"t","l":"Nhiệt độ","t":"num","u":"°C","dp":1,"ro":1,"w":"tile,trend","ic":"temp"},
 {"id":"h","l":"Độ ẩm","t":"num","u":"%","dp":1,"ro":1,"w":"tile","ic":"hum"},
 {"id":"ec","l":"EC","t":"num","ro":1,"w":"mini"},
 {"id":"sal","l":"Độ mặn","t":"num","ro":1,"w":"mini"},
 {"id":"tds","l":"TDS","t":"num","ro":1,"w":"mini"},
 {"id":"sok","l":"Cảm biến chưa có dữ liệu hoặc mất kết nối","t":"bool","ro":1,"w":"note","if":"sok==false"},
 {"id":"out","l":"Relay","t":"bool","w":"hero,btns","ic":"power","sub":"mode","en":"mode==manual","d":"Bật/tắt tay chỉ dùng được ở chế độ Tay"},
 {"id":"mode","l":"Chế độ","t":"enum","w":"seg","opt":[["manual","Tay","hand"],["auto","Tự động","auto"]]},
 {"id":"alarm","l":"Báo động","t":"flags","w":"alarm","g":"al","opt":["Mất cảm biến","Chưa có giờ","Nhiệt độ ngoài ngưỡng","Độ ẩm ngoài ngưỡng"]},
 {"id":"silence","l":"Tắt còi","t":"act","ic":"mute","g":"al","if":"alarm!=0&&muted!=true"},
 {"id":"time","l":"Giờ thiết bị","t":"text","ic":"clock","g":"Trạng thái"},
 {"id":"up","l":"Thời gian chạy","t":"num","u":"s","ro":1,"w":"dur","g":"Trạng thái"}]}
```

Lưu ý: chuỗi này dài hơn bản cũ (~1,3 KB). Vẫn < 1920 byte. Khi làm firmware thật (Phần D) có test kích thước.

---

## 4. Việc phía app (`app/`)

### 4.1 Theme chung — `lib/ui/theme.dart` (mới)
- Gom mọi màu/kích thước vào một chỗ (design token): seed teal `0xFF00796B`, `useMaterial3`, chế độ tối mặc định theo hệ thống.
- Bo góc thẻ 16, khoảng cách lề 12, khoảng giữa thẻ 8 (giống c3).
- Màu trạng thái dùng chung: `ok` (xanh lá), `warn` (đỏ = `cs.error`), `idle` (xám). Không rải `Colors.green` khắp nơi.
- Cỡ chữ: số `tile` 28 đậm, số `mini` 18, tiêu đề `hero` 22 đậm.

### 4.2 Khung màn Thiết bị — `device_screen.dart`
- Số màn ≤ 5 → **`NavigationBar` dưới đáy** với icon `ic` của màn (không có `ic` → icon theo vị trí: dashboard / schedule / tune / info). > 5 màn → giữ TabBar cuộn ngang.
- AppBar: tên thiết bị + dòng phụ "Đã kết nối" (xanh) / "Đang kết nối lại…" (vàng) / "Mất kết nối" (đỏ), giống c3. Thanh `LinearProgressIndicator` mảnh khi đang kết nối lại.
- Giữ nguyên logic hỏi lưu khi rời màn batch, banner mất kết nối.

### 4.3 Widget mới — `lib/ui/render/`
- `tile_card.dart` — `tile` (2 cột, dùng `Row` + `Expanded`, lẻ thì thẻ cuối chiếm cả dòng); có `trend` thì chạm vào thẻ mở biểu đồ ngay dưới.
- `mini_strip.dart` — gom `mini` liền nhau.
- `hero_card.dart` — `hero` (+ `btns` bên trong), đổi màu khi bật, dòng `sub`, dòng `d` khi bị khóa.
- `enum_field.dart` — thêm nhánh `seg` có icon, full width.
- `alarm_card.dart` — `alarm` + gom `act`/`led` cùng `g`.
- `note_line.dart`, định dạng `dur` trong `num_field.dart`.
- `icons.dart` — bảng tên icon §3.2 → `IconData`.
- `field_widget.dart` — hiện `d` dưới mọi trường; khi `en` sai thì `d` đổi màu nhấn.

### 4.4 Bộ xếp bố cục — `screen_view.dart`
Thứ tự xử lý trường: `note` → các cụm `tile` liền nhau → cụm `mini` → `hero` → `seg` → thẻ `alarm` (kèm trường cùng `g`) → các nhóm `g` còn lại → `rep`. **Giữ đúng thứ tự trong schema**, chỉ gom những trường liền nhau cùng kiểu.

### 4.5 Kết quả lệnh
SnackBar: OK → nền xanh lá chữ trắng 2 s ("Đã lưu", "Đã bật Relay"…); lỗi → nền đỏ, hiện nguyên `err` 5 s. Câu chữ gom trong `strings_vi.dart`.

### 4.6 Màn Quét — `scan_screen.dart`
- Mỗi thiết bị là một **thẻ**: icon theo `icon` trong INFO (nhớ từ lần kết nối trước), tên, model, cột sóng 4 vạch theo RSSI thay vì số dBm.
- Hai mục: "Thiết bị đã dùng" (có chấm xanh nếu đang thấy quanh đây) và "Thiết bị gần đây".
- Trạng thái trống đẹp: icon Bluetooth lớn + câu hướng dẫn. Nút Quét dạng `FloatingActionButton.extended` như c3.

### 4.7 Cập nhật schema lưu sẵn
- `assets/legacy/c3relay_v1.json`: đổi sang ví dụ §3.5 cho màn Tổng quan; thêm `ic` cho 4 màn (`dashboard`, `schedule`, `tune`, `device`); `d` cho `src` (3 câu giải thích như app cũ); khung giờ thêm `d:"Giờ tắt nhỏ hơn giờ bật = qua đêm"`.
- Adapter lò nung `legacy_kiln.dart`: nhiệt độ hiện tại `big,trend` + `ic:"fire"`, công tắc đốt `hero` với `opt:["Dừng","Đang đốt"]`, `safety` → `alarm`.
- `assets/demo/demo_all_types.json`: thêm đủ mọi gợi ý mới để test.

### 4.8 Mặc định khi schema không có gợi ý
Màn đầu tiên, nếu **không trường nào** có `w`: các `num` chỉ đọc đầu tiên (tối đa 2) tự hiện `tile`. Chỉ áp màn đầu, để thiết bị cũ trông khá hơn mà không phải sửa firmware.

---

## 5. Việc phía firmware (`firmware/components/vph_ble`)
- Hàm mới: `vph_icon(f, "temp")` (dùng cho cả màn và trường), `vph_desc(f, "...")`, `vph_sub(f, "mode")`, `vph_bool_labels(f, "Dừng", "Đang đốt")`, `vph_options_ic(f, vals, labels, icons, n)`.
- Bộ đệm WRITE 512 byte, giới hạn 500 (§3.4); test Unity cho lệnh `set` dài.
- `VERSION` → `1.1.0`, README component cập nhật ví dụ.
- `examples/vph_demo`: màn Tổng quan dùng `tile`, `hero,btns`, `seg`, `alarm` để làm **mẫu chuẩn mới**.
- `docs/QUY_TAC_THIET_BI_MOI.md` quy tắc 5 bổ sung: "Số đo chính dùng `tile` + `ic`; công tắc tải chính dùng `hero,btns`; chế độ dùng `seg`; báo động dùng `alarm`; mỗi màn có `ic`."

---

## 6. Thứ tự làm và tiêu chí xong

| Phase | Việc | Xong khi |
|---|---|---|
| U1 | Sửa `PROTOCOL.md` (§3 file này) + SPEC | Tài liệu cập nhật, §12 ghi lý do |
| U2 | Model đọc khóa mới (`ic`, `d`, `sub`, opt 3 phần tử, opt bool), bảng icon, theme | `flutter test` qua, test parser cho khóa mới |
| U3 | Widget mới + bộ xếp bố cục + NavigationBar + AppBar | Widget test vẽ `demo_all_types` không lỗi; test: 2 `tile` liền nhau nằm cùng 1 hàng |
| U4 | Cập nhật `c3relay_v1.json`, adapter lò, demo | Mở Thiết bị mẫu, chụp màn hình emulator; so với `c3_relay_ctrl/logs/screen2.png` — bố cục tương đương |
| U5 | Màn Quét mới, SnackBar | Kiểm tra bằng mắt trên điện thoại |
| U6 | Long write: app + `vph_ble` 1.1.0 + test_app + vph_demo | Build firmware OK, test Unity qua; lưu 5 khung giờ một lần thành công trên vph_demo |
| U7 | Build APK `release/VPHub_1.1.0.apk`, cập nhật README | Cài lên điện thoại, kết nối relay C3 thật (adapter) chạy đủ chức năng như bảng đối chiếu SPEC §11 |

Chú ý: app 1.1 phải mở được thiết bị VPH 1.0 (không có gợi ý mới) và ngược lại app 1.0 mở thiết bị 1.1 không crash. Thêm test cho cả hai chiều.

---

## 7. Câu giao việc cho Claude Code

```
Đọc CLAUDE.md, docs/PROTOCOL.md, docs/SPEC.md rồi docs/PLAN_GIAO_DIEN.md.
Làm lần lượt Phase U1 → U6 không hỏi lại (theo quy tắc trong CLAUDE.md).
Tham khảo giao diện (CHỈ ĐỌC): D:\2026\c3_relay_ctrl\app\lib\ui\*.dart và logs/screen2.png.
Không thêm màn riêng cho model nào. Mỗi phase xong: flutter analyze + flutter test, commit "uiN: <tóm tắt>".
Phase U7 cần điện thoại + relay C3: hỏi mình trước khi làm.
```
