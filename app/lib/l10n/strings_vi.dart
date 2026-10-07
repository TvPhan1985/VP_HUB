/// Moi chu hien thi trong app (tieng Viet co dau) gom o day
class S {
  static const appName = 'VP Hub';

  // ----- Chung -----
  static const ok = 'Đồng ý';
  static const cancel = 'Hủy';
  static const save = 'Lưu';
  static const retry = 'Thử lại';
  static const back = 'Quay lại';
  static const stay = 'Ở lại';
  static const discard = 'Bỏ thay đổi';
  static const confirmTitle = 'Xác nhận';
  static const noData = '--';

  // ----- Loi / thong bao tu transport -----
  static const badInfo = 'Thiết bị không trả lời đúng giao thức VPH (INFO sai)';
  static const deviceRefused = 'Thiết bị từ chối lệnh';
  static const noResponse = 'Thiết bị không phản hồi';
  static const linkLost = 'Mất kết nối';
  static const notConnected = 'Chưa kết nối với thiết bị';
  static const emptySchema = 'Thiết bị không gửi màn hình nào';
  static const kilnNotAccepted = 'Thiết bị không nhận giá trị';
  static const unsupportedDevice = 'Thiết bị này không dùng giao thức mà VP Hub hỗ trợ';
  static const saved = 'Đã lưu';
  static const schemaReloaded = 'Đã đọc lại schema từ thiết bị';
  static String writeTooLong(int len, int max) =>
      'Lệnh quá dài ($len byte, tối đa $max). Hãy lưu bớt thay đổi mỗi lần.';
  static String sendFailed(Object e) => 'Gửi lỗi: ${_short(e)}';
  static String selectFailed(Object e) => 'Không đổi được màn hình: ${_short(e)}';
  static String sent(String label) => 'Đã gửi: $label';
  static String turnedOn(String label) => 'Đã bật $label';
  static String turnedOff(String label) => 'Đã tắt $label';
  static String changedTo(String label, String value) => '$label: $value';

  static const protoDemo = 'Thiết bị mẫu (không có phần cứng)';
  static const protoKiln = 'Đời cũ: lò nung (adapter kiln_v0)';
  static const protoC3 = 'Đời cũ: relay C3 (adapter c3relay_v1)';

  // ----- Demo -----
  static const demoTitle = 'Thiết bị mẫu';
  static const demoHint = 'Thiết bị giả để xem giao diện mà không cần phần cứng. Số liệu tự đổi nhẹ mỗi giây, lệnh ghi luôn thành công.';
  static const demoRelay = 'Relay mẫu';
  static const demoRelaySub = 'Tổng quan + màn Lịch có khung giờ lặp';
  static const demoAll = 'Đủ mọi kiểu dữ liệu';
  static const demoAllSub = 'Mọi kiểu, mọi gợi ý hiển thị, điều kiện hiện/khóa, một kiểu lạ';
  static const openJson = 'Mở file JSON';
  static const openJsonSub = 'Chọn file demo trong bộ nhớ điện thoại để thử schema của thiết bị mới';
  static const demoNoScreens = 'File không đúng định dạng: thiếu mảng "screens"';
  static String demoBadJson(String e) => 'File JSON lỗi: $e';
  static String demoOpenFailed(Object e) => 'Không mở được file: ${_short(e)}';

  // ----- Man Quet -----
  static const scan = 'Quét';
  static const stopScan = 'Dừng';
  static const scanning = 'Đang quét thiết bị...';
  static const noDevices = 'Chưa thấy thiết bị nào quanh đây.\nBấm "Quét" để tìm lại.';
  static const knownDevices = 'Thiết bị đã dùng';
  static const nearby = 'Thiết bị gần đây';
  static const seenNow = 'Đang ở quanh đây';
  static const scanEmptyTitle = 'Chưa thấy thiết bị nào';
  static const scanEmptyHint = 'Bật nguồn thiết bị, để điện thoại ở gần rồi bấm "Quét".';
  static const tagVph = 'VPH';
  static const tagLegacy = 'Đời cũ';
  static const forget = 'Xóa khỏi danh sách';
  static const btOff = 'Bluetooth đang tắt. Hãy bật Bluetooth để quét thiết bị.';
  static const btTurnOn = 'Bật Bluetooth';
  static const permMissing =
      'VP Hub cần quyền "Thiết bị ở gần" (Bluetooth) để quét và kết nối. Hãy cấp quyền trong cài đặt của app.';
  static const openSettings = 'Mở cài đặt';
  static const menuDemo = 'Thiết bị mẫu';
  static const menuAuto = 'Tự kết nối thiết bị gần nhất khi mở app';
  static const menuAbout = 'Giới thiệu';
  static String scanFailed(Object e) => 'Không quét được: ${_short(e)}';
  static String rssi(int r) => '$r dBm';

  // ----- Man Thiet bi -----
  static const connecting = 'Đang kết nối...';
  static const linkOk = 'Đã kết nối';
  static const linkRetry = 'Đang kết nối lại…';
  static const onCaps = 'BẬT';
  static const offCaps = 'TẮT';
  static const alarmNone = 'Không có báo động';
  static const showTrend = 'Chạm để xem biểu đồ';
  static String durDH(int d, int h) => '$d ngày $h giờ';
  static String durHM(int h, int m) => '$h giờ $m phút';
  static String durMS(int m, int s) => '$m phút $s giây';
  static const loadingSchema = 'Đang đọc giao diện từ thiết bị...';
  static const connectFailed = 'Không kết nối được';
  static const lostRetrying = 'Mất kết nối, đang thử lại…';
  static const lostGiveUp = 'Mất kết nối với thiết bị.';
  static const menuInfo = 'Thông tin thiết bị';
  static const menuDisconnect = 'Ngắt kết nối';
  static const menuReload = 'Đọc lại schema';
  static const needUpdate = 'Thiết bị dùng giao thức mới hơn. Cần cập nhật app VP Hub.';
  static const noScreens = 'Thiết bị không có màn hình nào';
  static const schemaError = 'Schema của màn hình này bị lỗi, không vẽ được';
  static const unsavedTitle = 'Có thay đổi chưa lưu';
  static String unsavedBody(int n) => 'Màn hình này có $n thay đổi chưa lưu xuống thiết bị.';
  static String batchChanges(int n) => 'Có $n thay đổi';
  static const noLimit = 'Không giới hạn';
  static const flagsNone = 'Bình thường';
  static String flagBit(int i) => 'Cảnh báo bit $i';
  static const repDefault = 'Mục';
  static const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const invalidNumber = 'Phải là số';
  static String outOfRange(String min, String max) => 'Phải từ $min đến $max';
  static String atLeast(String min) => 'Phải từ $min trở lên';
  static String atMost(String max) => 'Tối đa $max';
  static String maxLen(int n) => 'Tối đa $n ký tự';
  static const notEmpty = 'Không được để trống';
  static const notSet = 'Chưa đặt';
  static const pickDate = 'Chọn ngày';
  static const pickTime = 'Chọn giờ';
  static const trendEmpty = 'Đang gom dữ liệu biểu đồ...';
  static const on = 'Bật';
  static const off = 'Tắt';

  // ----- Thong tin thiet bi -----
  static const infoName = 'Tên';
  static const infoModel = 'Model';
  static const infoFw = 'Firmware';
  static const infoHw = 'Phần cứng';
  static const infoPv = 'Phiên bản giao thức';
  static const infoProto = 'Giao thức thật';
  static const infoScreens = 'Số màn hình';
  static const infoSch = 'Mã schema';
  static const infoCaps = 'Khả năng';
  static const infoSchemaSrc = 'Nguồn schema';
  static const fromCache = 'Cache trong app';
  static const fromDevice = 'Đọc từ thiết bị';
  static const infoMtu = 'MTU';
  static const infoMaxValues = 'Gói VALUES lớn nhất';
  static const infoPackets = 'Số gói VALUES đã nhận';
  static const infoBad = 'Số gói hỏng (bị cắt)';
  static const valuesTooBig = 'Gói VALUES vượt 240 byte: firmware vi phạm PROTOCOL §8, cần tách màn hình hoặc rút ngắn id.';
  static const badPacketsWarn = 'Có gói VALUES hỏng: có thể VALUES quá dài so với MTU.';
  static String bytes(int n) => '$n byte';

  // ----- Gioi thieu -----
  static const aboutBody =
      'Một app cho mọi thiết bị ESP32 của Phận: quét, đọc, điều khiển qua BLE. Giao diện tự vẽ từ schema do thiết bị gửi lên (giao thức VPH v1.1), nên thiết bị mới không cần app mới.';
  static const aboutSupported = 'Thiết bị hỗ trợ';
  static const aboutSupportedList =
      '• Mọi thiết bị nói giao thức VPH v1\n• Bộ relay ESP32-C3 (firmware cũ)\n• Bộ điều khiển lò nung MAX31856 (firmware cũ)';
  static String version(String v) => 'Phiên bản $v';

  static String _short(Object e) {
    var s = e.toString();
    if (s.startsWith('Exception: ')) s = s.substring(11);
    return s.length > 120 ? '${s.substring(0, 120)}...' : s;
  }
}
