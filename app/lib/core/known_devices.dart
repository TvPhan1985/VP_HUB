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

  /// Ten do nguoi dung dat trong app: khong ghi de bang ten quang ba khi ket noi lai
  final bool alias;
  const KnownDevice({
    required this.id,
    required this.name,
    this.model = '',
    this.icon = 'generic',
    this.legacy = false,
    this.lastMs = 0,
    this.alias = false,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'model': model, 'icon': icon, 'legacy': legacy, 'last': lastMs, if (alias) 'alias': true};

  static KnownDevice? fromJson(dynamic j) {
    if (j is! Map || j['id'] is! String) return null;
    return KnownDevice(
      id: j['id'] as String,
      name: j['name'] is String ? j['name'] as String : j['id'] as String,
      model: j['model'] is String ? j['model'] as String : '',
      icon: j['icon'] is String ? j['icon'] as String : 'generic',
      legacy: j['legacy'] == true,
      lastMs: j['last'] is num ? (j['last'] as num).toInt() : 0,
      alias: j['alias'] == true,
    );
  }
}

/// Danh sach thiet bi da dung (toi da 20, moi nhat dung truoc)
class KnownDevices {
  static const int maxDevices = 20;
  static const _kList = 'known_devices';

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

  /// Dat lai mot thiet bi vao dung vi tri cu (hoan tac xoa)
  Future<void> insertAt(int index, KnownDevice d) async {
    final l = list()..removeWhere((e) => e.id == d.id);
    l.insert(index.clamp(0, l.length), d);
    await _save(l);
  }

  /// Doi ten hien thi trong app (khong doi ten quang ba cua thiet bi)
  Future<void> rename(String id, String name) async {
    final l = list();
    final i = l.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final d = l[i];
    l[i] = KnownDevice(id: d.id, name: name, model: d.model, icon: d.icon, legacy: d.legacy, lastMs: d.lastMs, alias: true);
    await _save(l);
  }
}
