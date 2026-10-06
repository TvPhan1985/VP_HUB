import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Kho khoa-gia tri don gian (de test khong can SharedPreferences)
abstract class KvStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class MemoryStore implements KvStore {
  final Map<String, String> data = {};

  @override
  String? getString(String key) => data[key];

  @override
  Future<void> setString(String key, String value) async => data[key] = value;

  @override
  Future<void> remove(String key) async => data.remove(key);
}

class PrefsStore implements KvStore {
  final SharedPreferences prefs;
  PrefsStore(this.prefs);

  @override
  String? getString(String key) => prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => prefs.setString(key, value);

  @override
  Future<void> remove(String key) => prefs.remove(key);
}

/// Cache chuoi schema tho cua tung man hinh, khoa theo model+sch (hoac model+fw voi doi cu)
class SchemaCache {
  final KvStore store;
  SchemaCache(this.store);

  static String _k(String key) => 'schema:$key';

  List<String>? get(String key) {
    final s = store.getString(_k(key));
    if (s == null) return null;
    try {
      final j = jsonDecode(s);
      if (j is List && j.isNotEmpty && j.every((e) => e is String)) return j.cast<String>();
    } catch (_) {}
    return null;
  }

  Future<void> put(String key, List<String> screens) => store.setString(_k(key), jsonEncode(screens));

  Future<void> remove(String key) => store.remove(_k(key));
}
