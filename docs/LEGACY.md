# LEGACY — Đọc 2 thiết bị cũ khi chưa nạp lại firmware

Hai thiết bị hiện tại **chưa** nói giao thức VPH. Để app VP Hub dùng được ngay (Phần A của PLAN), app có 2 **bộ chuyển đổi** (adapter). Mỗi adapter làm thiết bị cũ "trông giống" thiết bị VPH: cung cấp INFO, danh sách SCHEMA, VALUES, nhận lệnh ghi và trả kết quả, theo **đúng model dữ liệu VPH**. Giao diện vẫn là bộ vẽ chung, không có màn hình riêng cho từng thiết bị.

Adapter chỉ dành cho 2 thiết bị này. **Thiết bị mới không bao giờ được thêm adapter** — phải làm firmware theo `PROTOCOL.md`.

Sau khi 2 firmware được chuyển sang VPH (Phần B), adapter vẫn giữ lại cho các board chưa nạp lại.

Mã nguồn gốc để đối chiếu:
- Relay: `D:\2026\c3_relay_ctrl` (`docs/SPEC.md` §6, §7; `firmware/components/ble_svc/ble_svc.c`; `app/lib/protocol/*.dart`)
- Lò nung: `D:\2026\Temp_Max31856-main` (`main/ble_ui.c`; `app/lib/core/ble/*`, `app/lib/core/schema/schema.dart`)

---

## L1. Bộ relay ESP32-C3 — adapter `c3relay_v1`

**Nhận diện:** UUID dịch vụ `6e400001-c3a1-4b2c-9d10-0000000000a0`. Tên trong scan response (`C3-RELAY-XXXX`).

| Char | UUID | Thuộc tính |
|---|---|---|
| STATUS | `6e400002-c3a1-4b2c-9d10-0000000000a0` | Read, Notify 1 s |
| CONFIG | `6e400003-c3a1-4b2c-9d10-0000000000a0` | Read, Write (ghi từng phần được) |
| CMD | `6e400004-c3a1-4b2c-9d10-0000000000a0` | Write |
| RESULT | `6e400005-c3a1-4b2c-9d10-0000000000a0` | Notify `{"ok":true}` / `{"ok":false,"err":"..."}` (không có `q`) |

MTU 512 (firmware đã đặt).

**INFO giả lập:** `{"proto":"vph","pv":1,"model":"c3relay","name":<STATUS.name>,"fw":<STATUS.fw>,"hw":"esp32c3","n":4,"hdr":["t","h","out","mode","alarm"],"caps":["time"],"icon":"relay"}`

**Schema:** lưu sẵn trong app ở `assets/legacy/c3relay_v1.json` theo **đúng định dạng VPH** (4 màn hình dưới đây). Đọc schema này qua cùng parser như thiết bị thật.

**Đọc dữ liệu:** STATUS (notify) và CONFIG (đọc 1 lần khi kết nối, đọc lại sau mỗi lần lưu thành công) → gộp thành một map VALUES phẳng theo bảng ánh xạ.

| Màn hình (save) | Id VPH | Kiểu | Nguồn đọc | Cách ghi |
|---|---|---|---|---|
| **Tổng quan** (live) | `t`, `h` | num °C/% ro, `t` có `w:trend` | STATUS `t`,`h` | — |
| | `ec`,`sal`,`tds` | num ro | STATUS | — |
| | `sok` | bool `w:led` ro "Cảm biến" | STATUS `sok` | — |
| | `tok` | bool `w:led` ro "Có giờ" | STATUS `tok` | — |
| | `time` | text "Giờ thiết bị" | STATUS `time` | — |
| | `mode` | enum manual/auto | STATUS `mode` | CMD `{"cmd":"mode","v":v}` |
| | `out` | bool "Relay", `en:"mode==manual"` | STATUS `out` | CMD `{"cmd":"out","v":0/1}` |
| | `alarm` | flags (4 bit, SPEC §5) | STATUS `alarm` | — |
| | `muted` | bool `w:led` ro "Đã tắt còi" | STATUS `muted` | — |
| | `silence` | act "Tắt còi", `if:"alarm!=0"` | — | CMD `{"cmd":"silence"}` |
| | `up` | num ro "Thời gian chạy" (giây) | STATUS `up` | — |
| **Lịch & tự động** (batch) | `src` | enum schedule/sensor/both (Lịch/Cảm biến/Kết hợp) | CONFIG `auto.src` | CONFIG `{"auto":{"src":v}}` |
| | `date_from`,`date_to` | date `nul:1` | `auto.dateFrom/dateTo` | `{"auto":{"dateFrom":v}}` |
| | `s{i}_en/days/on/off` (rep n=5, pfx `s`) | bool/days/time/time | `auto.slots[i-1]` = `[en,days,"on","off"]` (thiếu thì coi như `[0,127,"00:00","00:00"]`) | **luôn gửi cả mảng 5 khung** `{"auto":{"slots":[[...],...]}}` |
| | `sen_type` | enum hum/temp, `if:"src!=schedule"` | `auto.sensor.type` | `{"auto":{"sensor":{...đủ 4 khóa}}}` |
| | `sen_act` | enum low/high ("Bật khi thấp"/"Bật khi cao") | `auto.sensor.action` | như trên |
| | `on_at`,`off_at` | num | `auto.sensor.onAt/offAt` | như trên |
| **Nâng cao** (batch) | `mb_addr`,`mb_baud`,`mb_fc`,`mb_start`,`mb_count`,`mb_idx_h`,`mb_idx_t`,`mb_scale`,`mb_period` | num (addr 1–247) | `modbus.*` | `{"modbus":{...đủ khóa}}` |
| | `al_en` | bool | `alarm.en` | `{"alarm":{...đủ khóa}}` |
| | `al_t_lo`,`al_t_hi`,`al_h_lo`,`al_h_hi` | num | `alarm.tLo/tHi/hLo/hHi` | như trên |
| **Thiết bị** (live) | `_name` | str max 20 | STATUS `name` | CONFIG `{"name":v}` |
| | `fw` | text | STATUS `fw` | — |
| | `_reboot` | act, `c:"Khởi động lại thiết bị?"` | — | CMD `{"cmd":"reboot"}` |

- `_time` → CMD `{"cmd":"time","epoch":v}` (gửi ngay khi kết nối, như app cũ).
- Lệnh batch: gom tất cả trường đổi trong màn hình thành **một** JSON CONFIG một phần (gửi đủ object con, không gửi lẻ một khóa của `sensor`/`modbus`/`alarm`), kiểm tra ≤ 500 byte, ghi CONFIG.
- RESULT cũ không có `q`: adapter chỉ cho **một lệnh đang chờ** tại một thời điểm (hàng đợi), RESULT đến thì gán cho lệnh đó.
- Kiểm tra trước khi gửi giống app cũ (`app/lib/protocol/app_config.dart`): `low` cần `on_at < off_at`, `high` cần `on_at > off_at`, giờ `HH:MM`, `date_from ≤ date_to`. Firmware vẫn kiểm tra lại.
- Đối chiếu với app cũ để không bỏ sót chức năng (3 tab: Tổng quan, Lịch & tự động, Nâng cao).

---

## L2. Bộ điều khiển lò nung MAX31856 — adapter `kiln_v0`

**Nhận diện:** UUID dịch vụ `6a1e0001-b5c3-4a4d-8a1e-5b6c7d8e9f00`. Tên quảng bá trong firmware là `Temp_Control` (README cũ ghi `LoNung`/`KilnCtrl`; **không lọc theo tên**).

| Char | UUID | Thuộc tính |
|---|---|---|
| SCHEMA | `6a1e0002-…-5b6c7d8e9f00` | Read |
| VALUES | `6a1e0003-…` | Read, Notify 1 s |
| WRITE | `6a1e0004-…` | Write `{"id":"x","value":v}` |
| SELECT | `6a1e0005-…` | Write 1 byte |

Không có INFO, không có RESULT. MTU app cũ xin 247 (VALUES ≤ 240 byte).

Giao thức này **gần như là VPH v0**, nên adapter rất mỏng:
- **INFO giả lập:** `{"proto":"vph","pv":1,"model":"kiln31856","name":<tên quảng bá>,"fw":"?","n":<đếm được>,"hdr":["pv","sv","running","sensor_ok","safety_latched"],"icon":"heater"}`.
- **Schema:** đọc thật từ thiết bị: ghi SELECT = i, đọc SCHEMA, dừng khi gặp `{}` (tối đa 16). Parser VPH đã nhận khóa dài (`title`, `fields`, `label`, `type`, `readonly`, `repeat.count/prefix/fields`) và kiểu `float` = `num`.
- **Vá schema** (chỉ trong adapter, áp sau khi đọc):
  - Màn `operation`: `save:"live"`; `pv` thêm `w:"big"` và `w:"trend"`; thêm trường `program_info` (text, `if:"program_running==true"`), `safety_reason` (text, `if:"safety_latched==true"`) và `safety_clear` (act "Xóa lỗi", `if:"safety_latched==true"`, `c:"Xóa khóa an toàn và cho lò chạy lại?"`).
  - `running`, `program_running` thêm `c` xác nhận khi bật (app cũ có hỏi lại trước khi đốt lò).
  - `autotune_run`, `autotune_apply`: giữ `bool` nhưng thêm `c` xác nhận.
  - Màn `program_steps`: thêm `cnt:"program_step_count"` cho khối lặp (giá trị này nằm ở màn `program`, adapter nhớ giá trị gần nhất của nó).
  - Mọi màn hình khác `save:"live"` (giống hành vi cũ).
- **Ghi:** `{"id":X,"v":v}` → `{"id":X,"value":v}`. Không có RESULT nên adapter trả `ok` khi lệnh ghi BLE thành công, rồi **xác nhận** bằng cách xem VALUES lần kế (≤ 2 s) có đúng giá trị không; không đúng thì báo "Thiết bị không nhận giá trị".
- **Không có `_time`, `_name`, `_reboot`** → ẩn các mục tương ứng.
- Mất: biểu đồ "profile chương trình" (ProgramProfileChart) của app cũ. Ghi vào SPEC §11 như một gợi ý hiển thị tương lai (`w:"profile"`), **không** làm màn hình riêng.
