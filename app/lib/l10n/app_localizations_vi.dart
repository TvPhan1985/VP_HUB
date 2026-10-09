// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTagline => 'Theo dõi và điều khiển thiết bị của bạn';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get apply => 'Áp dụng';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get retry => 'Thử lại';

  @override
  String get back => 'Quay lại';

  @override
  String get stay => 'Sửa tiếp';

  @override
  String get discard => 'Bỏ thay đổi';

  @override
  String get close => 'Đóng';

  @override
  String get remove => 'Xóa';

  @override
  String get clear => 'Xóa';

  @override
  String get undo => 'Hoàn tác';

  @override
  String get details => 'Chi tiết';

  @override
  String get turnOn => 'Bật';

  @override
  String get rename => 'Đổi tên';

  @override
  String get errBluetoothOff =>
      'Bluetooth đang tắt. Hãy bật Bluetooth để kết nối.';

  @override
  String get errPermission => 'VP Hub cần quyền Bluetooth để kết nối.';

  @override
  String get errUnreachable =>
      'Không kết nối được thiết bị. Hãy lại gần hơn và kiểm tra thiết bị đã bật nguồn.';

  @override
  String get errUnsupported => 'VP Hub không hỗ trợ thiết bị này.';

  @override
  String get errBadData =>
      'Thiết bị gửi dữ liệu không hợp lệ. Hãy khởi động lại thiết bị rồi thử lại.';

  @override
  String get errNoResponse => 'Thiết bị không phản hồi. Hãy thử lại.';

  @override
  String get errRejected => 'Thiết bị từ chối thay đổi.';

  @override
  String get errTooLong =>
      'Quá nhiều thay đổi trong một lần. Hãy lưu ít thay đổi hơn rồi thử lại.';

  @override
  String get errNotConnected => 'Chưa kết nối. Hãy đợi thiết bị kết nối lại.';

  @override
  String get errNotAccepted =>
      'Thiết bị không nhận giá trị. Hãy kiểm tra giá trị rồi thử lại.';

  @override
  String get errUnknown => 'Đã xảy ra lỗi. Hãy thử lại.';

  @override
  String get errFile => 'Không mở được file. Hãy chọn file khác.';

  @override
  String get errFileFormat => 'File này không phải file thiết bị hợp lệ.';

  @override
  String get errScan =>
      'Không quét được thiết bị. Hãy kiểm tra Bluetooth đã bật rồi thử lại.';

  @override
  String get errorDetails => 'Chi tiết lỗi';

  @override
  String get saved => 'Đã lưu';

  @override
  String get interfaceReloaded => 'Đã đọc lại giao diện';

  @override
  String commandSent(String label) {
    return '$label: đã gửi lệnh';
  }

  @override
  String turnedOn(String label) {
    return 'Đã bật $label';
  }

  @override
  String turnedOff(String label) {
    return 'Đã tắt $label';
  }

  @override
  String changedTo(String label, String value) {
    return '$label: $value';
  }

  @override
  String get protoDemo => 'Thiết bị mẫu (không có phần cứng)';

  @override
  String get protoKiln => 'Lò nung đời cũ (adapter kiln_v0)';

  @override
  String get protoC3 => 'Relay C3 đời cũ (adapter c3relay_v1)';

  @override
  String get demoTitle => 'Thiết bị mẫu';

  @override
  String get demoHint =>
      'Thiết bị giả để xem giao diện mà không cần phần cứng. Số liệu tự đổi nhẹ mỗi giây, mọi lệnh đều thành công.';

  @override
  String get demoRelay => 'Relay mẫu';

  @override
  String get demoRelaySub =>
      'Tổng quan, lịch có khung giờ lặp và các màn cài đặt trong menu.';

  @override
  String get demoAll => 'Đủ mọi kiểu dữ liệu';

  @override
  String get demoAllSub =>
      'Mọi kiểu, mọi gợi ý hiển thị, điều kiện hiện và khóa, một kiểu lạ.';

  @override
  String get openJson => 'Mở file JSON';

  @override
  String get openJsonSub =>
      'Chọn file thiết bị trong bộ nhớ điện thoại để xem trước schema của thiết bị mới.';

  @override
  String get onboardBody =>
      'VP Hub kết nối với cảm biến và bộ điều khiển của bạn qua Bluetooth.';

  @override
  String get onboardWhy =>
      'Để tìm và kết nối thiết bị ở gần, VP Hub cần quyền Bluetooth. Quyền này không dùng để theo dõi vị trí của bạn.';

  @override
  String get onboardAllow => 'Cho phép dùng Bluetooth';

  @override
  String get scan => 'Quét';

  @override
  String get scanAgain => 'Quét lại';

  @override
  String get stopScan => 'Dừng';

  @override
  String get scanning => 'Đang quét…';

  @override
  String get noNewDevices => 'Không thấy thiết bị mới nào ở gần.';

  @override
  String get myDevices => 'Thiết bị của tôi';

  @override
  String get nearby => 'Ở gần';

  @override
  String get inRange => 'Đang ở gần';

  @override
  String get scanEmptyTitle => 'Không thấy thiết bị nào ở gần';

  @override
  String get scanEmptyHint =>
      'Hãy bật thiết bị và để điện thoại cách thiết bị vài mét.';

  @override
  String get tagLegacy => 'Đời cũ';

  @override
  String get removeDevice => 'Xóa thiết bị';

  @override
  String get deviceRemoved => 'Đã xóa thiết bị';

  @override
  String get renameDevice => 'Đổi tên thiết bị';

  @override
  String get renameDeviceHint => 'Tên này chỉ dùng trong VP Hub.';

  @override
  String get deviceNameLabel => 'Tên';

  @override
  String get btOff => 'Bluetooth đang tắt. Hãy bật Bluetooth để tìm thiết bị.';

  @override
  String get btTurnOn => 'Bật Bluetooth';

  @override
  String get permMissing =>
      'VP Hub cần quyền Bluetooth để tìm và kết nối thiết bị. Hãy cho phép trong cài đặt của ứng dụng.';

  @override
  String get openSettings => 'Mở cài đặt';

  @override
  String get locationOff => 'Hãy bật Vị trí để tìm thiết bị Bluetooth.';

  @override
  String get openLocationSettings => 'Mở cài đặt vị trí';

  @override
  String get btOn => 'Bluetooth đang bật';

  @override
  String get btOffShort => 'Bluetooth đang tắt';

  @override
  String rssiDbm(int r) {
    return '$r dBm';
  }

  @override
  String get openMenu => 'Mở menu';

  @override
  String get secDevice => 'Thiết bị này';

  @override
  String get secApp => 'Ứng dụng';

  @override
  String get deviceList => 'Danh sách thiết bị';

  @override
  String get settings => 'Cài đặt';

  @override
  String get helpAbout => 'Trợ giúp & giới thiệu';

  @override
  String get secGeneral => 'Chung';

  @override
  String get secAdvanced => 'Nâng cao';

  @override
  String get secDeveloper => 'Công cụ nhà phát triển';

  @override
  String get secAbout => 'Giới thiệu';

  @override
  String get theme => 'Giao diện';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get autoConnect => 'Tự kết nối thiết bị dùng gần nhất';

  @override
  String get keepAwake => 'Giữ màn hình sáng khi đang kết nối';

  @override
  String get techMode => 'Chế độ kỹ thuật viên';

  @override
  String get techModeSub => 'Hiện các mục cài đặt, hiệu chuẩn và chẩn đoán.';

  @override
  String get setPin => 'Đặt mã PIN';

  @override
  String get removePin => 'Xóa mã PIN';

  @override
  String get pinSub => 'Hỏi mã PIN 4 số trước khi bật chế độ kỹ thuật viên.';

  @override
  String get enterPin => 'Nhập mã PIN';

  @override
  String get newPin => 'Mã PIN mới';

  @override
  String get confirmPin => 'Nhập lại mã PIN';

  @override
  String get pinWrong => 'Mã PIN không đúng. Hãy thử lại.';

  @override
  String get pinFormat => 'Hãy nhập 4 chữ số.';

  @override
  String get pinMismatch => 'Hai mã PIN không giống nhau.';

  @override
  String get removePinTitle => 'Xóa mã PIN?';

  @override
  String get removePinBody =>
      'Chế độ kỹ thuật viên sẽ bật mà không hỏi mã PIN.';

  @override
  String get pinSet => 'Đã đặt mã PIN';

  @override
  String get pinRemoved => 'Đã xóa mã PIN';

  @override
  String get showAddr => 'Hiện địa chỉ thiết bị';

  @override
  String get exportLog => 'Xuất nhật ký chẩn đoán';

  @override
  String get exportLogEmpty => 'Nhật ký chẩn đoán đang trống.';

  @override
  String get clearCache => 'Xóa giao diện đã lưu';

  @override
  String get clearCacheTitle => 'Xóa giao diện đã lưu?';

  @override
  String get clearCacheBody =>
      'VP Hub sẽ đọc lại giao diện của từng thiết bị ở lần kết nối tới.';

  @override
  String get cacheCleared => 'Đã xóa giao diện đã lưu';

  @override
  String get versionLabel => 'Phiên bản';

  @override
  String get licenses => 'Giấy phép mã nguồn mở';

  @override
  String get connecting => 'Đang kết nối…';

  @override
  String get connected => 'Đã kết nối';

  @override
  String get reconnecting => 'Đang kết nối lại…';

  @override
  String get disconnected => 'Mất kết nối';

  @override
  String connectedUpdated(int sec) {
    return 'Đã kết nối · cập nhật $sec giây trước';
  }

  @override
  String noNewData(int sec) {
    return 'Không có dữ liệu mới trong $sec giây';
  }

  @override
  String get onCaps => 'BẬT';

  @override
  String get offCaps => 'TẮT';

  @override
  String get alarmNone => 'Không có báo động';

  @override
  String get alarmsTitle => 'Báo động đang bật';

  @override
  String get alarmsTooltip => 'Báo động';

  @override
  String get showTrend => 'Xem biểu đồ';

  @override
  String durDH(String d, String h) {
    return '$d ngày $h giờ';
  }

  @override
  String durHM(String h, String m) {
    return '$h giờ $m phút';
  }

  @override
  String durMS(String m, String s) {
    return '$m phút $s giây';
  }

  @override
  String get loadingDevice => 'Đang tải thiết bị…';

  @override
  String get connectFailed => 'Không kết nối được';

  @override
  String get lostRetrying => 'Mất kết nối. Đang kết nối lại…';

  @override
  String get lostGiveUp => 'Không kết nối lại được với thiết bị.';

  @override
  String get deviceInfo => 'Thông tin thiết bị';

  @override
  String get disconnect => 'Ngắt kết nối';

  @override
  String disconnectTitle(String name) {
    return 'Ngắt kết nối với $name?';
  }

  @override
  String get disconnectBody => 'Các thay đổi chưa lưu sẽ bị mất.';

  @override
  String get reloadInterface => 'Đọc lại giao diện';

  @override
  String get needUpdate => 'Thiết bị này cần phiên bản VP Hub mới hơn.';

  @override
  String get noScreens =>
      'Thiết bị này không có gì để hiển thị. Hãy cập nhật firmware thiết bị hoặc liên hệ hỗ trợ.';

  @override
  String get screenError =>
      'Không hiển thị được màn hình này. Hãy cập nhật firmware thiết bị hoặc liên hệ hỗ trợ.';

  @override
  String get unsavedTitle => 'Lưu thay đổi?';

  @override
  String get noLimit => 'Không giới hạn';

  @override
  String get flagsNone => 'Bình thường';

  @override
  String flagN(int n) {
    return 'Báo động $n';
  }

  @override
  String get invalidNumber => 'Hãy nhập một số.';

  @override
  String rangeHint(String min, String max) {
    return 'Từ $min đến $max';
  }

  @override
  String outOfRange(String min, String max) {
    return 'Hãy nhập giá trị từ $min đến $max.';
  }

  @override
  String atLeast(String min) {
    return 'Hãy nhập từ $min trở lên.';
  }

  @override
  String atMost(String max) {
    return 'Hãy nhập tối đa $max.';
  }

  @override
  String maxLen(int n) {
    return 'Dùng tối đa $n ký tự.';
  }

  @override
  String get notEmpty => 'Không được để trống.';

  @override
  String get notSet => 'Chưa đặt';

  @override
  String get trendEmpty => 'Đang thu thập dữ liệu…';

  @override
  String get dayMon => 'T2';

  @override
  String get dayTue => 'T3';

  @override
  String get dayWed => 'T4';

  @override
  String get dayThu => 'T5';

  @override
  String get dayFri => 'T6';

  @override
  String get daySat => 'T7';

  @override
  String get daySun => 'CN';

  @override
  String get infoName => 'Tên';

  @override
  String get infoModel => 'Model';

  @override
  String get infoFw => 'Firmware';

  @override
  String get infoHw => 'Phần cứng';

  @override
  String get infoSignal => 'Sóng';

  @override
  String get infoStatus => 'Trạng thái';

  @override
  String get signalExcellent => 'Rất mạnh';

  @override
  String get signalGood => 'Mạnh';

  @override
  String get signalFair => 'Trung bình';

  @override
  String get signalWeak => 'Yếu';

  @override
  String get infoPv => 'Phiên bản giao thức';

  @override
  String get infoProto => 'Giao thức';

  @override
  String get infoScreens => 'Số màn hình';

  @override
  String get infoSch => 'Mã schema';

  @override
  String get infoCaps => 'Khả năng';

  @override
  String get infoSchemaSrc => 'Nguồn schema';

  @override
  String get fromCache => 'Lưu trong ứng dụng';

  @override
  String get fromDevice => 'Đọc từ thiết bị';

  @override
  String get infoMtu => 'MTU';

  @override
  String get infoMaxValues => 'Gói dữ liệu lớn nhất';

  @override
  String get infoPackets => 'Số gói dữ liệu đã nhận';

  @override
  String get infoBad => 'Số gói hỏng';

  @override
  String get infoAddr => 'Địa chỉ';

  @override
  String get valuesTooBig =>
      'Có gói dữ liệu lớn hơn 240 byte. Firmware cần tách màn hình hoặc rút ngắn id của trường (PROTOCOL §8).';

  @override
  String get badPacketsWarn =>
      'Đã nhận gói dữ liệu hỏng. Có thể dữ liệu quá dài so với MTU.';

  @override
  String bytesN(int n) {
    return '$n byte';
  }

  @override
  String get about => 'Giới thiệu';

  @override
  String get aboutBody =>
      'VP Hub kết nối với cảm biến và bộ điều khiển của bạn qua Bluetooth.';

  @override
  String get aboutProtocol => 'Giao thức VPH v1.3';

  @override
  String get aboutSupported => 'Thiết bị hỗ trợ';

  @override
  String get aboutSupportedList =>
      '• Thiết bị làm cho VP Hub\n• Bộ relay ESP32-C3\n• Bộ điều khiển lò nung MAX31856';

  @override
  String versionN(String v) {
    return 'Phiên bản $v';
  }

  @override
  String unsavedBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Màn hình này có $n thay đổi chưa lưu xuống thiết bị.',
    );
    return '$_temp0';
  }

  @override
  String batchChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n thay đổi chưa lưu',
    );
    return '$_temp0';
  }
}
