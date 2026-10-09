import 'dart:async';

/// Loai loi ma app biet cach noi voi nguoi dung (PLAN_HOAN_THIEN §H6).
/// Chu hien thi nam o lib/l10n (ham errorText), core khong chua chu.
enum ErrorKind {
  bluetoothOff,
  permission,
  unreachable,
  unsupported,
  badData,
  noResponse,

  /// Thiet bi tu choi nhung khong gui ly do
  rejected,

  /// Thiet bi tu choi kem cau `err`: hien nguyen van [AppError.deviceText]
  device,
  tooLong,
  notConnected,
  notAccepted,
  file,
  fileFormat,
  scan,
  unknown,
}

/// Moi loi BLE / transport deu doi ve lop nay truoc khi len UI
class AppError implements Exception {
  final ErrorKind kind;

  /// Loi goc, chi hien o che do Technician (nut Details)
  final String? detail;

  /// Cau do thiet bi gui (RESULT `err`), hien nguyen van
  final String? deviceText;

  const AppError(this.kind, [this.detail]) : deviceText = null;
  const AppError.device(String text)
      : kind = ErrorKind.device,
        deviceText = text,
        detail = null;

  /// Loi goc rut gon con 300 ky tu
  String? get shortDetail {
    final d = detail;
    if (d == null || d.isEmpty) return null;
    return d.length > 300 ? '${d.substring(0, 300)}...' : d;
  }

  /// Doi mot exception bat ky thanh AppError. [fallback] dung khi khong nhan ra loai loi.
  static AppError from(Object e, {ErrorKind fallback = ErrorKind.unknown}) {
    if (e is AppError) return e;
    final text = e.toString();
    final low = text.toLowerCase();
    ErrorKind kind = fallback;
    if (e is TimeoutException || low.contains('timeout') || low.contains('timed out')) {
      kind = fallback == ErrorKind.unknown ? ErrorKind.noResponse : fallback;
    } else if (low.contains('bluetoothnotenabled') ||
        low.contains('bluetooth not enabled') ||
        low.contains('bluetooth is off') ||
        low.contains('adapter is off')) {
      kind = ErrorKind.bluetoothOff;
    } else if (low.contains('permission') || low.contains('unauthorized')) {
      kind = ErrorKind.permission;
    } else if (e is FormatException) {
      kind = ErrorKind.badData;
    } else if (low.contains('khong co characteristic') || low.contains('not found')) {
      kind = fallback == ErrorKind.unknown ? ErrorKind.unsupported : fallback;
    }
    return AppError(kind, text);
  }

  @override
  String toString() => 'AppError(${kind.name}${deviceText != null ? ': $deviceText' : ''}${detail != null ? ', $detail' : ''})';
}
