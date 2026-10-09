import '../errors.dart';

/// Ket qua mot lenh ghi (PROTOCOL §6.4)
class VphResult {
  final bool ok;
  final AppError? error;
  const VphResult.ok()
      : ok = true,
        error = null;
  const VphResult.fail(AppError this.error) : ok = false;

  /// Cau `err` do thiet bi gui (neu co)
  String? get err => error?.deviceText;

  @override
  String toString() => ok ? 'ok' : 'loi: $error';
}

/// Doi gia tri VALUES sang bool (chap nhan true/false va 0/1)
bool? asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v == 'true') return true;
  if (v == 'false') return false;
  return null;
}

double? asNum(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is bool) return v ? 1 : 0;
  if (v is String) return double.tryParse(v.trim().replaceAll(',', '.'));
  return null;
}

/// So chu so thap phan cua buoc nhay (0.1 -> 1, 0.001 -> 3), toi da 4
int decimalsOf(double step) {
  for (var d = 0; d <= 4; d++) {
    final scaled = step * _pow10(d);
    // Sai so 1e-5 de nhan dung buoc kieu float cua firmware (0.05f -> 0.0500000007)
    if ((scaled - scaled.roundToDouble()).abs() < 1e-5) return d;
  }
  return 4;
}

double _pow10(int d) {
  var r = 1.0;
  for (var i = 0; i < d; i++) {
    r *= 10;
  }
  return r;
}

/// In so: co dp thi dung dp; khong thi so nguyen in nguyen, so le in toi da 2 chu so
String fmtNum(num v, {int? dp}) {
  if (v.isNaN || v.isInfinite) return '--';
  if (dp != null) return v.toStringAsFixed(dp.clamp(0, 6));
  if (v == v.roundToDouble()) return v.round().toString();
  var s = v.toStringAsFixed(2);
  if (s.endsWith('0')) s = s.substring(0, s.length - 1);
  return s;
}

/// Lam tron de bo nhieu so thuc sau khi cong tru buoc nhay
double roundTo(double v, int decimals) {
  final p = _pow10(decimals);
  return (v * p).roundToDouble() / p;
}

/// So sanh hai gia tri VALUES (so co sai so nho, bool chap nhan 0/1)
bool sameValue(dynamic a, dynamic b, {double tol = 1e-6}) {
  if (a == null || b == null) return a == null && b == null;
  if (a is bool || b is bool) return asBool(a) == asBool(b);
  if (a is num && b is num) return (a - b).abs() <= tol;
  return '$a' == '$b';
}
