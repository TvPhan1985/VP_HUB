/// INFO cua thiet bi (PROTOCOL §4)
class VphInfo {
  final String proto;
  final int pv;
  final String model;
  final String name;
  final String fw;
  final String? hw;
  final int n;
  final String? sch;
  final List<String> hdr;
  final List<String> caps;
  final String icon;

  /// Linh vuc cua thiet bi (khoa `dom`): 'ind' cong nghiep (mac dinh) | 'agri' nong nghiep
  final String domain;

  const VphInfo({
    this.proto = 'vph',
    this.pv = 1,
    required this.model,
    required this.name,
    this.fw = '?',
    this.hw,
    required this.n,
    this.sch,
    this.hdr = const [],
    this.caps = const [],
    this.icon = 'generic',
    this.domain = 'ind',
  });

  bool get agri => domain == 'agri';

  bool get hasTime => caps.contains('time');

  static List<String> _strList(dynamic v) =>
      v is List ? [for (final e in v) if (e is String) e] : const [];

  /// Nem FormatException neu thieu khoa bat buoc hoac khong phai "vph"
  factory VphInfo.fromJson(Map<String, dynamic> j) {
    if (j['proto'] != 'vph') throw const FormatException('proto khong phai vph');
    final model = j['model'];
    if (model is! String || model.isEmpty) throw const FormatException('thieu model');
    return VphInfo(
      pv: j['pv'] is num ? (j['pv'] as num).toInt() : 1,
      model: model,
      name: j['name'] is String ? j['name'] as String : model,
      fw: j['fw'] is String ? j['fw'] as String : '?',
      hw: j['hw'] is String ? j['hw'] as String : null,
      n: j['n'] is num ? (j['n'] as num).toInt() : 0,
      sch: j['sch'] is String ? j['sch'] as String : null,
      hdr: _strList(j['hdr']),
      caps: _strList(j['caps']),
      icon: j['icon'] is String ? j['icon'] as String : 'generic',
      domain: j['dom'] == 'agri' ? 'agri' : 'ind',
    );
  }

  Map<String, dynamic> toJson() => {
        'proto': proto,
        'pv': pv,
        'model': model,
        'name': name,
        'fw': fw,
        if (hw != null) 'hw': hw,
        'n': n,
        if (sch != null) 'sch': sch,
        if (hdr.isNotEmpty) 'hdr': hdr,
        if (caps.isNotEmpty) 'caps': caps,
        'icon': icon,
        if (agri) 'dom': domain,
      };
}
