import 'package:flutter/material.dart';

import 'schema_cache.dart';

/// Hai che do nguoi dung (SPEC §11.50). Standard: nguoi van hanh. Technician: nguoi ky thuat.
/// An trong app chi de giao dien gon, KHONG phai bao mat: firmware van kiem tra moi lenh ghi.
enum UserMode { standard, technician }

/// Cai dat cua app, luu trong kho cua app; doi la ap dung ngay, khong can mo lai app.
class AppSettings extends ChangeNotifier {
  static const _kTheme = 'theme';
  static const _kLang = 'lang';
  static const _kMode = 'user_mode';
  static const _kPin = 'tech_pin';
  static const _kAuto = 'auto_connect';
  static const _kAwake = 'keep_awake';
  static const _kAddr = 'show_addr';
  static const _kOnboarded = 'onboarded';

  final KvStore store;
  ThemeMode _mode;
  UserMode _userMode;
  String _lang;

  AppSettings(this.store)
      : _mode = _parseTheme(store.getString(_kTheme)),
        _userMode = store.getString(_kMode) == 'technician' ? UserMode.technician : UserMode.standard,
        // Mac dinh tieng Anh, khong theo ngon ngu cua may; nguoi dung tu chon Tieng Viet
        _lang = store.getString(_kLang) == 'vi' ? 'vi' : 'en';

  static ThemeMode _parseTheme(String? s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  bool _flag(String key, bool def) {
    final s = store.getString(key);
    return s == null ? def : s == '1';
  }

  // ----- Giao dien, ngon ngu -----

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode m) async {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
    await store.setString(_kTheme, m.name);
  }

  /// Ma ngon ngu cua app: 'en' (mac dinh) | 'vi'
  String get lang => _lang;
  Locale get locale => Locale(_lang);

  Future<void> setLang(String code) async {
    final c = code == 'vi' ? 'vi' : 'en';
    if (c == _lang) return;
    _lang = c;
    // MaterialApp nghe lop nay va doi `locale`: ca cay widget tu ve lai
    notifyListeners();
    await store.setString(_kLang, c);
  }

  // ----- Che do nguoi dung -----

  UserMode get userMode => _userMode;
  bool get technician => _userMode == UserMode.technician;

  /// PIN 4 so (tuy chon). null = khong dat PIN.
  String? get pin {
    final p = store.getString(_kPin);
    return p != null && p.isNotEmpty ? p : null;
  }

  bool get hasPin => pin != null;

  static bool validPin(String s) => RegExp(r'^\d{4}$').hasMatch(s);

  /// Bat Technician: co PIN thi phai dua dung PIN. Tat thi khong hoi. Tra false neu PIN sai.
  Future<bool> setTechnician(bool on, {String? pin}) async {
    if (on && hasPin && pin != this.pin) return false;
    final m = on ? UserMode.technician : UserMode.standard;
    if (m == _userMode) return true;
    _userMode = m;
    notifyListeners();
    await store.setString(_kMode, m.name);
    return true;
  }

  Future<void> setPin(String? pin) async {
    if (pin == null) {
      await store.remove(_kPin);
    } else {
      if (!validPin(pin)) throw ArgumentError('PIN phai la 4 chu so');
      await store.setString(_kPin, pin);
    }
    notifyListeners();
  }

  // ----- Tuy chon khac -----

  /// Tu ket noi thiet bi da nho gan nhat khi mo app (mac dinh bat)
  bool get autoConnect => _flag(_kAuto, true);
  Future<void> setAutoConnect(bool v) => _setFlagNow(_kAuto, v);

  /// Giu man hinh sang khi dang ket noi (mac dinh tat)
  bool get keepScreenOn => _flag(_kAwake, false);
  Future<void> setKeepScreenOn(bool v) => _setFlagNow(_kAwake, v);

  /// Hien dia chi MAC tren the thiet bi (chi co nghia o Technician, mac dinh bat)
  bool get showAddresses => _flag(_kAddr, true);
  Future<void> setShowAddresses(bool v) => _setFlagNow(_kAddr, v);

  /// Da qua man gioi thieu lan dau
  bool get onboarded => _flag(_kOnboarded, false);
  Future<void> setOnboarded() => _setFlagNow(_kOnboarded, true);

  Future<void> _setFlagNow(String key, bool v) async {
    await store.setString(key, v ? '1' : '0');
    notifyListeners();
  }
}

/// Dua AppSettings xuong cay widget
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({super.key, required AppSettings settings, required super.child}) : super(notifier: settings);

  static AppSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()?.notifier;

  /// Dang o che do Technician. Khong co SettingsScope (vd trong test) -> Standard.
  static bool technician(BuildContext context) => maybeOf(context)?.technician ?? false;
}
