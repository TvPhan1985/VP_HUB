import 'dart:convert';

import 'schema_cache.dart';

/// Mot thiet bi da tung ket noi
class KnownDevice {
  final String id;
  final String name;
  final String model;
  final String icon;
  final bool legacy;
  final int lastMs;
  const KnownDevice({
    required this.id,
    required this.name,
    this.model = '',
    this.icon = 'generic',
    this.legacy = false,
    this.lastMs = 0,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'model': model, 'icon': icon, 'legacy': legacy, 'last': lastMs};

  static KnownDevice? fromJson(dynamic j) {
    if (j is! Map || j['id'] is! String) return null;
    return KnownDevice(
      id: j['id'] as String,
      name: j['name'] is String ? j['name'] as String : j['id'] as String,
      model: j['model'] is String ? j['model'] as String : '',
      icon: j['icon'] is String ? j['icon'] as String : 'generic',
      legacy: j['legacy'] == true,
      lastMs: j['last'] is num ? (j['last'] as num).toInt() : 0,
    );
  }
}

/// Danh sach thiet bi da dung (toi da 20, moi nhat dung truoc) va tuy chon tu ket noi
class KnownDevices {
  static const int maxDevices = 20;
  static const _kList = 'known_devices';
  static const _kAuto = 'auto_connect';

  final KvStore store;
  KnownDevices(this.store);

  List<KnownDevice> list() {
    final s = store.getString(_kList);
    if (s == null) return [];
    try {
      final j = jsonDecode(s);
      if (j is! List) return [];
      return [for (final e in j) ?KnownDevice.fromJson(e)];
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<KnownDevice> l) => store.setString(_kList, jsonEncode([for (final d in l) d.toJson()]));

  Future<void> remember(KnownDevice d) async {
    final l = list()..removeWhere((e) => e.id == d.id);
    l.insert(0, d);
    if (l.length > maxDevices) l.removeRange(maxDevices, l.length);
    await _save(l);
  }

  Future<void> forget(String id) async => _save(list()..removeWhere((e) => e.id == id));

  /// Mac dinh bat (SPEC §3)
  bool get autoConnect => store.getString(_kAuto) != '0';

  Future<void> setAutoConnect(bool v) => store.setString(_kAuto, v ? '1' : '0');
}
