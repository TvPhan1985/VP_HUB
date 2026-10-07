import 'dart:async';

import 'package:flutter/foundation.dart';

import '../l10n/strings_vi.dart';
import 'model/vph_info.dart';
import 'model/vph_schema.dart';
import 'model/vph_value.dart';
import 'transport/transport.dart';

enum LinkStatus { connecting, loading, ready, reconnecting, failed, closed }

/// Ham tao duong truyen moi (ket noi BLE roi chon transport, hoac tao demo)
typedef TransportConnector = Future<DeviceTransport> Function();

class TrendPoint {
  final DateTime t;
  final double v;
  const TrendPoint(this.t, this.v);
}

/// Thong bao mot lan cho nguoi dung (SnackBar)
class SessionMessage {
  final bool ok;
  final String text;
  const SessionMessage(this.ok, this.text);
}

/// Mot phien lam viec voi mot thiet bi: info, schema, VALUES, lich su trend,
/// gia tri dang sua, gui lenh, tu ket noi lai. UI chi doc lop nay.
class DeviceSession extends ChangeNotifier {
  static const Duration trendWindow = Duration(hours: 1);

  final TransportConnector connector;
  final List<Duration> reconnectDelays;

  /// Ten hien truoc khi doc duoc INFO
  final String title;

  LinkStatus status = LinkStatus.closed;
  String? error;
  VphInfo? info;
  List<VphScreen> screens = const [];
  Map<String, dynamic> values = {};
  int current = 0;
  bool hasEverConnected = false;
  DeviceTransport? transport;

  /// Lich su cac truong co goi y trend (RAM, toi da 1 gio)
  final Map<String, List<TrendPoint>> trends = {};

  /// Cac truong dang cho RESULT
  final Set<String> busy = {};

  /// Gia tri tam cua man batch: chi so man hinh -> {id: gia tri}
  final Map<int, Map<String, dynamic>> drafts = {};
  bool saving = false;

  final Map<String, dynamic> _pending = {};
  final Map<String, VphField> _fieldById = {};
  final StreamController<SessionMessage> _messages = StreamController.broadcast();
  StreamSubscription? _valuesSub, _lostSub;
  int _gen = 0;
  bool _disposed = false;

  DeviceSession({
    required this.connector,
    this.title = '',
    this.reconnectDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ],
  });

  Stream<SessionMessage> get messages => _messages.stream;
  bool get ready => status == LinkStatus.ready;

  String get displayName {
    final n = values['_name'];
    if (n is String && n.isNotEmpty) return n;
    return info?.name ?? title;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void _say(bool ok, String text) {
    if (!_messages.isClosed) _messages.add(SessionMessage(ok, text));
  }

  static String _short(Object e) {
    var s = e.toString();
    if (s.startsWith('Exception: ')) s = s.substring(11);
    return s.length > 160 ? '${s.substring(0, 160)}...' : s;
  }

  // ---------- Ket noi ----------

  /// Ket noi lan dau, hoac thu lai sau khi that bai
  Future<void> connect() async {
    final gen = ++_gen;
    await _connectOnce(gen);
  }

  Future<bool> _connectOnce(int gen) async {
    status = hasEverConnected ? LinkStatus.reconnecting : LinkStatus.connecting;
    error = null;
    notifyListeners();
    DeviceTransport? t;
    try {
      t = await connector();
      if (gen != _gen) {
        await t.close();
        return false;
      }
      transport = t;
      final i = await t.open();
      info = i;
      if (!hasEverConnected) {
        status = LinkStatus.loading;
        notifyListeners();
      }
      final scr = await t.loadScreens();
      _setScreens(scr);
      await _valuesSub?.cancel();
      await _lostSub?.cancel();
      _valuesSub = t.values.listen(_onValues);
      _lostSub = t.lost.listen((_) => _onLost(gen));
      await t.start();
      if (current >= screens.length) current = 0;
      if (screens.isNotEmpty) await t.select(current);
      if (gen != _gen) return false;
      status = LinkStatus.ready;
      hasEverConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('VPHUB Ket noi loi: $e');
      if (gen != _gen) return false;
      error = _short(e);
      await _teardown();
      status = LinkStatus.failed;
      notifyListeners();
      return false;
    }
  }

  void _setScreens(List<VphScreen> scr) {
    screens = scr;
    _fieldById.clear();
    for (final s in scr) {
      for (final f in s.allFields) {
        _fieldById.putIfAbsent(f.id, () => f);
      }
    }
  }

  Future<void> _teardown() async {
    await _valuesSub?.cancel();
    await _lostSub?.cancel();
    _valuesSub = _lostSub = null;
    final t = transport;
    transport = null;
    busy.clear();
    _pending.clear();
    saving = false;
    if (t != null) {
      try {
        await t.close();
      } catch (_) {}
    }
  }

  Future<void> _onLost(int gen) async {
    if (gen != _gen || _disposed) return;
    final myGen = ++_gen;
    await _teardown();
    status = LinkStatus.reconnecting;
    notifyListeners();
    // Thu lai voi do tre 1, 2, 5, 10 s roi dung, cho nguoi dung bam "Thu lai"
    for (final d in reconnectDelays) {
      await Future.delayed(d);
      if (myGen != _gen || _disposed) return;
      if (await _connectOnce(myGen)) return;
      if (myGen != _gen || _disposed) return;
      status = LinkStatus.reconnecting;
      notifyListeners();
    }
    status = LinkStatus.failed;
    notifyListeners();
  }

  /// Ngat ket noi do nguoi dung, khong tu ket noi lai
  Future<void> close() async {
    _gen++;
    await _teardown();
    status = LinkStatus.closed;
    notifyListeners();
  }

  // ---------- Du lieu ----------

  VphField? fieldById(String id) => _fieldById[id];

  void _onValues(Map<String, dynamic> m) {
    values = {...values, ...m};
    final now = DateTime.now();
    for (final e in m.entries) {
      final f = _fieldById[e.key];
      if (f == null || !f.hint('trend') || e.value is! num) continue;
      final list = trends.putIfAbsent(e.key, () => []);
      list.add(TrendPoint(now, (e.value as num).toDouble()));
      final cut = now.subtract(trendWindow);
      while (list.isNotEmpty && list.first.t.isBefore(cut)) {
        list.removeAt(0);
      }
    }
    notifyListeners();
  }

  /// Gia tri de hien: ban nhap (batch) > gia tri dang gui > gia tri thiet bi
  dynamic valueOf(int screen, String id) {
    final d = drafts[screen];
    if (d != null && d.containsKey(id)) return d[id];
    if (_pending.containsKey(id)) return _pending[id];
    return values[id];
  }

  bool isDraft(int screen, String id) => drafts[screen]?.containsKey(id) ?? false;
  int draftCount(int screen) => drafts[screen]?.length ?? 0;

  Future<void> selectScreen(int i) async {
    if (i == current && ready) return;
    current = i;
    notifyListeners();
    final t = transport;
    if (t == null || !ready) return;
    try {
      await t.select(i);
    } catch (e) {
      _say(false, S.selectFailed(_short(e)));
    }
  }

  /// Nguoi dung doi mot truong. Man batch thi giu tam, man live thi gui ngay.
  /// Nut lenh (act) luon gui ngay.
  Future<void> edit(int screen, VphField f, dynamic v) async {
    final batch = screen >= 0 && screen < screens.length && screens[screen].batch;
    if (batch && f.type != 'act') {
      final d = drafts.putIfAbsent(screen, () => {});
      if (sameValue(v, values[f.id])) {
        d.remove(f.id);
        if (d.isEmpty) drafts.remove(screen);
      } else {
        d[f.id] = v;
      }
      notifyListeners();
      return;
    }
    await _sendLive(f, v);
  }

  Future<void> _sendLive(VphField f, dynamic v) async {
    final t = transport;
    if (t == null || !ready) {
      _say(false, S.notConnected);
      return;
    }
    if (busy.contains(f.id)) return;
    busy.add(f.id);
    if (f.type != 'act') _pending[f.id] = v;
    notifyListeners();
    final r = await t.write(f.id, f.type == 'act' ? 1 : v);
    busy.remove(f.id);
    _pending.remove(f.id);
    if (r.ok) {
      if (f.type == 'act') {
        _say(true, S.sent(f.label));
      } else {
        values = {...values, f.id: v};
        if (f.type == 'bool') {
          _say(true, asBool(v) == true ? S.turnedOn(f.label) : S.turnedOff(f.label));
        } else if (f.type == 'enum') {
          _say(true, S.changedTo(f.label, f.optionLabel(v) ?? '$v'));
        }
      }
    } else {
      // Loi: bo gia tri tam, o tro ve gia tri thiet bi
      _say(false, r.err ?? S.deviceRefused);
    }
    notifyListeners();
  }

  Future<bool> saveBatch(int screen) async {
    final d = drafts[screen];
    final t = transport;
    if (d == null || d.isEmpty) return true;
    if (t == null || !ready) {
      _say(false, S.notConnected);
      return false;
    }
    if (saving) return false;
    saving = true;
    notifyListeners();
    final set = Map<String, dynamic>.from(d);
    final r = await t.writeBatch(set);
    saving = false;
    if (r.ok) {
      values = {...values, ...set};
      drafts.remove(screen);
      _say(true, S.saved);
    } else {
      _say(false, r.err ?? S.deviceRefused);
    }
    notifyListeners();
    return r.ok;
  }

  void discardBatch(int screen) {
    if (drafts.remove(screen) != null) notifyListeners();
  }

  /// Bo cache, doc lai schema tu thiet bi
  Future<void> reloadSchema() async {
    final t = transport;
    if (t == null || !ready) {
      _say(false, S.notConnected);
      return;
    }
    try {
      _setScreens(await t.loadScreens(refresh: true));
      drafts.clear();
      if (current >= screens.length) current = 0;
      if (screens.isNotEmpty) await t.select(current);
      _say(true, S.schemaReloaded);
    } catch (e) {
      _say(false, _short(e));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _gen++;
    unawaited(_teardown());
    unawaited(_messages.close());
    super.dispose();
  }
}
