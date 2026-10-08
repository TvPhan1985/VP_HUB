# PROTOCOL — Giao thức BLE chung VPH v1

**VPH** (VP Hub) là "ngôn ngữ chung" giữa app Android **VP Hub** và mọi thiết bị ESP32 của Phận.
Thiết bị nào làm đúng file này thì app VP Hub **tự quét thấy, tự đọc, tự vẽ giao diện, tự ghi được** mà **không phải sửa hay build lại app**.

Ý tưởng lấy từ dự án lò nung (`Temp_Max31856`: SELECT / SCHEMA / VALUES / WRITE, giao diện sinh từ JSON), bổ sung những thứ dự án `c3_relay_ctrl` cần mà lò nung chưa có: phản hồi kết quả (RESULT), kiểu dữ liệu giờ / ngày / thứ / danh sách chọn / nút lệnh, ghi theo lô (batch), đồng bộ giờ, thông tin thiết bị.

> File này là **nguồn sự thật duy nhất** của giao thức. App và firmware chỉ làm theo file này. Muốn đổi thì tăng phiên bản (`pv`) và ghi lý do ở §12.

---

## 1. Quy tắc vàng (đọc trước)

1. **Một UUID dịch vụ duy nhất cho mọi thiết bị**: `5b390001-5578-4ab2-9265-4b994a7bc724`. Không bao giờ đổi. Thiết bị phân biệt nhau bằng `model` trong INFO, không bằng UUID.
2. **App không biết trước thiết bị có gì.** Mọi màn hình, nhãn, đơn vị, giới hạn, danh sách chọn đều do firmware gửi lên. Thêm/bớt trường ở firmware → app tự hiện theo.
3. **Firmware là nơi kiểm tra hợp lệ cuối cùng.** App chỉ kiểm tra sơ bộ theo `min/max`. Sai thì firmware trả lỗi tiếng Việt qua RESULT, app hiện nguyên văn.
4. **Giới hạn kích thước** (§8) là luật cứng, firmware phải tự kiểm tra lúc khởi động và có test.
5. **Không làm việc nặng trong callback GATT** (ghi NVS, quảng bá lại, chờ cảm biến). Chuyển sang task chính qua queue.
6. Schema lưu sẵn trong app (adapter thiết bị cũ, demo) không bị giới hạn kích thước vì không đi qua BLE.
7. Kiểu hoặc gợi ý hiển thị nào app chưa biết → app **hiện dạng chữ chỉ đọc**, không được crash. Trường JSON lạ → bỏ qua.

---

## 2. Quảng bá (advertising)

| Gói | Nội dung |
|---|---|
| Advertising | flags + **UUID 128-bit dịch vụ VPH** (danh sách đầy đủ) |
| Scan response | **Tên đầy đủ** (complete local name), ASCII, 1–20 ký tự |

- Tên mặc định: `<TEN-MODEL>-<4 hex cuối MAC>`, ví dụ `C3-RELAY-A1B2`, `KILN-3F0C`. Người dùng đổi được tên qua `_name` (§6.3).
- Đổi tên thì quảng bá lại (làm trong task chính).
- Chỉ **1 kết nối** cùng lúc. Mất kết nối thì quảng bá lại ngay.

---

## 3. Dịch vụ GATT

UUID gốc: `5b39XXXX-5578-4ab2-9265-4b994a7bc724`

| Tên | XXXX | Thuộc tính | Nội dung |
|---|---|---|---|
| (service) | `0001` | — | Dịch vụ VPH |
| INFO | `0002` | Read | JSON thông tin thiết bị (§4) |
| SELECT | `0003` | Write, Read | 1 hoặc 2 byte: `[màn hình, trang]` — màn hình 0..N-1, trang schema 0.. (thiếu byte trang = trang 0) |
| SCHEMA | `0004` | Read | Trang đang chọn của chuỗi JSON mô tả màn hình (§5, §8.1). Màn hình ≥ N trả về `{}` |
| VALUES | `0005` | Read, Notify | JSON giá trị của màn hình đang chọn (§7) |
| WRITE | `0006` | Write (có phản hồi) | Lệnh ghi (§6) |
| RESULT | `0007` | Notify | Kết quả của mỗi lệnh ghi (§6.4) |

Viết UUID trong NimBLE: `BLE_UUID128_INIT` nhận byte **ngược** so với chuỗi (little-endian). Component `vph_ble` (§10) đã làm sẵn, không tự gõ lại.

- MTU: firmware đặt `ble_att_set_preferred_mtu(512)`, app gọi `requestMtu(512)` (chỉ Android).
- VALUES notify **mỗi 1 giây** khi app đã đăng ký (xử lý `BLE_GAP_EVENT_SUBSCRIBE`), và **gửi ngay** sau mỗi lệnh ghi thành công.
- Khi app ghi SELECT, lần đọc/notify VALUES kế tiếp phải là của màn hình mới.
- Khi có kết nối mới: SELECT về 0.

---

## 4. INFO — thông tin thiết bị

```json
{"proto":"vph","pv":1,"model":"c3relay","name":"C3-RELAY-A1B2","fw":"1.1.0","hw":"esp32c3",
 "n":3,"sch":"9f3a","hdr":["t","h","out","alarm"],"caps":["time"],"icon":"relay"}
```

| Khóa | Bắt buộc | Ý nghĩa |
|---|---|---|
| `proto` | có | Luôn là `"vph"` |
| `pv` | có | Phiên bản giao thức, hiện tại `1` |
| `model` | có | Mã loại thiết bị, chữ thường, không dấu, không cách (`c3relay`, `kiln31856`, `growhub`…). **Không đổi** sau khi đã phát hành |
| `name` | có | Tên đang quảng bá |
| `fw` | có | Phiên bản firmware `x.y.z` |
| `hw` | không | Chip / board |
| `n` | có | Số màn hình |
| `sch` | có | Mã băm (CRC16 hex) của toàn bộ schema. App dùng để **cache** schema theo `model+sch`, lần sau kết nối khỏi đọc lại |
| `hdr` | không | Danh sách id trường "đầu trang": firmware **luôn chèn** các trường này vào VALUES của **mọi** màn hình, để app hiện thanh trạng thái cố định ở trên cùng |
| `caps` | không | Khả năng thêm. `"time"`: thiết bị cần giờ, app gửi `_time` ngay khi kết nối |
| `icon` | không | Gợi ý biểu tượng: `relay`, `heater`, `sensor`, `pump`, `light`, `motor`, `generic` |
| `dom` | không | Lĩnh vực của thiết bị (v1.2): `"ind"` = công nghiệp (mặc định khi không có), `"agri"` = nông nghiệp. App chọn bộ giao diện theo khóa này (công nghiệp: thanh trên xám đậm, màu nhấn xanh dương; nông nghiệp: thanh trên xanh lá, màu nhấn xanh lá). Giá trị lạ → coi như `ind` |

---

## 5. SCHEMA — mô tả một màn hình

```json
{"id":"overview","l":"Tổng quan","save":"live","f":[ ...trường... ],"rep":{ ...lặp... }}
```

| Khóa | Ý nghĩa |
|---|---|
| `id` | Mã màn hình (không dấu) |
| `l` | Tiêu đề tab (tiếng Việt có dấu được) |
| `save` | `"live"`: mỗi thay đổi gửi ngay (công tắc, setpoint…). `"batch"`: app cho sửa nhiều ô rồi bấm **Lưu**, gửi một lệnh `set` duy nhất. Dùng `batch` khi các trường ràng buộc nhau (ví dụ ngưỡng bật < ngưỡng tắt) |
| `f` | Mảng trường (§5.1) |
| `rep` | Khối lặp (§5.3), tùy chọn |
| `ic` | Icon của tab (§5.6), tùy chọn (v1.1) |
| `nav` | Vị trí của màn trong app, tùy chọn (v1.1). Không có = một **tab**. `"menu"` = màn cài đặt / thông tin ít dùng: không làm tab, app đưa vào **menu hệ thống** (Navigation Drawer, nút [≡] góc trên bên trái; app 1.1 dùng menu ⋮), bấm thì mở thành trang riêng. Dữ liệu trên đường truyền không đổi (vẫn SELECT theo số thứ tự màn). Giá trị lạ → coi như tab |

App chấp nhận cả khóa dài để tương thích lò nung cũ: `title`=`l`, `fields`=`f`, `repeat`=`rep`.

### 5.1 Trường

```json
{"id":"sv","l":"Nhiệt độ đặt","t":"num","u":"°C","min":0,"max":1200,"st":1,"dp":0}
```

| Khóa | Ý nghĩa | Khóa dài tương đương |
|---|---|---|
| `id` | Mã trường, duy nhất trong thiết bị, `[a-z0-9_]`, ≤ 16 ký tự. Bắt đầu bằng `_` là id dành riêng (§6.3) | |
| `l` | Nhãn | `label` |
| `t` | Kiểu (§5.2) | `type` |
| `u` | Đơn vị | `unit` |
| `min`,`max`,`st` | Giới hạn và bước (kiểu `num`); với `str` thì `max` là độ dài tối đa | `step` |
| `dp` | Số chữ số thập phân khi hiển thị | |
| `ro` | `1` = chỉ đọc | `readonly` |
| `opt` | Danh sách chọn (`enum`) hoặc nhãn từng bit (`flags`) | |
| `w` | Gợi ý hiển thị (§5.4) | |
| `c` | Câu hỏi xác nhận trước khi gửi (nút nguy hiểm) | |
| `if` | Điều kiện **hiện** trường (§5.5) | |
| `en` | Điều kiện **cho phép sửa** (§5.5) | |
| `nul` | `1` = được phép `null` (app hiện thêm công tắc "Không giới hạn") | |
| `g` | Tên nhóm: các trường cùng `g` liền nhau được gom vào một thẻ | |
| `ic` | Icon của trường (thẻ số, thẻ trạng thái, nút), tên trong §5.6 (v1.1) | |
| `d` | Dòng chú thích nhỏ dưới trường. Trường bị khóa do `en` sai thì chú thích hiện rõ hơn, để giải thích vì sao khóa (v1.1) | |
| `sub` | Id một trường khác; giá trị của nó hiện làm dòng phụ của thẻ `hero` (vd thẻ Relay hiện "Chế độ: Tự động") (v1.1) | |

### 5.2 Kiểu dữ liệu

| `t` | Giá trị trong VALUES | App hiển thị | Ghi chú |
|---|---|---|---|
| `num` | số hoặc `null` | ô số / bàn phím số + nút ± theo `st` | kiểu cũ `float`, `int` = `num` |
| `bool` | `true/false` (chấp nhận `0/1`) | công tắc | `opt` tùy chọn (v1.1): `["Dừng","Đang đốt"]` = chữ cho 2 trạng thái tắt / bật |
| `text` | chuỗi | chữ chỉ đọc | trạng thái, thông báo |
| `str` | chuỗi | ô nhập chữ | `max` = độ dài tối đa |
| `enum` | chuỗi hoặc số | nút chọn (≤ 4 mục) hoặc danh sách thả | `opt`: `[["auto","Tự động"],["manual","Tay"]]`; phần tử thứ 3 tùy chọn là icon (v1.1): `["auto","Tự động","auto"]` |
| `time` | `"HH:MM"` | bộ chọn giờ | |
| `date` | `"YYYY-MM-DD"` hoặc `null` | bộ chọn ngày | dùng với `nul:1` |
| `days` | số 0..127 | 7 nút T2 … CN | bit0 = Thứ 2 … bit6 = Chủ nhật, 127 = mọi ngày |
| `flags` | số (bitmask) | danh sách cảnh báo, đỏ khi ≠ 0 | `opt`: `["Mất cảm biến","Chưa có giờ",...]` theo bit0, bit1… |
| `act` | (không cần có trong VALUES) | nút bấm | gửi `{"id":X,"v":1}`; nên có `c` |

### 5.3 Khối lặp (`rep`)

Cho các nhóm giống nhau (bước chương trình nhiệt, khung giờ…), firmware chỉ mô tả mẫu **một lần**:

```json
"rep":{"n":5,"pfx":"s","l":"Khung","f":[
  {"id":"en","l":"Bật","t":"bool"},
  {"id":"days","l":"Thứ","t":"days"},
  {"id":"on","l":"Giờ bật","t":"time"},
  {"id":"off","l":"Giờ tắt","t":"time"}]}
```

App tự sinh `s1_en, s1_days, s1_on, s1_off, … s5_off`, mỗi lần lặp là một thẻ "Khung 1", "Khung 2"…
Tùy chọn `"cnt":"<id>"`: chỉ hiện số thẻ bằng giá trị trường `<id>` (ví dụ `program_step_count`).
Khóa dài tương thích lò nung: `count`=`n`, `prefix`=`pfx`, `fields`=`f`; với khóa dài, id sinh ra là `step1_t` (giống lò nung cũ).

### 5.4 Gợi ý hiển thị (`w`)

| `w` | Ý nghĩa |
|---|---|
| `big` | Số to giữa màn hình (nhiệt độ chính) |
| `trend` | App lưu lịch sử trong RAM (tối đa 1 giờ) và vẽ biểu đồ đường |
| `led` | Bool hiện thành đèn tròn xanh/xám, không phải công tắc |
| `gauge` | Đồng hồ kim (cần `min`,`max`) |
| `warn` | Dùng kèm `led`: đèn màu **đỏ** khi bật (lỗi, khóa an toàn) thay vì xanh |


Bổ sung v1.1 (thiết bị 1.0 không cần đổi gì; app 1.0 gặp các gợi ý này thì vẽ kiểu mặc định của `t`):

| `w` | Áp cho | Hiển thị |
|---|---|---|
| `tile` | `num`, `text`, `enum` | Thẻ số đo: icon + nhãn + số to + đơn vị. **Các `tile` liền nhau xếp 2 cột**. Kèm `trend` thì chạm vào thẻ để mở biểu đồ |
| `mini` | `num`, `text` | Ô số nhỏ. **Các `mini` liền nhau gom vào 1 thẻ**, chia cột đều (tối đa 4 ô một hàng) |
| `hero` | `bool` | Thẻ trạng thái lớn: icon + "`l`: BẬT/TẮT" + dòng `sub`; nền xanh khi bật (kèm `warn` → đỏ) |
| `btns` | `bool` | 2 nút **BẬT / TẮT** thay công tắc. Đi với `hero` thì nút nằm trong thẻ hero |
| `seg` | `enum` | Nút chọn chiếm cả chiều ngang, có icon lấy từ `opt[2]` |
| `alarm` | `flags`, `bool` | Thẻ báo động: `flags` ≠ 0 (hoặc `bool` = true) → nền đỏ, icon cảnh báo, gạch đầu dòng từng lỗi; ngược lại → "Không có báo động", dấu tích xanh. Các trường **liền sau, cùng nhóm `g`** được đặt vào trong thẻ: `act` thành nút ở góc phải, `bool` thành đèn, `text` thành một dòng gạch đầu dòng |
| `note` | `bool`, `text` | Một dòng chữ màu cảnh báo (nhãn của trường `bool`, hoặc giá trị của trường `text`); dùng với `if` (vd "Cảm biến mất kết nối" khi `sok==false`) |
| `dur` | `num` (giây) | Hiện "2 giờ 5 phút" / "5 phút 12 giây" |

Một trường có thể mang **nhiều gợi ý**, cách nhau dấu phẩy: `"w":"big,trend"`, `"w":"led,warn"`, `"w":"tile,trend"`, `"w":"hero,btns"`.
App chưa biết gợi ý nào thì hiển thị kiểu mặc định của `t`.
App giữ **đúng thứ tự trường trong schema**, chỉ gom những trường liền nhau cùng kiểu (`tile`, `mini`, cùng `g`).

### 5.5 Điều kiện `if` / `en`

Chuỗi dạng `"<id><op><giá trị>"`, `op` là `==` hoặc `!=`; nối nhiều điều kiện bằng `&&`. Giá trị so sánh với VALUES hiện tại (kể cả trường `hdr`).
Ví dụ: `"if":"safety_latched==true"`, `"en":"mode==manual"`, `"if":"src!=schedule"`.
Không có trường trong VALUES → coi điều kiện là **đúng** (hiện, cho sửa).

### 5.6 Bộ icon chuẩn (v1.1)

Tên cố định, app ánh xạ sang biểu tượng của mình. Dùng cho `ic` của màn hình, `ic` của trường và `opt[2]` của `enum`:

`dashboard, schedule, settings, tune, info, device, temp, hum, water, soil, light, sun, fan, pump, motor, fire, heater, bolt, power, plug, speed, gauge, timer, clock, calendar, alarm, warning, mute, bell, hand, auto, sensor, wifi, ble, battery, chip, play, pause, stop, refresh, reset, check, save`

Tên lạ → không hiện icon (không lỗi). Thêm icon mới = sửa danh sách này + app. Màn hình không có `ic` → app tự chọn icon theo vị trí tab.

---

## 6. WRITE và RESULT

### 6.1 Ghi một trường (màn hình `live`)
```json
{"q":12,"id":"sv","v":150}
```

### 6.2 Ghi theo lô (màn hình `batch`)
```json
{"q":13,"set":{"src":"sensor","on_at":70,"off_at":80}}
```
Firmware áp **tất cả** lên bản sao cấu hình → kiểm tra hợp lệ → hợp lệ mới lưu. Sai thì giữ nguyên cấu hình cũ.

`q` là số thứ tự 1..65535 do app tăng dần, firmware trả lại trong RESULT.

### 6.3 Id dành riêng

| id | `v` | Ý nghĩa |
|---|---|---|
| `_time` | epoch UTC (số nguyên) | Đặt giờ. App gửi ngay sau khi kết nối nếu `caps` có `"time"` |
| `_name` | chuỗi 1–20 ASCII, không `"` `\` | Đổi tên quảng bá |
| `_reboot` | `1` | Khởi động lại (trả RESULT trước, lưu NVS, rồi reset sau 0,5 s) |

### 6.4 RESULT
```json
{"q":12,"ok":1}
{"q":13,"ok":0,"err":"Ngưỡng bật phải nhỏ hơn ngưỡng tắt"}
```
- Firmware trả RESULT cho **mọi** lệnh ghi trong vòng **1 giây**. App chờ tối đa **3 giây**, quá thì báo "Thiết bị không phản hồi".
- `err` tiếng Việt có dấu, ≤ 80 byte. Id không biết → `"err":"Không có trường <id>"`.

---

## 7. VALUES

Một object phẳng `{"id":giá_trị,...}` gồm: các trường của màn hình đang chọn (kể cả trường sinh từ `rep`) **+** các trường trong `hdr`.
- Chưa có dữ liệu → `null` (app hiện `--`).
- Số thực in tối đa 2 chữ số thập phân để tiết kiệm byte.

---

## 8. Giới hạn kích thước (luật cứng)

| Gói | Tối đa | Lý do |
|---|---|---|
| INFO | 240 byte | đọc 1 gói kể cả khi MTU chỉ được 247 |
| SCHEMA mỗi **trang** | **480 byte** | 1 attribute BLE tối đa 512 byte. Cả màn hình tối đa 4 trang = 1920 byte (§8.1) |
| VALUES (mỗi màn hình, kể cả `hdr`) | **240 byte** | notify tối đa MTU−3 = 244 byte nếu điện thoại chỉ cho MTU 247. Dài hơn sẽ bị cắt, app không đọc được |
| WRITE | **500 byte** | v1.1 (trước là 240). Lệnh dài hơn MTU−3 thì app gửi bằng **long write** (prepared write, có phản hồi); NimBLE tự ghép. Dài hơn 500 → RESULT `"err":"Lệnh quá dài"` |
| RESULT | 120 byte | |

Chữ tiếng Việt có dấu tốn 2–3 byte/ký tự (ví dụ §11 đã là ~556 byte). VALUES quá 240 byte → **tách thành 2 màn hình**, hoặc rút id ngắn lại.

### 8.1 Đọc schema theo trang
Chuỗi JSON schema của một màn hình được **cắt thô** thành các trang 480 byte (cắt theo byte, không cần đúng ranh giới JSON).
App: ghi SELECT `[i, 0]` → đọc SCHEMA → nếu nhận đủ 480 byte thì ghi `[i, 1]`, đọc tiếp… dừng khi trang nhận được < 480 byte (trang cuối đúng 480 byte thì trang kế là rỗng). Ghép lại rồi mới parse JSON.
Sau khi đọc schema xong, app ghi SELECT `[i]` (1 byte) để chọn màn hình cho VALUES. Thiết bị cũ chỉ nhận 1 byte vẫn tương thích (chỉ có trang 0).
`vph_ble` làm sẵn việc cắt trang.
Firmware phải `ESP_LOGW` khi vượt và có **unit test** kiểm tra kích thước lớn nhất của từng màn hình.

---

## 9. Trình tự app làm việc với thiết bị

1. Quét theo UUID dịch vụ VPH (và các UUID cũ, xem `LEGACY.md`).
2. Kết nối → `requestMtu(512)` → tìm 6 characteristic.
3. Đọc INFO. Kiểm tra `proto=="vph"` và `pv`. `pv` lớn hơn app hỗ trợ → báo "Cần cập nhật app", vẫn thử hiển thị.
4. Nếu cache có `model+sch` → dùng luôn. Không thì lặp `i = 0..n-1`: đọc schema theo trang (§8.1).
5. Đăng ký notify RESULT, rồi VALUES.
6. `caps` có `time` → ghi `_time`.
7. SELECT tab đầu tiên. Đổi tab → ghi SELECT tương ứng.

---

## 10. Component firmware dùng chung `vph_ble`

Mọi dự án ESP-IDF mới **không tự viết lại GATT**, mà dùng component `vph_ble` (C, NimBLE) ở `firmware/components/vph_ble`. API đầy đủ: `include/vph_ble.h`; cách dùng: `README.md` của component. Tóm tắt:

```c
typedef struct {
    const char *model, *fw, *hw, *icon;
    const char *domain;         // "ind" (mac dinh khi NULL) | "agri" -> khoa "dom" cua INFO
    const char *const *hdr;       // NULL-terminated
    uint32_t caps;                // VPH_CAP_TIME ...
    const char *name_prefix;      // tên mặc định = <name_prefix>-<4 hex MAC>
} vph_info_t;

// Dựng schema
cJSON *vph_screen(const char *id, const char *title, const char *save);
cJSON *vph_field(cJSON *screen_or_rep, const char *id, const char *label, const char *type);
void   vph_range(cJSON *f, double min, double max, double step);
void   vph_unit / vph_dp / vph_readonly / vph_nullable / vph_hint / vph_confirm /
       vph_show_if / vph_enable_if / vph_group / vph_maxlen (cJSON *f, ...);
// v1.1: icon (dùng cho cả màn hình và trường), chú thích, dòng phụ, chữ 2 trạng thái của bool
void   vph_icon / vph_desc / vph_sub (cJSON *screen_or_field, const char *s);
void   vph_bool_labels(cJSON *f, const char *off, const char *on);
void   vph_nav_menu(cJSON *screen);   // màn cài đặt/thông tin: nằm trong menu hệ thống [≡] thay vì làm tab
void   vph_options_ic(cJSON *f, const char *const *vals, const char *const *labels,
                      const char *const *icons, int n);
void   vph_options(cJSON *f, const char *const *vals, const char *const *labels, int n);
void   vph_flag_labels(cJSON *f, const char *const *labels, int n);
cJSON *vph_repeat(cJSON *screen, int n, const char *pfx, const char *label);

// Điền VALUES: project ghi các trường của màn `screen` vào out.
// screen == VPH_SCREEN_HDR: ghi các trường đầu trang.
typedef void (*vph_values_cb)(uint8_t screen, vph_out_t *out);
void vph_out_num(vph_out_t *o, const char *id, double v, int dp);
void vph_out_int / vph_out_bool / vph_out_str / vph_out_null (...);

// Ghi: luôn chạy trong TASK gọi vph_poll() (không phải callback GATT).
// Trả VPH_OK, VPH_ERR_UNKNOWN (không biết trường), hoặc VPH_ERR_REJECT kèm err tiếng Việt.
typedef int (*vph_write_cb)(const char *id, const cJSON *v, char *err, size_t err_len);
typedef int (*vph_batch_cb)(const cJSON *set, char *err, size_t err_len);

esp_err_t vph_init(const vph_info_t *info, cJSON *const *screens, int n,
                   vph_values_cb vcb, vph_write_cb wcb, vph_batch_cb bcb);
void vph_poll(void);              // gọi ≥ 10 lần/giây trong vòng lặp task chính
esp_err_t vph_set_name(const char *name);
void vph_notify_now(void);
bool vph_connected(void);
```

`vph_ble` tự lo: UUID, quảng bá, MTU, SELECT, cache chuỗi schema, tính `sch`, ghép `hdr` vào VALUES, notify 1 s, queue lệnh ghi, `_time`/`_name`/`_reboot` (gọi lại project qua `wcb` trước khi thực hiện), RESULT, cảnh báo kích thước.

---

## 11. Ví dụ đầy đủ một màn hình

SCHEMA tối thiểu (v1.0, vẫn hợp lệ):
```json
{"id":"overview","l":"Tổng quan","save":"live","f":[
 {"id":"t","l":"Nhiệt độ","t":"num","u":"°C","dp":1,"ro":1,"w":"trend"},
 {"id":"h","l":"Độ ẩm","t":"num","u":"%","dp":1,"ro":1},
 {"id":"mode","l":"Chế độ","t":"enum","opt":[["manual","Tay"],["auto","Tự động"]]},
 {"id":"out","l":"Relay","t":"bool","en":"mode==manual"},
 {"id":"alarm","l":"Báo động","t":"flags","opt":["Mất cảm biến","Chưa có giờ","Nhiệt độ ngoài ngưỡng","Độ ẩm ngoài ngưỡng"]},
 {"id":"silence","l":"Tắt còi","t":"act","if":"alarm!=0"}]}
```
VALUES: `{"t":28.4,"h":72.5,"mode":"auto","out":true,"alarm":0}`

Cùng màn hình, viết theo v1.1 (**mẫu nên theo** cho thiết bị mới):
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
Chuỗi này khoảng 1,3 KB (3 trang), vẫn dưới 1920 byte.

---

## 12. Lịch sử thay đổi giao thức
- v1 (2026-10): bản đầu.
- v1, bổ sung 2026-10-06 (không tăng `pv`, tương thích ngược — app cũ hơn chỉ bỏ qua gợi ý lạ):
  - §5.4: `w` nhận nhiều gợi ý cách nhau dấu phẩy. Lý do: nhiệt độ chính của lò cần vừa số to vừa biểu đồ (`big,trend`).
  - §5.4: gợi ý `warn` cho đèn `led`. Lý do: đèn "khóa an toàn"/"lỗi" bật thì phải đỏ, không phải xanh.
  - Làm rõ cách app hiểu (không đổi dữ liệu trên đường truyền): `c` trên `bool` chỉ hỏi khi bật; `if`/`en` trong mẫu `rep` trỏ tới trường cùng lần lặp nếu trùng id trong mẫu (xem SPEC §11).
- **v1.1 (2026-10-07)**, giữ `pv:1`, tương thích hai chiều (thiết bị 1.0 mở bằng app 1.1 như cũ; app 1.0 mở thiết bị 1.1 thì bỏ qua khóa và gợi ý lạ, vẽ kiểu mặc định). Lý do chung: schema thiếu "từ vựng hiển thị" nên app vẽ ra toàn hàng "nhãn – giá trị", kém xa app viết riêng cho bộ relay C3.
  - §5, §5.1: khóa `ic` (màn hình và trường), `d` (chú thích), `sub` (dòng phụ).
  - §5.2: `opt` của `enum` nhận phần tử thứ 3 là icon; `bool` nhận `opt` 2 phần tử làm chữ cho trạng thái tắt / bật.
  - §5.4: gợi ý `tile`, `mini`, `hero`, `btns`, `seg`, `alarm`, `note`, `dur`. `alarm` áp được cho cả `bool` (lò nung chỉ có một cờ "khóa an toàn", không có bitmask).
  - §5.6: bộ tên icon chuẩn.
  - §8: WRITE tối đa 500 byte (trước 240), gửi bằng long write. Lý do: lưu 5 khung giờ một lần ≈ 300 byte bị chặn (SPEC §11.11). Firmware `vph_ble` 1.0.0 đã có bộ đệm 512 byte nên vẫn nhận được; adapter thiết bị đời cũ giữ giới hạn riêng.
  - §10: hàm `vph_icon`, `vph_desc`, `vph_sub`, `vph_bool_labels`, `vph_options_ic`, `vph_nav_menu`.
  - §5: khóa `nav` của màn hình (`"menu"`). Lý do: các màn "Nâng cao", "Thiết bị" là cài đặt và thông tin, để chung hàng tab với màn dùng hằng ngày làm thanh tab chật và rối; người dùng yêu cầu đưa vào menu ⋮. App 1.0 bỏ qua khóa này nên vẫn hiện thành tab như cũ.
- **v1.2 (2026-10-08)**, giữ `pv:1`, tương thích hai chiều.
  - §4: khóa `dom` của INFO (`"ind"` / `"agri"`). Lý do: quy chuẩn giao diện có hai bộ mẫu (Factory SCADA và Smart Farm); bộ relay C3 dùng cho nông nghiệp nên phải hiện theo mẫu nông nghiệp, lò nung theo mẫu công nghiệp. App không được đoán theo `model`, nên thiết bị tự khai lĩnh vực. Thiết bị cũ không có `dom` → công nghiệp như trước; app cũ bỏ qua khóa này.
  - §10: trường `domain` trong `vph_info_t`.
