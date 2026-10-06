/// Danh gia dieu kien if/en (PROTOCOL §5.5): `id==gia_tri` hoac `id!=gia_tri`, noi bang `&&`
library;

class CondTerm {
  final String id;
  final bool negate;
  final String value;
  const CondTerm(this.id, this.negate, this.value);

  @override
  String toString() => '$id${negate ? '!=' : '=='}$value';
}

/// Tach mot dieu kien don. Sai cu phap tra null.
CondTerm? parseCondTerm(String term) {
  var i = term.indexOf('!=');
  var negate = true;
  final eq = term.indexOf('==');
  if (i < 0 || (eq >= 0 && eq < i)) {
    i = eq;
    negate = false;
  }
  if (i <= 0) return null;
  final id = term.substring(0, i).trim();
  var value = term.substring(i + 2).trim();
  if (id.isEmpty) return null;
  if (value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'")))) {
    value = value.substring(1, value.length - 1);
  }
  return CondTerm(id, negate, value);
}

List<CondTerm?> parseCond(String expr) => [for (final t in expr.split('&&')) parseCondTerm(t)];

bool _same(dynamic actual, String expected) {
  if (actual == null) return expected == 'null';
  final expNum = double.tryParse(expected);
  final expBool = expected == 'true' ? true : (expected == 'false' ? false : null);
  if (actual is bool) {
    if (expBool != null) return actual == expBool;
    if (expNum != null) return (actual ? 1 : 0) == expNum;
    return false;
  }
  if (actual is num) {
    if (expNum != null) return actual == expNum;
    if (expBool != null) return (actual != 0) == expBool;
    return '$actual' == expected;
  }
  return '$actual' == expected;
}

/// Khong co truong trong VALUES, hoac dieu kien sai cu phap -> coi la dung
bool evalCond(String? expr, Map<String, dynamic> values) {
  if (expr == null || expr.trim().isEmpty) return true;
  for (final t in parseCond(expr)) {
    if (t == null) continue;
    if (!values.containsKey(t.id)) continue;
    final same = _same(values[t.id], t.value);
    if (t.negate ? same : !same) return false;
  }
  return true;
}

/// Doi id trong dieu kien (dung khi mo rong khoi lap): id nao co trong [rename] thi thay
String? renameCond(String? expr, Map<String, String> rename) {
  if (expr == null) return null;
  return expr.split('&&').map((raw) {
    final t = parseCondTerm(raw);
    if (t == null || !rename.containsKey(t.id)) return raw.trim();
    return CondTerm(rename[t.id]!, t.negate, t.value).toString();
  }).join('&&');
}
