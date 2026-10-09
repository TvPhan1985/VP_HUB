# QUY CHUẨN DỰ ÁN THIẾT BỊ MỚI — để app VP Hub tự nhận và tự vẽ đúng giao diện

Bản 1.4 (2026-10-09). Áp dụng cho **mọi** dự án ESP32 (ESP-IDF) có điều khiển / cài đặt qua điện thoại.
Đọc file này **trước khi viết dòng code BLE đầu tiên**. Chi tiết từng byte nằm ở `PROTOCOL.md`; file này nói **phải làm gì và làm theo thứ tự nào**.

Nguyên tắc: **không làm app mới, không sửa app**. Thiết bị tự khai mình là gì và có những màn hình nào; app VP Hub đọc lời khai đó rồi vẽ.

---

## 1. Làm theo 7 bước

| Bước | Việc | Xong khi |
|---|---|---|
| 1 | Chọn `model`, lĩnh vực (`dom`), icon thiết bị (§2) | Đã ghi vào `CLAUDE.md` của dự án |
| 2 | Vẽ nháp các màn hình trên giấy: màn nào dùng hằng ngày, màn nào là cài đặt (§3) | Có danh sách màn + trường |
| 3 | Chép một file mẫu trong `docs/mau/` rồi sửa thành schema của mình (§4, §5) | File JSON mở được trong app |
| 4 | **Xem trên điện thoại trước khi viết firmware**: VP Hub → [≡] → Settings → bật Technician mode → Developer tools → Open JSON file (§8) | Giao diện đúng ý |
| 5 | Viết firmware từ mẫu `firmware/examples/vph_demo`, dùng component `vph_ble` (§9) | Build được |
| 6 | Kiểm tra kích thước và xử lý ghi (§6, §7) | Log không có cảnh báo vượt kích thước |
| 7 | Nạp, kết nối bằng VP Hub, đi hết bảng nghiệm thu (§11) | Mọi dòng đạt |

---

## 2. Khai thiết bị (INFO)

Với `vph_ble`, điền `vph_info_t`:

```c
static const char *const hdr[] = {"soil", "pump", "alarm", NULL};
const vph_info_t info = {
    .model = "growhub",        // chu thuong, khong dau, khong cach. KHONG doi sau khi phat hanh
    .fw = "1.0.0",
    .hw = "esp32c3",
    .icon = "pump",            // relay|heater|sensor|pump|light|motor|generic
    .domain = "agri",          // "agri" nong nghiep | "ind" cong nghiep  <-- BAT BUOC khai
    .hdr = hdr,                // cac truong luon gui kem moi man
    .caps = VPH_CAP_TIME,      // neu thiet bi can gio (lich, RTC)
    .name_prefix = "GROW",     // ten quang ba mac dinh: GROW-A1B2
};
```

### Chọn lĩnh vực — app dựa vào đây để chọn bộ giao diện

| Thiết bị | Khai | App vẽ |
|---|---|---|
| Tưới, bơm, nhà màng, cảm biến đất / nước / khí hậu, chuồng trại | `.domain = "agri"` | Bộ **nông nghiệp**: thanh trên và menu xanh lá, số đo và nút màu xanh lá |
| Lò, nồi hơi, dây chuyền, máy, tủ điện, đo lường nhà xưởng | `.domain = "ind"` | Bộ **công nghiệp**: thanh trên xám đậm, màu nhấn xanh dương |
| Không khai | — | App coi là công nghiệp |

App **không đoán** theo tên `model`. Khai sai thì giao diện sai màu; sửa bằng cách đổi một dòng này.

### Chọn `hdr`

`hdr` là các trường quan trọng nhất (1 số đo chính, trạng thái tải chính, báo động). `vph_ble` tự gửi kèm chúng ở mọi màn, app hiện ở thanh dưới tab khi màn đang mở không có trường đó. Tối đa 3–4 trường, vì chúng tính vào giới hạn 240 byte của **mọi** màn.

---

## 3. Chia màn hình

| Loại màn | Khai | App đặt ở đâu |
|---|---|---|
| Dùng hằng ngày (Overview, Schedule, Monitor…) | bình thường | **Tab** ở thanh trên, chữ in hoa |
| Cài đặt ít đụng tới (Modbus, ngưỡng báo động, hiệu chuẩn…) | `vph_nav_menu(screen)` | Trong **menu [≡]**, mở thành trang riêng |
| Thông tin / đổi tên / khởi động lại thiết bị | `vph_nav_menu(screen)` | Trong **menu [≡]** |
| Cài đặt chỉ dành cho người kỹ thuật (Modbus, PID, hiệu chuẩn, bảo vệ) | `vph_nav_menu(screen)` + `vph_advanced(screen)` | Trong **menu [≡]**, **chỉ hiện khi app ở chế độ Technician** |

Quy tắc:
- Màn đầu tiên là màn tổng quan, `save:"live"`. Nên có 2–4 tab; nhiều hơn thì thanh tab phải cuộn.
- Mỗi màn có icon: `vph_icon(screen, "dashboard")`.
- `save:"live"`: bấm là gửi ngay (công tắc, setpoint). `save:"batch"`: sửa nhiều ô rồi bấm Save — dùng khi các ô ràng buộc nhau (ngưỡng bật < ngưỡng tắt, giờ bật / giờ tắt).
- Tên màn viết kiểu thường (`Overview`); app tự đổi thành in hoa trên tab.
- Tối đa 16 màn (`VPH_MAX_SCREENS`).
- Không đặt tên màn là `Settings` (trùng mục Settings của app trong menu). Dùng tên nói rõ nội dung: `Alarm settings`, `Sensor setup`, `Calibration`.

### Hai chế độ người dùng của app: Standard và Technician (v1.3)

App mặc định ở chế độ **Standard** (người vận hành: công nhân, nông dân). Người kỹ thuật bật **Technician** trong Settings của app (có thể đặt PIN). Thiết bị tự khai phần nào là nâng cao bằng khóa `adv`:

| Nội dung | Khai | Standard | Technician |
|---|---|---|---|
| Số đo, bật/tắt, chế độ, lịch, ngưỡng báo động, đổi tên | bình thường | Có | Có |
| **Tham số cài đặt phần cứng, giao tiếp (Modbus, baud, địa chỉ), hiệu chuẩn, PID, bảo vệ, khởi động lại** | `vph_advanced(screen)` hoặc `vph_advanced(field)` | **Không** | Có |

- Cả một màn là nâng cao → `vph_advanced(screen)`. Chỉ vài trường trong màn → `vph_advanced(field)` cho từng trường.
- Trường `adv` bị ẩn vẫn nằm trong VALUES, vẫn dùng được trong `if` / `en`, làm `sub`, nằm trong `hdr`.
- `adv` **không phải bảo mật**, chỉ để giao diện gọn. Firmware vẫn phải kiểm tra mọi lệnh ghi (§7).
- App cũ (trước 1.4) bỏ qua khóa này và hiện hết.

---

## 4. Muốn hiện gì thì khai gì

Thứ tự trường trong schema **chính là** thứ tự trên màn hình. App chỉ gom những trường **liền nhau** cùng loại.

| Muốn hiện | Kiểu `t` | Gợi ý `w` | Kèm theo | Gọi trong firmware |
|---|---|---|---|---|
| Số đo chính, 2 ô một hàng | `num` | `tile` | `ic`, `u`, `dp`, `ro` | `vph_hint(f,"tile"); vph_icon(f,"temp");` |
| Số đo chính + chạm để xem biểu đồ | `num` | `tile,trend` | như trên | `vph_hint(f,"tile,trend");` |
| Một số thật to đầu màn | `num` | `big` hoặc `big,trend` | `ic`, `u`, `dp` | `vph_hint(f,"big,trend");` |
| Dãy số phụ nhỏ trong một thẻ | `num` / `text` | `mini` | đặt liền nhau | `vph_hint(f,"mini");` |
| Đồng hồ kim | `num` | `gauge` | `min`, `max` | `vph_hint(f,"gauge");` |
| Thời lượng "2 h 5 min" | `num` (giây) | `dur` | | `vph_hint(f,"dur");` |
| Thẻ tải chính có nhãn trạng thái + 2 nút ON/OFF | `bool` | `hero,btns` | `ic`, `sub`, `en`, `d` | `vph_hint(f,"hero,btns"); vph_sub(f,"mode");` |
| Thẻ trạng thái với chữ riêng ("Stopped / Running") | `bool` | `hero` | `opt` 2 chữ, `c` | `vph_bool_labels(f,"Stopped","Running");` |
| Công tắc thường | `bool` | (không) | | |
| Đèn báo chỉ đọc | `bool` | `led` (đỏ: `led,warn`) | `ro` | `vph_hint(f,"led,warn");` |
| Chọn chế độ, nút chiếm cả hàng, có icon | `enum` | `seg` | `opt` 3 phần tử | `vph_options_ic(...)` |
| Danh sách chọn | `enum` | (không) | `opt` | `vph_options(...)` |
| Thẻ báo động (đỏ khi có, liệt kê từng lỗi) | `flags` hoặc `bool` | `alarm` | `g` chung với nút / lý do | `vph_hint(f,"alarm"); vph_flag_labels(...)` |
| Nút trong thẻ báo động (Silence, Clear fault) | `act` | | **liền sau**, cùng `g`, có `if` | `vph_group(f,"al"); vph_show_if(f,"alarm!=0");` |
| Dòng cảnh báo vàng ("Sensor disconnected") | `bool` / `text` | `note` | `if` | `vph_hint(f,"note"); vph_show_if(f,"sok==false");` |
| Ô nhập số có nút ± | `num` | | `min`, `max`, `st` | `vph_range(f,0,100,1);` |
| Giờ / ngày / thứ trong tuần | `time` / `date` / `days` | | | |
| Ô nhập chữ | `str` | | `max` | `vph_maxlen(f,20);` |
| Chữ trạng thái chỉ đọc | `text` | | | |
| Nút lệnh | `act` | | `c` nếu nguy hiểm | `vph_confirm(f,"Start the burner?");` |
| Gom vài trường vào một thẻ có tiêu đề | bất kỳ | | `g` giống nhau, đặt liền nhau | `vph_group(f,"Status");` |
| Nhóm lặp (khung giờ, bước, kênh) | | | `rep` | `vph_repeat(screen,5,"s","Slot");` |
| Ẩn / hiện theo điều kiện | bất kỳ | | `if` | `vph_show_if(f,"src!=schedule");` |
| Khóa không cho sửa theo điều kiện | bất kỳ | | `en` + `d` giải thích | `vph_enable_if(f,"mode==manual"); vph_desc(f,"...");` |
| Chú thích nhỏ dưới trường | bất kỳ | | `d` | `vph_desc(f,"...");` |
| Chỉ hiện cho người kỹ thuật (chế độ Technician) | bất kỳ, hoặc cả màn | | `adv` | `vph_advanced(f);` |

### Chuông báo động trên thanh đầu

App tự đếm và hiện số trên chuông: mỗi bit đang bật của mọi trường `flags`, cộng mỗi trường `bool` có `alarm` (hoặc `led,warn`) đang bật. Muốn chuông đúng ở mọi tab thì đưa trường báo động vào `hdr`.

### Bắt buộc

- Nút hoặc công tắc nguy hiểm (đốt lò, chạy motor, xóa lỗi, khởi động lại) phải có `c` (câu hỏi xác nhận). Với `bool`, app chỉ hỏi khi bật.
- Trường bị khóa bằng `en` phải có `d` nói vì sao khóa.
- Chỉ dùng kiểu và gợi ý có trong bảng trên (đầy đủ: PROTOCOL §5.2, §5.4). **Không tự chế** kiểu mới ở firmware: app sẽ hiện thành chữ chỉ đọc.

---

## 5. Icon và chữ

**Icon** (dùng cho màn, trường, lựa chọn của `enum`) — chỉ dùng tên trong danh sách này; tên lạ thì không hiện icon:

`dashboard, schedule, settings, tune, info, device, temp, hum, water, soil, light, sun, fan, pump, motor, fire, heater, bolt, power, plug, speed, gauge, timer, clock, calendar, alarm, warning, mute, bell, hand, auto, sensor, wifi, ble, battery, chip, play, pause, stop, refresh, reset, check, save`

**Chữ**:
- App có 2 ngôn ngữ (English mặc định, Tiếng Việt) cho chữ **của app**. App **không dịch** chữ của thiết bị.
- Vì vậy mọi chữ firmware gửi lên — tên màn, nhãn `l`, nhóm `g`, chú thích `d`, câu hỏi `c`, nhãn `opt`, chuỗi lỗi `err` — viết **tiếng Anh**, từ ngữ chuyên nghiệp, ngắn: `Temperature`, `Setpoint`, `Alarm thresholds`, `Start the burner?`.
- Đơn vị viết chuẩn: `°C`, `%`, `bar`, `L/min`, `min`, `s`.
- `id` của trường: `[a-z0-9_]`, tối đa 16 ký tự, duy nhất trong cả thiết bị, càng ngắn càng tốt (`t`, `h`, `sp`, `al_hi`). Không bắt đầu bằng `_` (dành riêng).
- Lưu ý: vài thông báo có sẵn bên trong `vph_ble` 1.1 (như lệnh quá dài, trường không tồn tại) hiện vẫn là tiếng Việt.

---

## 6. Giới hạn kích thước (luật cứng)

| Gói | Tối đa | Vượt thì |
|---|---|---|
| INFO | 240 byte | bớt `hdr`, rút tên |
| Schema mỗi màn | 1920 byte (`vph_ble` tự cắt 4 trang × 480) | tách màn, dùng `rep` thay vì liệt kê |
| **VALUES mỗi màn, kể cả `hdr`** | **240 byte** | tách màn hoặc rút `id`. Dài hơn app **không đọc được** |
| Lệnh ghi (WRITE) | 500 byte | chia màn batch nhỏ hơn |
| `err` | 80 byte | viết ngắn |

`vph_ble` in `ESP_LOGW` lúc khởi động khi vượt. Dự án phải có unit test kiểm tra kích thước lớn nhất của từng màn (mẫu: `firmware/test_app`).

---

## 7. Xử lý ghi

- Firmware là nơi kiểm tra hợp lệ cuối cùng. Sai → trả `VPH_ERR_REJECT` kèm `err` ngắn, **giữ nguyên cấu hình cũ**. App hiện nguyên văn `err`.
- Màn `batch`: áp tất cả lên **bản sao** cấu hình → kiểm tra → hợp lệ mới lưu.
- Callback ghi chạy trong task gọi `vph_poll()`, được phép ghi NVS. Không tự làm việc nặng trong callback GATT.
- Gọi `vph_poll()` ít nhất 10 lần/giây. Trạng thái đổi do nút nhấn / cảm biến → gọi `vph_notify_now()`.
- Id dành riêng: `_time` (cần `VPH_CAP_TIME`), `_name` (lưu NVS), `_reboot` (lưu NVS ngay).

---

## 8. Xem giao diện trước khi nạp firmware

1. Chép `docs/mau/mau_nong_nghiep.json` hoặc `docs/mau/mau_cong_nghiep.json`, sửa thành thiết bị của mình. File có 3 phần: `info`, `screens`, `values` (giá trị mẫu của mọi trường, kể cả id sinh từ `rep` như `s1_en`).
2. Chép file vào điện thoại.
3. VP Hub → [≡] → **Settings** → bật **Technician mode** → **Developer tools** → **Open JSON file**.
4. Sửa file cho tới khi giao diện đúng, rồi mới chuyển từng màn thành code `vph_screen(...)`.

Thiết bị giả không kiểm tra hợp lệ — việc đó là của firmware thật.

---

## 9. Thêm `vph_ble` vào dự án

1. `main/idf_component.yml`:
   ```yaml
   dependencies:
     vph_ble:
       path: ../../../vp_hub/firmware/components/vph_ble   # dự án nằm trong D:\2026\
   ```
   Dự án ở chỗ khác: chép nguyên thư mục `vph_ble` vào `components/`, giữ file `VERSION`.
2. `main/CMakeLists.txt`: thêm `vph_ble` vào `REQUIRES`.
3. `sdkconfig.defaults`:
   ```
   CONFIG_BT_ENABLED=y
   CONFIG_BT_NIMBLE_ENABLED=y
   CONFIG_BT_BLUEDROID_ENABLED=n
   CONFIG_BT_NIMBLE_MAX_CONNECTIONS=1
   CONFIG_BT_NIMBLE_ATT_PREFERRED_MTU=512
   CONFIG_BT_NIMBLE_SECURITY_ENABLE=n
   CONFIG_ESP_MAIN_TASK_STACK_SIZE=8192
   ```
4. Gọi `nvs_flash_init()` trước `vph_init()`.
5. Chép khung từ `firmware/examples/vph_demo/main/main.c`: khai màn hình → điền VALUES → xử lý ghi → `vph_init` → vòng lặp `vph_poll`.

Khung một màn:

```c
static cJSON *build_overview(void)
{
    cJSON *s = vph_screen("overview", "Overview", "live");
    vph_icon(s, "dashboard");

    cJSON *t = vph_field(s, "soil", "Soil moisture", "num");
    vph_unit(t, "%"); vph_dp(t, 1); vph_readonly(t);
    vph_hint(t, "tile,trend"); vph_icon(t, "soil");

    cJSON *p = vph_field(s, "pump", "Pump", "bool");
    vph_hint(p, "hero,btns"); vph_icon(p, "pump");
    vph_sub(p, "mode"); vph_enable_if(p, "mode==manual");
    vph_desc(p, "Manual switching is available in Manual mode only");
    return s;
}
```

---

## 10. Lỗi hay gặp

| Thấy trên app | Nguyên nhân | Sửa |
|---|---|---|
| Không quét thấy thiết bị | Không dùng `vph_ble`, hoặc tự đổi UUID | Dùng `vph_ble`, không đổi UUID |
| Giao diện xám / xanh dương dù là thiết bị nông nghiệp | Chưa khai `.domain = "agri"` | Khai `domain` |
| Mọi số hiện `--` | VALUES vượt 240 byte, hoặc quên điền trường trong `vph_values_cb` | Xem log, tách màn / rút id |
| Trường hiện dạng `id: giá trị` | Kiểu `t` không có trong PROTOCOL | Dùng kiểu chuẩn |
| Thẻ "schema invalid" | JSON màn hỏng hoặc thiếu `id` | Sửa schema |
| Số đo không thành thẻ, chỉ là một hàng | Thiếu `w:"tile"` | Thêm gợi ý |
| Hai `tile` không nằm cùng hàng | Có trường khác chen giữa | Đặt liền nhau |
| Nút Silence nằm ngoài thẻ báo động | Không cùng `g`, hoặc không liền sau trường `alarm` | Cùng `g`, đặt ngay sau |
| Màn cài đặt chiếm một tab | Thiếu `vph_nav_menu` | Thêm |
| Chuông không báo ở tab khác | Trường báo động không nằm trong `hdr` | Thêm vào `hdr` |
| "No response from the device" | Không gọi `vph_poll()` đủ nhanh, hoặc callback ghi chạy lâu hơn 1 giây | Sửa vòng lặp |

---

## 11. Bảng nghiệm thu trước khi phát hành

- [ ] `model` đã chốt, ghi trong `CLAUDE.md` của dự án.
- [ ] Đã khai `.domain` đúng lĩnh vực; mở app thấy đúng bộ màu.
- [ ] Mọi màn có `ic`; màn cài đặt và màn thông tin thiết bị có `vph_nav_menu`.
- [ ] Màn đầu có số đo chính dạng `tile` / `big`, tải chính dạng `hero`, báo động dạng `alarm`.
- [ ] Trường báo động nằm trong `hdr`; chuông hiện đúng số.
- [ ] Tham số phần cứng / giao tiếp / hiệu chuẩn / PID / bảo vệ đã đánh `adv`: mở app ở **Standard mode không thấy tham số kỹ thuật**, bật Technician thì thấy đủ.
- [ ] Mọi nút nguy hiểm có `c`; mọi trường khóa bằng `en` có `d`.
- [ ] Mọi chữ gửi lên là tiếng Anh.
- [ ] Log khởi động không có cảnh báo kích thước; có unit test kích thước.
- [ ] Ghi sai giá trị → app hiện đúng `err`, cấu hình cũ còn nguyên.
- [ ] Đổi tên (`_name`), khởi động lại (`_reboot`), ngắt nguồn rồi cấp lại: app tự kết nối lại.
- [ ] Đã thử bằng VP Hub trên điện thoại thật.

---

## 12. Khi nào PHẢI sửa app VP Hub

Chỉ khi cần **kiểu dữ liệu, gợi ý hiển thị, icon hoặc lĩnh vực mới** dùng chung được cho nhiều thiết bị. Khi đó: sửa `PROTOCOL.md` trước (ghi lý do ở §12), thêm vào app, **giữ tương thích** với thiết bị cũ. Không bao giờ thêm màn hình riêng cho một model.

---

## 13. Đoạn chép sẵn vào `CLAUDE.md` của dự án mới

```markdown
## App điện thoại
- KHÔNG làm app Android riêng. Thiết bị dùng giao thức BLE chung **VPH v1**: đọc
  `D:\2026\vp_hub\docs\QUY_TAC_THIET_BI_MOI.md` (quy chuẩn) và `D:\2026\vp_hub\docs\PROTOCOL.md`
  trước khi làm phần BLE.
- Dùng component `vph_ble` (D:\2026\vp_hub\firmware\components\vph_ble), bắt đầu từ mẫu
  `vp_hub/firmware/examples/vph_demo`.
- model = `<điền>`; lĩnh vực `.domain = "<agri hoặc ind>"`; tên quảng bá mặc định `<TÊN>-XXXX`.
- Thiết kế schema bằng file JSON (mẫu `vp_hub/docs/mau/`), xem trên VP Hub (Settings → Technician mode → Developer tools → Open JSON file)
  trước khi viết firmware.
- Mọi chữ gửi lên app (nhãn, nhóm, chú thích, câu hỏi, lỗi) viết tiếng Anh.
- Tham số phần cứng, giao tiếp, hiệu chuẩn, PID, bảo vệ → đánh `vph_advanced(...)` (chỉ hiện ở chế độ Technician).
- Schema mỗi màn ≤ 1920 byte, mỗi VALUES (kể cả hdr) ≤ 240 byte, có test kiểm tra.
- Kiểm tra bằng app VP Hub trên điện thoại (cài `vp_hub/release/VPHub_*.apk`), không viết app mới.
```
