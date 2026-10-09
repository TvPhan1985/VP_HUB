// ignore_for_file: unnecessary_brace_in_string_interps
/// Ngon ngu hien thi cua app. Mac dinh tieng Anh; nguoi dung doi trong Settings.
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

/// Moi chu hien thi trong app gom o day, moi chu co ban tieng Anh va tieng Viet.
/// Quy tac viet chu: docs/COPY_STYLE.md.
class S {
  static const appName = 'VP Hub';
  static const noData = '--';
  static const tagVph = 'VPH';
  static const techChip = 'TECH';

  static String get appTagline => tr('Monitor and control your devices', 'Theo dõi và điều khiển thiết bị của bạn');
  static String get cancel => tr('Cancel', 'Hủy');
  static String get save => tr('Save', 'Lưu');
  static String get apply => tr('Apply', 'Áp dụng');
  static String get confirm => tr('Confirm', 'Xác nhận');
  static String get retry => tr('Try again', 'Thử lại');
  static String get back => tr('Back', 'Quay lại');
  static String get stay => tr('Keep editing', 'Sửa tiếp');
  static String get discard => tr('Discard', 'Bỏ thay đổi');
  static String get close => tr('Close', 'Đóng');
  static String get remove => tr('Remove', 'Xóa');
  static String get clear => tr('Clear', 'Xóa');
  static String get undo => tr('Undo', 'Hoàn tác');
  static String get details => tr('Details', 'Chi tiết');
  static String get turnOn => tr('Turn on', 'Bật');
  static String get rename => tr('Rename', 'Đổi tên');
  static String get errBluetoothOff => tr('Bluetooth is off. Turn it on to connect.', 'Bluetooth đang tắt. Hãy bật Bluetooth để kết nối.');
  static String get errPermission => tr('VP Hub needs Bluetooth access to connect.', 'VP Hub cần quyền Bluetooth để kết nối.');
  static String get errUnreachable => tr('Can\'t reach the device. Move closer and make sure it\'s powered on.', 'Không kết nối được thiết bị. Hãy lại gần hơn và kiểm tra thiết bị đã bật nguồn.');
  static String get errUnsupported => tr('This device isn\'t supported by VP Hub.', 'VP Hub không hỗ trợ thiết bị này.');
  static String get errBadData => tr('The device sent invalid data. Restart the device and try again.', 'Thiết bị gửi dữ liệu không hợp lệ. Hãy khởi động lại thiết bị rồi thử lại.');
  static String get errNoResponse => tr('The device didn\'t respond. Try again.', 'Thiết bị không phản hồi. Hãy thử lại.');
  static String get errRejected => tr('The device rejected the change.', 'Thiết bị từ chối thay đổi.');
  static String get errTooLong => tr('Too many changes at once. Save fewer changes and try again.', 'Quá nhiều thay đổi trong một lần. Hãy lưu ít thay đổi hơn rồi thử lại.');
  static String get errNotConnected => tr('Not connected. Wait for the device to reconnect.', 'Chưa kết nối. Hãy đợi thiết bị kết nối lại.');
  static String get errNotAccepted => tr('The device didn\'t accept the value. Check the value and try again.', 'Thiết bị không nhận giá trị. Hãy kiểm tra giá trị rồi thử lại.');
  static String get errUnknown => tr('Something went wrong. Try again.', 'Đã xảy ra lỗi. Hãy thử lại.');
  static String get errFile => tr('Can\'t open the file. Choose a different file.', 'Không mở được file. Hãy chọn file khác.');
  static String get errFileFormat => tr('This file isn\'t a valid device file.', 'File này không phải file thiết bị hợp lệ.');
  static String get errScan => tr('Can\'t scan for devices. Make sure Bluetooth is on and try again.', 'Không quét được thiết bị. Hãy kiểm tra Bluetooth đã bật rồi thử lại.');
  static String get errorDetails => tr('Error details', 'Chi tiết lỗi');
  static String get saved => tr('Saved', 'Đã lưu');
  static String get interfaceReloaded => tr('Interface reloaded', 'Đã đọc lại giao diện');
  static String commandSent(String label) => tr('${label}: command sent', '${label}: đã gửi lệnh');
  static String turnedOn(String label) => tr('${label} turned on', 'Đã bật ${label}');
  static String turnedOff(String label) => tr('${label} turned off', 'Đã tắt ${label}');
  static String changedTo(String label, String value) => tr('${label}: ${value}', '${label}: ${value}');
  static String get protoDemo => tr('Demo device (no hardware)', 'Thiết bị mẫu (không có phần cứng)');
  static String get protoKiln => tr('Legacy kiln controller (kiln_v0 adapter)', 'Lò nung đời cũ (adapter kiln_v0)');
  static String get protoC3 => tr('Legacy C3 relay (c3relay_v1 adapter)', 'Relay C3 đời cũ (adapter c3relay_v1)');
  static String get demoTitle => tr('Demo devices', 'Thiết bị mẫu');
  static String get demoHint => tr('Simulated devices for exploring the interface without hardware. Readings drift slightly every second and every command succeeds.', 'Thiết bị giả để xem giao diện mà không cần phần cứng. Số liệu tự đổi nhẹ mỗi giây, mọi lệnh đều thành công.');
  static String get demoRelay => tr('Demo relay', 'Relay mẫu');
  static String get demoRelaySub => tr('Overview, schedule with repeating slots, and settings screens in the menu.', 'Tổng quan, lịch có khung giờ lặp và các màn cài đặt trong menu.');
  static String get demoAll => tr('All data types', 'Đủ mọi kiểu dữ liệu');
  static String get demoAllSub => tr('Every type and display hint, show and enable conditions, and one unknown type.', 'Mọi kiểu, mọi gợi ý hiển thị, điều kiện hiện và khóa, một kiểu lạ.');
  static String get openJson => tr('Open JSON file', 'Mở file JSON');
  static String get openJsonSub => tr('Choose a device file from phone storage to preview the schema of a new device.', 'Chọn file thiết bị trong bộ nhớ điện thoại để xem trước schema của thiết bị mới.');
  static String get onboardBody => tr('VP Hub connects to your sensors and controllers over Bluetooth.', 'VP Hub kết nối với cảm biến và bộ điều khiển của bạn qua Bluetooth.');
  static String get onboardWhy => tr('To find devices near you and connect to them, VP Hub needs Bluetooth access. It is never used to track your location.', 'Để tìm và kết nối thiết bị ở gần, VP Hub cần quyền Bluetooth. Quyền này không dùng để theo dõi vị trí của bạn.');
  static String get onboardAllow => tr('Allow Bluetooth access', 'Cho phép dùng Bluetooth');
  static String get scan => tr('Scan', 'Quét');
  static String get scanAgain => tr('Scan again', 'Quét lại');
  static String get stopScan => tr('Stop', 'Dừng');
  static String get scanning => tr('Scanning…', 'Đang quét…');
  static String get noNewDevices => tr('No new devices nearby.', 'Không thấy thiết bị mới nào ở gần.');
  static String get myDevices => tr('My devices', 'Thiết bị của tôi');
  static String get nearby => tr('Nearby', 'Ở gần');
  static String get inRange => tr('In range', 'Đang ở gần');
  static String get scanEmptyTitle => tr('No devices nearby', 'Không thấy thiết bị nào ở gần');
  static String get scanEmptyHint => tr('Turn on your device and keep the phone within a few meters.', 'Hãy bật thiết bị và để điện thoại cách thiết bị vài mét.');
  static String get tagLegacy => tr('Legacy', 'Đời cũ');
  static String get removeDevice => tr('Remove device', 'Xóa thiết bị');
  static String get deviceRemoved => tr('Device removed', 'Đã xóa thiết bị');
  static String get renameDevice => tr('Rename device', 'Đổi tên thiết bị');
  static String get renameDeviceHint => tr('This name is used in VP Hub only.', 'Tên này chỉ dùng trong VP Hub.');
  static String get deviceNameLabel => tr('Name', 'Tên');
  static String get btOff => tr('Bluetooth is off. Turn it on to find devices.', 'Bluetooth đang tắt. Hãy bật Bluetooth để tìm thiết bị.');
  static String get btTurnOn => tr('Turn on Bluetooth', 'Bật Bluetooth');
  static String get permMissing => tr('VP Hub needs Bluetooth access to find and connect to devices. Allow it in the app settings.', 'VP Hub cần quyền Bluetooth để tìm và kết nối thiết bị. Hãy cho phép trong cài đặt của ứng dụng.');
  static String get openSettings => tr('Open settings', 'Mở cài đặt');
  static String get locationOff => tr('Turn on Location to find Bluetooth devices.', 'Hãy bật Vị trí để tìm thiết bị Bluetooth.');
  static String get openLocationSettings => tr('Open location settings', 'Mở cài đặt vị trí');
  static String get btOn => tr('Bluetooth is on', 'Bluetooth đang bật');
  static String get btOffShort => tr('Bluetooth is off', 'Bluetooth đang tắt');
  static String rssiDbm(int r) => tr('${r} dBm', '${r} dBm');
  static String get openMenu => tr('Open menu', 'Mở menu');
  static String get secDevice => tr('This device', 'Thiết bị này');
  static String get secApp => tr('App', 'Ứng dụng');
  static String get deviceList => tr('Device list', 'Danh sách thiết bị');
  static String get settings => tr('Settings', 'Cài đặt');
  static String get helpAbout => tr('Help & about', 'Trợ giúp & giới thiệu');
  static String get secGeneral => tr('General', 'Chung');
  static String get secAdvanced => tr('Advanced', 'Nâng cao');
  static String get secDeveloper => tr('Developer tools', 'Công cụ nhà phát triển');
  static String get secAbout => tr('About', 'Giới thiệu');
  static String get theme => tr('Theme', 'Giao diện');
  static String get themeSystem => tr('System default', 'Theo hệ thống');
  static String get themeLight => tr('Light', 'Sáng');
  static String get themeDark => tr('Dark', 'Tối');
  static String get language => tr('Language', 'Ngôn ngữ');
  static String get autoConnect => tr('Auto-connect to last device', 'Tự kết nối thiết bị dùng gần nhất');
  static String get keepAwake => tr('Keep screen on while connected', 'Giữ màn hình sáng khi đang kết nối');
  static String get techMode => tr('Technician mode', 'Chế độ kỹ thuật viên');
  static String get techModeSub => tr('Shows setup, calibration and diagnostic options.', 'Hiện các mục cài đặt, hiệu chuẩn và chẩn đoán.');
  static String get setPin => tr('Set PIN', 'Đặt mã PIN');
  static String get removePin => tr('Remove PIN', 'Xóa mã PIN');
  static String get pinSub => tr('Ask for a 4-digit PIN before turning on Technician mode.', 'Hỏi mã PIN 4 số trước khi bật chế độ kỹ thuật viên.');
  static String get enterPin => tr('Enter PIN', 'Nhập mã PIN');
  static String get newPin => tr('New PIN', 'Mã PIN mới');
  static String get confirmPin => tr('Confirm PIN', 'Nhập lại mã PIN');
  static String get pinWrong => tr('Incorrect PIN. Try again.', 'Mã PIN không đúng. Hãy thử lại.');
  static String get pinFormat => tr('Enter 4 digits.', 'Hãy nhập 4 chữ số.');
  static String get pinMismatch => tr('The PINs don\'t match.', 'Hai mã PIN không giống nhau.');
  static String get removePinTitle => tr('Remove PIN?', 'Xóa mã PIN?');
  static String get removePinBody => tr('Technician mode will turn on without asking for a PIN.', 'Chế độ kỹ thuật viên sẽ bật mà không hỏi mã PIN.');
  static String get pinSet => tr('PIN set', 'Đã đặt mã PIN');
  static String get pinRemoved => tr('PIN removed', 'Đã xóa mã PIN');
  static String get showAddr => tr('Show device addresses', 'Hiện địa chỉ thiết bị');
  static String get exportLog => tr('Export diagnostics log', 'Xuất nhật ký chẩn đoán');
  static String get exportLogEmpty => tr('The diagnostics log is empty.', 'Nhật ký chẩn đoán đang trống.');
  static String get clearCache => tr('Clear saved interfaces', 'Xóa giao diện đã lưu');
  static String get clearCacheTitle => tr('Clear saved interfaces?', 'Xóa giao diện đã lưu?');
  static String get clearCacheBody => tr('VP Hub will load each device interface again the next time you connect.', 'VP Hub sẽ đọc lại giao diện của từng thiết bị ở lần kết nối tới.');
  static String get cacheCleared => tr('Saved interfaces cleared', 'Đã xóa giao diện đã lưu');
  static String get versionLabel => tr('Version', 'Phiên bản');
  static String get licenses => tr('Open-source licenses', 'Giấy phép mã nguồn mở');
  static String get connecting => tr('Connecting…', 'Đang kết nối…');
  static String get connected => tr('Connected', 'Đã kết nối');
  static String get reconnecting => tr('Reconnecting…', 'Đang kết nối lại…');
  static String get disconnected => tr('Disconnected', 'Mất kết nối');
  static String connectedUpdated(int sec) => tr('Connected · updated ${sec} s ago', 'Đã kết nối · cập nhật ${sec} giây trước');
  static String noNewData(int sec) => tr('No new data for ${sec} s', 'Không có dữ liệu mới trong ${sec} giây');
  static String get onCaps => tr('ON', 'BẬT');
  static String get offCaps => tr('OFF', 'TẮT');
  static String get alarmNone => tr('No active alarms', 'Không có báo động');
  static String get alarmsTitle => tr('Active alarms', 'Báo động đang bật');
  static String get alarmsTooltip => tr('Alarms', 'Báo động');
  static String get showTrend => tr('Show chart', 'Xem biểu đồ');
  static String durDH(String d, String h) => tr('${d} d ${h} h', '${d} ngày ${h} giờ');
  static String durHM(String h, String m) => tr('${h} h ${m} min', '${h} giờ ${m} phút');
  static String durMS(String m, String s) => tr('${m} min ${s} s', '${m} phút ${s} giây');
  static String get loadingDevice => tr('Loading device…', 'Đang tải thiết bị…');
  static String get connectFailed => tr('Can\'t connect', 'Không kết nối được');
  static String get lostRetrying => tr('Connection lost. Reconnecting…', 'Mất kết nối. Đang kết nối lại…');
  static String get lostGiveUp => tr('Can\'t reconnect to the device.', 'Không kết nối lại được với thiết bị.');
  static String get deviceInfo => tr('Device info', 'Thông tin thiết bị');
  static String get disconnect => tr('Disconnect', 'Ngắt kết nối');
  static String disconnectTitle(String name) => tr('Disconnect from ${name}?', 'Ngắt kết nối với ${name}?');
  static String get disconnectBody => tr('Changes you haven\'t saved will be lost.', 'Các thay đổi chưa lưu sẽ bị mất.');
  static String get reloadInterface => tr('Reload interface', 'Đọc lại giao diện');
  static String get needUpdate => tr('This device needs a newer version of VP Hub.', 'Thiết bị này cần phiên bản VP Hub mới hơn.');
  static String get noScreens => tr('This device has nothing to show. Update the device firmware or contact support.', 'Thiết bị này không có gì để hiển thị. Hãy cập nhật firmware thiết bị hoặc liên hệ hỗ trợ.');
  static String get screenError => tr('This screen can\'t be displayed. Update the device firmware or contact support.', 'Không hiển thị được màn hình này. Hãy cập nhật firmware thiết bị hoặc liên hệ hỗ trợ.');
  static String get unsavedTitle => tr('Save changes?', 'Lưu thay đổi?');
  static String get noLimit => tr('No limit', 'Không giới hạn');
  static String get flagsNone => tr('Normal', 'Bình thường');
  static String flagN(int n) => tr('Alarm ${n}', 'Báo động ${n}');
  static String get invalidNumber => tr('Enter a number.', 'Hãy nhập một số.');
  static String rangeHint(String min, String max) => tr('From ${min} to ${max}', 'Từ ${min} đến ${max}');
  static String outOfRange(String min, String max) => tr('Enter a value from ${min} to ${max}.', 'Hãy nhập giá trị từ ${min} đến ${max}.');
  static String atLeast(String min) => tr('Enter ${min} or more.', 'Hãy nhập từ ${min} trở lên.');
  static String atMost(String max) => tr('Enter ${max} or less.', 'Hãy nhập tối đa ${max}.');
  static String maxLen(int n) => tr('Use up to ${n} characters.', 'Dùng tối đa ${n} ký tự.');
  static String get notEmpty => tr('This can\'t be empty.', 'Không được để trống.');
  static String get notSet => tr('Not set', 'Chưa đặt');
  static String get trendEmpty => tr('Collecting data…', 'Đang thu thập dữ liệu…');
  static String get dayMon => tr('Mo', 'T2');
  static String get dayTue => tr('Tu', 'T3');
  static String get dayWed => tr('We', 'T4');
  static String get dayThu => tr('Th', 'T5');
  static String get dayFri => tr('Fr', 'T6');
  static String get daySat => tr('Sa', 'T7');
  static String get daySun => tr('Su', 'CN');
  static String get infoName => tr('Name', 'Tên');
  static String get infoModel => tr('Model', 'Model');
  static String get infoFw => tr('Firmware', 'Firmware');
  static String get infoHw => tr('Hardware', 'Phần cứng');
  static String get infoSignal => tr('Signal', 'Sóng');
  static String get infoStatus => tr('Status', 'Trạng thái');
  static String get signalExcellent => tr('Excellent', 'Rất mạnh');
  static String get signalGood => tr('Good', 'Mạnh');
  static String get signalFair => tr('Fair', 'Trung bình');
  static String get signalWeak => tr('Weak', 'Yếu');
  static String get infoPv => tr('Protocol version', 'Phiên bản giao thức');
  static String get infoProto => tr('Protocol', 'Giao thức');
  static String get infoScreens => tr('Screens', 'Số màn hình');
  static String get infoSch => tr('Schema ID', 'Mã schema');
  static String get infoCaps => tr('Capabilities', 'Khả năng');
  static String get infoSchemaSrc => tr('Schema source', 'Nguồn schema');
  static String get fromCache => tr('Saved in app', 'Lưu trong ứng dụng');
  static String get fromDevice => tr('Read from device', 'Đọc từ thiết bị');
  static String get infoMtu => tr('MTU', 'MTU');
  static String get infoMaxValues => tr('Largest data packet', 'Gói dữ liệu lớn nhất');
  static String get infoPackets => tr('Data packets received', 'Số gói dữ liệu đã nhận');
  static String get infoBad => tr('Corrupted packets', 'Số gói hỏng');
  static String get infoAddr => tr('Address', 'Địa chỉ');
  static String get valuesTooBig => tr('A data packet is larger than 240 bytes. The firmware must split the screen or use shorter field IDs (PROTOCOL §8).', 'Có gói dữ liệu lớn hơn 240 byte. Firmware cần tách màn hình hoặc rút ngắn id của trường (PROTOCOL §8).');
  static String get badPacketsWarn => tr('Corrupted data packets were received. The data may be too long for the MTU.', 'Đã nhận gói dữ liệu hỏng. Có thể dữ liệu quá dài so với MTU.');
  static String bytesN(int n) => tr('${n} bytes', '${n} byte');
  static String get about => tr('About', 'Giới thiệu');
  static String get aboutBody => tr('VP Hub connects to your sensors and controllers over Bluetooth.', 'VP Hub kết nối với cảm biến và bộ điều khiển của bạn qua Bluetooth.');
  static String get aboutProtocol => tr('Protocol VPH v1.3', 'Giao thức VPH v1.3');
  static String get aboutSupported => tr('Supported devices', 'Thiết bị hỗ trợ');
  static String get aboutSupportedList => tr('• Devices made for VP Hub\n• ESP32-C3 relay controller\n• MAX31856 kiln controller', '• Thiết bị làm cho VP Hub\n• Bộ relay ESP32-C3\n• Bộ điều khiển lò nung MAX31856');
  static String versionN(String v) => tr('Version ${v}', 'Phiên bản ${v}');

  static String unsavedBody(int n) => tr(
      n == 1
          ? "This screen has 1 change that isn't saved to the device."
          : "This screen has $n changes that aren't saved to the device.",
      'Màn hình này có $n thay đổi chưa lưu xuống thiết bị.');
  static String batchChanges(int n) => tr(n == 1 ? '1 unsaved change' : '$n unsaved changes', '$n thay đổi chưa lưu');

  /// Muc song theo so vach 1..4
  static String signalLevel(int bars) => switch (bars) {
        4 => signalExcellent,
        3 => signalGood,
        2 => signalFair,
        _ => signalWeak,
      };

  /// Thu 2 ... Chu nhat
  static List<String> get dayLabels => [dayMon, dayTue, dayWed, dayThu, dayFri, daySat, daySun];
}
