/// Ngon ngu hien thi cua app. Mac dinh tieng Anh; nguoi dung doi trong menu he thong.
class Lang {
  static const en = 'en';
  static const vi = 'vi';
  static String code = en;
  static bool get isVi => code == vi;

  /// Ten ngon ngu, viet bang chinh ngon ngu do
  static String nameOf(String c) => c == vi ? 'Tiếng Việt' : 'English';
}

/// Chon chu theo ngon ngu dang dung
String tr(String en, String vi) => Lang.isVi ? vi : en;

/// Moi chu hien thi trong app gom o day, moi chu co ban tieng Anh va tieng Viet
class S {
  static const appName = 'VP Hub';
  static String get appTagline => tr('BLE Device Manager', 'Quản lý thiết bị BLE');

  // ----- Chung -----
  static String get ok => tr('OK', 'Đồng ý');
  static String get cancel => tr('Cancel', 'Hủy');
  static String get save => tr('Save', 'Lưu');
  static String get retry => tr('Retry', 'Thử lại');
  static String get back => tr('Back', 'Quay lại');
  static String get stay => tr('Stay', 'Ở lại');
  static String get discard => tr('Discard', 'Bỏ thay đổi');
  static String get close => tr('Close', 'Đóng');
  static String get confirmTitle => tr('Confirm', 'Xác nhận');
  static const noData = '--';

  // ----- Loi / thong bao tu transport -----
  static String get badInfo => tr('The device did not answer with a valid VPH INFO packet',
      'Thiết bị không trả lời đúng giao thức VPH (INFO sai)');
  static String get deviceRefused => tr('Command rejected by the device', 'Thiết bị từ chối lệnh');
  static String get noResponse => tr('No response from the device', 'Thiết bị không phản hồi');
  static String get linkLost => tr('Disconnected', 'Mất kết nối');
  static String get notConnected => tr('Not connected to the device', 'Chưa kết nối với thiết bị');
  static String get emptySchema => tr('The device did not send any screen', 'Thiết bị không gửi màn hình nào');
  static String get kilnNotAccepted => tr('Value not accepted by the device', 'Thiết bị không nhận giá trị');
  static String get unsupportedDevice => tr('This device uses a protocol that VP Hub does not support',
      'Thiết bị này không dùng giao thức mà VP Hub hỗ trợ');
  static String get saved => tr('Saved', 'Đã lưu');
  static String get schemaReloaded => tr('Schema reloaded from the device', 'Đã đọc lại schema từ thiết bị');
  static String writeTooLong(int len, int max) => tr(
      'Command too long ($len bytes, max $max). Save fewer changes at a time.',
      'Lệnh quá dài ($len byte, tối đa $max). Hãy lưu bớt thay đổi mỗi lần.');
  static String sendFailed(Object e) => tr('Send failed: ${_short(e)}', 'Gửi lỗi: ${_short(e)}');
  static String selectFailed(Object e) =>
      tr('Could not switch screen: ${_short(e)}', 'Không đổi được màn hình: ${_short(e)}');
  static String sent(String label) => tr('Sent: $label', 'Đã gửi: $label');
  static String turnedOn(String label) => tr('$label turned on', 'Đã bật $label');
  static String turnedOff(String label) => tr('$label turned off', 'Đã tắt $label');
  static String changedTo(String label, String value) => '$label: $value';

  static String get protoDemo => tr('Demo device (no hardware)', 'Thiết bị mẫu (không có phần cứng)');
  static String get protoKiln =>
      tr('Legacy: kiln controller (kiln_v0 adapter)', 'Đời cũ: lò nung (adapter kiln_v0)');
  static String get protoC3 => tr('Legacy: C3 relay (c3relay_v1 adapter)', 'Đời cũ: relay C3 (adapter c3relay_v1)');

  // ----- Demo -----
  static String get demoTitle => tr('Demo Devices', 'Thiết bị mẫu');
  static String get demoHint => tr(
      'Simulated devices for exploring the interface without hardware. Readings drift slightly every second and every write succeeds.',
      'Thiết bị giả để xem giao diện mà không cần phần cứng. Số liệu tự đổi nhẹ mỗi giây, lệnh ghi luôn thành công.');
  static String get demoRelay => tr('Demo Relay', 'Relay mẫu');
  static String get demoRelaySub => tr('Overview, schedule with repeating slots, 2 settings screens in the drawer',
      'Tổng quan, Lịch có khung giờ lặp, 2 màn cài đặt trong menu');
  static String get demoAll => tr('All Data Types', 'Đủ mọi kiểu dữ liệu');
  static String get demoAllSub => tr('Every type and display hint, show/enable conditions, one unknown type',
      'Mọi kiểu, mọi gợi ý hiển thị, điều kiện hiện/khóa, một kiểu lạ');
  static String get openJson => tr('Open JSON File', 'Mở file JSON');
  static String get openJsonSub => tr('Pick a demo file from phone storage to try the schema of a new device',
      'Chọn file demo trong bộ nhớ điện thoại để thử schema của thiết bị mới');
  static String get demoNoScreens =>
      tr('Invalid file: the "screens" array is missing', 'File không đúng định dạng: thiếu mảng "screens"');
  static String demoBadJson(String e) => tr('Invalid JSON file: $e', 'File JSON lỗi: $e');
  static String demoOpenFailed(Object e) =>
      tr('Could not open the file: ${_short(e)}', 'Không mở được file: ${_short(e)}');

  // ----- Man Quet -----
  static String get scan => tr('Scan', 'Quét');
  static String get stopScan => tr('Stop', 'Dừng');
  static String get scanning => tr('Scanning for devices...', 'Đang quét thiết bị...');
  static String get noDevices => tr('No other devices nearby.\nTap "Scan" to search again.',
      'Chưa thấy thiết bị nào khác quanh đây.\nBấm "Quét" để tìm lại.');
  static String get knownDevices => tr('Saved Devices', 'Thiết bị đã dùng');
  static String get nearby => tr('Nearby Devices', 'Thiết bị gần đây');
  static String get seenNow => tr('In range', 'Đang ở quanh đây');
  static String get scanEmptyTitle => tr('No devices found', 'Chưa thấy thiết bị nào');
  static String get scanEmptyHint => tr('Power on the device, keep the phone close, then tap "Scan".',
      'Bật nguồn thiết bị, để điện thoại ở gần rồi bấm "Quét".');
  static const tagVph = 'VPH';
  static String get tagLegacy => tr('Legacy', 'Đời cũ');
  static String get forget => tr('Remove from list', 'Xóa khỏi danh sách');
  static String get btOff => tr('Bluetooth is off. Turn on Bluetooth to scan for devices.',
      'Bluetooth đang tắt. Hãy bật Bluetooth để quét thiết bị.');
  static String get btTurnOn => tr('Turn On Bluetooth', 'Bật Bluetooth');
  static String get permMissing => tr(
      'VP Hub needs the "Nearby devices" (Bluetooth) permission to scan and connect. Grant it in the app settings.',
      'VP Hub cần quyền "Thiết bị ở gần" (Bluetooth) để quét và kết nối. Hãy cấp quyền trong cài đặt của app.');
  static String get openSettings => tr('Open Settings', 'Mở cài đặt');
  static String get menuDemo => tr('Demo Devices', 'Thiết bị mẫu');
  static String get menuAuto => tr('Auto-connect on Launch', 'Tự kết nối khi mở app');
  static String get menuAbout => tr('About', 'Giới thiệu');
  static String get btReady => tr('Bluetooth ready', 'Bluetooth sẵn sàng');
  static String get btOffShort => tr('Bluetooth off', 'Bluetooth đang tắt');
  static String scanFailed(Object e) => tr('Scan failed: ${_short(e)}', 'Không quét được: ${_short(e)}');
  static String rssi(int r) => '$r dBm';

  // ----- Menu he thong (Navigation Drawer) -----
  static String get openMenu => tr('Open menu', 'Mở menu');
  static String get secDevices => tr('Devices', 'Thiết bị');
  static String get secDevice => tr('Device', 'Thiết bị');
  static String get secApp => tr('App Settings', 'Cài đặt ứng dụng');
  static String get secSupport => tr('Support', 'Hỗ trợ');
  static String get menuDeviceList => tr('Device List', 'Danh sách thiết bị');
  static String get menuTheme => tr('Theme', 'Giao diện');
  static String get themeSystem => tr('System default', 'Theo hệ thống');
  static String get themeLight => tr('Light', 'Sáng');
  static String get themeDark => tr('Dark', 'Tối');
  static String get menuLanguage => tr('Language', 'Ngôn ngữ');
  static String get on => tr('On', 'Bật');
  static String get off => tr('Off', 'Tắt');

  // ----- Man Thiet bi -----
  static String get connecting => tr('Connecting...', 'Đang kết nối...');
  static String get linkOk => tr('Connected', 'Đã kết nối');
  static String get linkRetry => tr('Reconnecting…', 'Đang kết nối lại…');
  static String get onCaps => tr('ON', 'BẬT');
  static String get offCaps => tr('OFF', 'TẮT');
  static String get alarmNone => tr('No active alarms', 'Không có báo động');
  static String get alarmsTitle => tr('Active Alarms', 'Báo động đang bật');
  static String get alarmsTooltip => tr('Alarms', 'Báo động');
  static String get showTrend => tr('Tap to show the trend chart', 'Chạm để xem biểu đồ');
  static String durDH(int d, int h) => tr('$d d $h h', '$d ngày $h giờ');
  static String durHM(int h, int m) => tr('$h h $m min', '$h giờ $m phút');
  static String durMS(int m, int s) => tr('$m min $s s', '$m phút $s giây');
  static String get loadingSchema =>
      tr('Loading the interface from the device...', 'Đang đọc giao diện từ thiết bị...');
  static String get connectFailed => tr('Connection failed', 'Không kết nối được');
  static String get lostRetrying => tr('Connection lost, reconnecting…', 'Mất kết nối, đang thử lại…');
  static String get lostGiveUp => tr('Connection to the device was lost.', 'Mất kết nối với thiết bị.');
  static String get menuInfo => tr('Device Information', 'Thông tin thiết bị');
  static String get menuDisconnect => tr('Disconnect', 'Ngắt kết nối');
  static String get menuReload => tr('Reload Schema', 'Đọc lại schema');
  static String get needUpdate => tr('This device uses a newer protocol. Please update VP Hub.',
      'Thiết bị dùng giao thức mới hơn. Cần cập nhật app VP Hub.');
  static String get noScreens => tr('The device has no screens', 'Thiết bị không có màn hình nào');
  static String get schemaError => tr('The schema of this screen is invalid and cannot be rendered',
      'Schema của màn hình này bị lỗi, không vẽ được');
  static String get unsavedTitle => tr('Unsaved changes', 'Có thay đổi chưa lưu');
  static String unsavedBody(int n) => tr(
      n == 1
          ? 'This screen has 1 change not yet saved to the device.'
          : 'This screen has $n changes not yet saved to the device.',
      'Màn hình này có $n thay đổi chưa lưu xuống thiết bị.');
  static String batchChanges(int n) => tr(n == 1 ? '1 change' : '$n changes', 'Có $n thay đổi');
  static String get noLimit => tr('No limit', 'Không giới hạn');
  static String get flagsNone => tr('Normal', 'Bình thường');
  static String flagBit(int i) => tr('Alarm bit $i', 'Cảnh báo bit $i');
  static String get repDefault => tr('Item', 'Mục');
  static List<String> get dayLabels => Lang.isVi
      ? const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
      : const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static String get invalidNumber => tr('Enter a number', 'Phải là số');
  static String outOfRange(String min, String max) => tr('Must be between $min and $max', 'Phải từ $min đến $max');
  static String atLeast(String min) => tr('Must be at least $min', 'Phải từ $min trở lên');
  static String atMost(String max) => tr('Must be at most $max', 'Tối đa $max');
  static String maxLen(int n) => tr('Up to $n characters', 'Tối đa $n ký tự');
  static String get notEmpty => tr('Must not be empty', 'Không được để trống');
  static String get notSet => tr('Not set', 'Chưa đặt');
  static String get pickDate => tr('Select date', 'Chọn ngày');
  static String get pickTime => tr('Select time', 'Chọn giờ');
  static String get trendEmpty => tr('Collecting chart data...', 'Đang gom dữ liệu biểu đồ...');

  // ----- Thong tin thiet bi -----
  static String get infoName => tr('Name', 'Tên');
  static const infoModel = 'Model';
  static const infoFw = 'Firmware';
  static String get infoHw => tr('Hardware', 'Phần cứng');
  static String get infoPv => tr('Protocol version', 'Phiên bản giao thức');
  static String get infoProto => tr('Transport', 'Giao thức thật');
  static String get infoScreens => tr('Screens', 'Số màn hình');
  static String get infoSch => tr('Schema ID', 'Mã schema');
  static String get infoCaps => tr('Capabilities', 'Khả năng');
  static String get infoSchemaSrc => tr('Schema source', 'Nguồn schema');
  static String get fromCache => tr('App cache', 'Cache trong app');
  static String get fromDevice => tr('Read from device', 'Đọc từ thiết bị');
  static const infoMtu = 'MTU';
  static String get infoMaxValues => tr('Largest VALUES packet', 'Gói VALUES lớn nhất');
  static String get infoPackets => tr('VALUES packets received', 'Số gói VALUES đã nhận');
  static String get infoBad => tr('Corrupt (truncated) packets', 'Số gói hỏng (bị cắt)');
  static String get valuesTooBig => tr(
      'A VALUES packet exceeds 240 bytes: the firmware violates PROTOCOL §8. Split the screen or shorten the ids.',
      'Gói VALUES vượt 240 byte: firmware vi phạm PROTOCOL §8, cần tách màn hình hoặc rút ngắn id.');
  static String get badPacketsWarn => tr('Corrupt VALUES packets received: VALUES may be too long for the MTU.',
      'Có gói VALUES hỏng: có thể VALUES quá dài so với MTU.');
  static String bytes(int n) => tr('$n bytes', '$n byte');

  // ----- Gioi thieu -----
  static String get aboutBody => tr(
      'One app for every ESP32 device: scan, monitor and control over BLE. The interface is rendered from the schema sent by the device (VPH protocol v1.1), so a new device needs no new app.',
      'Một app cho mọi thiết bị ESP32: quét, đọc, điều khiển qua BLE. Giao diện tự vẽ từ schema do thiết bị gửi lên (giao thức VPH v1.1), nên thiết bị mới không cần app mới.');
  static String get aboutSupported => tr('Supported devices', 'Thiết bị hỗ trợ');
  static String get aboutSupportedList => tr(
      '• Any device that speaks the VPH v1 protocol\n• ESP32-C3 relay controller (legacy firmware)\n• MAX31856 kiln controller (legacy firmware)',
      '• Mọi thiết bị nói giao thức VPH v1\n• Bộ relay ESP32-C3 (firmware cũ)\n• Bộ điều khiển lò nung MAX31856 (firmware cũ)');
  static String version(String v) => tr('Version $v', 'Phiên bản $v');

  static String _short(Object e) {
    var s = e.toString();
    if (s.startsWith('Exception: ')) s = s.substring(11);
    return s.length > 120 ? '${s.substring(0, 120)}...' : s;
  }
}
