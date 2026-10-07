import 'dart:convert';

import '../cond.dart';
import 'vph_value.dart';

/// Mot muc cua danh sach chon (enum)
class VphOption {
  final dynamic value;
  final String label;

  /// Ten icon (PROTOCOL §5.6), phan tu thu 3 cua opt
  final String? icon;
  const VphOption(this.value, this.label, [this.icon]);
}

dynamic _pick(Map j, String short, [String? long]) => j[short] ?? (long != null ? j[long] : null);

double? _dbl(dynamic v) => v is num ? v.toDouble() : null;
bool _flag(dynamic v) => v == true || (v is num && v != 0);
String? _str(dynamic v) => v is String && v.isNotEmpty ? v : null;

/// Mot truong cua man hinh (PROTOCOL §5.1)
class VphField {
  static const knownTypes = {'num', 'bool', 'text', 'str', 'enum', 'time', 'date', 'days', 'flags', 'act'};

  final String id;
  final String label;

  /// Kieu da chuan hoa (float/int -> num). Kieu la giu nguyen de hien chu chi doc.
  final String type;
  final String? unit;
  final double? min, max, step;
  final int? dp;
  final bool readOnly;
  final List<VphOption> options;
  final List<String> flagLabels;

  /// Goi y hien thi `w`; cho phep nhieu goi y cach nhau dau phay ("big,trend")
  final Set<String> hints;
  final String? confirm;
  final String? ifCond;
  final String? enCond;
  final bool nullable;
  final String? group;

  /// Ten icon `ic` (PROTOCOL §5.6)
  final String? icon;

  /// Dong chu thich `d`
  final String? desc;

  /// Id truong lam dong phu cua the hero
  final String? sub;

  /// Chu cho 2 trang thai [tat, bat] cua bool (opt 2 phan tu), null = mac dinh
  final List<String>? boolLabels;

  const VphField({
    required this.id,
    required this.label,
    required this.type,
    this.unit,
    this.min,
    this.max,
    this.step,
    this.dp,
    this.readOnly = false,
    this.options = const [],
    this.flagLabels = const [],
    this.hints = const {},
    this.confirm,
    this.ifCond,
    this.enCond,
    this.nullable = false,
    this.group,
    this.icon,
    this.desc,
    this.sub,
    this.boolLabels,
  });

  bool get known => knownTypes.contains(type);
  bool hint(String h) => hints.contains(h);

  /// So chu so thap phan khi hien: dp, khong co thi suy tu buoc nhay
  int? get decimals => dp ?? (step != null && step! > 0 ? decimalsOf(step!) : null);

  String? optionLabel(dynamic v) {
    for (final o in options) {
      if ('${o.value}' == '$v') return o.label;
    }
    return null;
  }

  static String _normType(String t) => (t == 'float' || t == 'int') ? 'num' : t;

  factory VphField.fromJson(Map j) {
    final id = j['id'];
    if (id is! String || id.isEmpty) throw const FormatException('truong thieu id');
    final type = _normType(_str(_pick(j, 't', 'type')) ?? 'text');
    final opt = j['opt'];
    final options = <VphOption>[];
    final flagLabels = <String>[];
    List<String>? boolLabels;
    if (opt is List && type == 'bool') {
      if (opt.length >= 2 && opt[0] is String && opt[1] is String) boolLabels = [opt[0] as String, opt[1] as String];
    } else if (opt is List) {
      for (final o in opt) {
        if (type == 'flags') {
          flagLabels.add('$o');
        } else if (o is List && o.isNotEmpty) {
          options.add(VphOption(o[0], o.length > 1 ? '${o[1]}' : '${o[0]}', o.length > 2 ? _str(o[2]) : null));
        } else if (o is! List) {
          options.add(VphOption(o, '$o'));
        }
      }
    }
    final w = j['w'];
    final hints = <String>{
      if (w is String) ...w.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      if (w is List) ...w.map((e) => '$e'),
    };
    final dp = j['dp'];
    return VphField(
      id: id,
      label: _str(_pick(j, 'l', 'label')) ?? id,
      type: type,
      unit: _str(_pick(j, 'u', 'unit')),
      min: _dbl(j['min']),
      max: _dbl(j['max']),
      step: _dbl(_pick(j, 'st', 'step')),
      dp: dp is num ? dp.toInt() : null,
      readOnly: _flag(_pick(j, 'ro', 'readonly')),
      options: options,
      flagLabels: flagLabels,
      hints: hints,
      confirm: _str(j['c']),
      ifCond: _str(j['if']),
      enCond: _str(j['en']),
      nullable: _flag(j['nul']),
      group: _str(j['g']),
      icon: _str(j['ic']),
      desc: _str(j['d']),
      sub: _str(j['sub']),
      boolLabels: boolLabels,
    );
  }

  /// Ban sao cho mot lan lap: doi id va doi id trong dieu kien
  VphField expanded(String newId, Map<String, String> rename) => VphField(
        id: newId,
        label: label,
        type: type,
        unit: unit,
        min: min,
        max: max,
        step: step,
        dp: dp,
        readOnly: readOnly,
        options: options,
        flagLabels: flagLabels,
        hints: hints,
        confirm: confirm,
        ifCond: renameCond(ifCond, rename),
        enCond: renameCond(enCond, rename),
        nullable: nullable,
        icon: icon,
        desc: desc,
        sub: sub == null ? null : (rename[sub] ?? sub),
        boolLabels: boolLabels,
      );
}

/// Khoi lap (PROTOCOL §5.3)
class VphRepeat {
  final int n;
  final String pfx;
  final String? label;
  final List<VphField> fields;
  final String? cnt;
  const VphRepeat({required this.n, required this.pfx, this.label, required this.fields, this.cnt});

  factory VphRepeat.fromJson(Map j) {
    final n = _pick(j, 'n', 'count');
    final f = _pick(j, 'f', 'fields');
    return VphRepeat(
      n: n is num ? n.toInt().clamp(0, 64) : 0,
      pfx: _str(_pick(j, 'pfx', 'prefix')) ?? 'r',
      label: _str(_pick(j, 'l', 'label')),
      fields: [if (f is List) for (final e in f) if (e is Map) VphField.fromJson(e)],
      cnt: _str(j['cnt']),
    );
  }

  String idOf(int i, String fieldId) => '$pfx${i}_$fieldId';
}

/// Mot the cua khoi lap sau khi mo rong ("Khung 1", "Khung 2"...)
class VphRepGroup {
  final int index; // tu 1
  final List<VphField> fields;
  const VphRepGroup(this.index, this.fields);
}

/// Mot man hinh (PROTOCOL §5)
class VphScreen {
  final String id;
  final String title;

  /// Ten icon cua tab (PROTOCOL §5.6)
  final String? icon;
  final bool batch;
  final List<VphField> fields;
  final VphRepeat? rep;
  final List<VphRepGroup> repGroups;

  /// Khac null khi schema hong: man hinh hien thanh the canh bao
  final String? error;

  VphScreen({
    required this.id,
    required this.title,
    this.icon,
    this.batch = false,
    this.fields = const [],
    this.rep,
    this.error,
  }) : repGroups = _expand(rep);

  static List<VphRepGroup> _expand(VphRepeat? r) {
    if (r == null) return const [];
    return [
      for (var i = 1; i <= r.n; i++)
        VphRepGroup(i, [
          for (final f in r.fields)
            f.expanded(r.idOf(i, f.id), {for (final g in r.fields) g.id: r.idOf(i, g.id)}),
        ]),
    ];
  }

  Iterable<VphField> get allFields sync* {
    yield* fields;
    for (final g in repGroups) {
      yield* g.fields;
    }
  }

  VphField? field(String id) {
    for (final f in allFields) {
      if (f.id == id) return f;
    }
    return null;
  }

  factory VphScreen.fromJson(Map j) {
    final id = j['id'];
    if (id is! String || id.isEmpty) throw const FormatException('man hinh thieu id');
    final f = _pick(j, 'f', 'fields');
    final rep = _pick(j, 'rep', 'repeat');
    return VphScreen(
      id: id,
      title: _str(_pick(j, 'l', 'title')) ?? id,
      icon: _str(j['ic']),
      batch: j['save'] == 'batch',
      fields: [if (f is List) for (final e in f) if (e is Map) VphField.fromJson(e)],
      rep: rep is Map ? VphRepeat.fromJson(rep) : null,
    );
  }

  /// Khong bao gio nem loi: schema hong tra ve man hinh co [error]
  static VphScreen tryParse(String json, {int index = 0}) {
    try {
      final j = jsonDecode(json);
      if (j is! Map) throw const FormatException('khong phai object JSON');
      return VphScreen.fromJson(j);
    } catch (e) {
      return VphScreen(id: 'screen$index', title: '#${index + 1}', error: '$e');
    }
  }

  static VphScreen tryFromMap(dynamic j, {int index = 0}) {
    try {
      if (j is! Map) throw const FormatException('khong phai object JSON');
      return VphScreen.fromJson(j);
    } catch (e) {
      return VphScreen(id: 'screen$index', title: '#${index + 1}', error: '$e');
    }
  }
}
