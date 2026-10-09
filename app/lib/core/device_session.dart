import 'dart:async';

import 'package:flutter/foundation.dart';

import 'diag_log.dart';
import 'errors.dart';
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

/// Loai thong bao thanh cong; UI doi sang chu theo ngon ngu dang chon
enum MsgKind { saved, interfaceReloaded, commandSent, turnedOn, turnedOff, changedTo }

/// Kho lich su bieu do theo thiet bi, song suot luc app con chay: thoat man Thiet bi roi vao lai
/// (hoac ket noi lai) van con duong cu. Moi truong giu toi da 1 gio (DeviceSession.trendWindow).
class TrendStore {
  static final TrendStore instance = TrendStore();
  final Map<String, Map<String, List<TrendPoint>>> _byDevice = {};

  Map<String, List<TrendPoint>> of(String deviceId) => _byDevice.putIfAbsent(deviceId, () => {});

  void clear() => _byDevice.clear();
}

/// Thong bao mot lan cho nguoi dung (SnackBar): thanh cong ([kind]) hoac loi ([error])
class SessionMessage {
  final MsgKind? kind;
  final AppError? error;

  /// Nhan cua truong lien quan
  final String label;

  /// Gia tri moi (chi voi changedTo)
  final String value;
  const SessionMessage.done(MsgKind this.kind, {this.label = '', this.value = ''}) : error = null;
  const SessionMessage.failed(AppError this.error)
      : kind = null,
        label = '',
        value = '';
  bool get ok => error == null;
}

/// Mot phien lam viec voi mot thiet bi: info, schema, VALUES, lich su trend,
/// gia tri dang sua, gui lenh, tu ket noi lai. UI chi doc lop nay.
class DeviceSession extends ChangeNotifier {
  static const Duration trendWindow = Duration(hours: 1);

  /// Qua khoang nay khong co VALUES moi: hien "updated N s ago"
  static const Duration ageShownAfter = Duration(seconds: 5);

  /// Qua khoang nay khong co VALUES moi: coi so lieu la cu (chu vang, so mo di)
  static const Duration staleAfter = Duration(seconds: 15);

  final TransportConnector connector;
  final List<Duration> reconnectDelays;

  /// Ten hien truoc khi doc duoc INFO
  final String title;

  /// Dia chi thiet bi (MAC); null voi thiet bi mau
  final String? deviceId;

  /// Doc cuong do song (dBm) cua ket noi hien tai; null neu khong ho tro
  final Future<int?> Function()? rssiReader;

  LinkStatus status = LinkStatus.closed;
  AppError? error;
  VphInfo? info;
  List<VphScreen> screens = const [];
  Map<String, dynamic> values = {};
  int current = 0;
  bool hasEverConnected = false;
  DeviceTransport? transport;

  /// Lich su cac truong co goi y trend (RAM, toi da 1 gio). Thiet bi that: lay tu TrendStore
  /// theo deviceId nen khong mat khi thoat man roi vao lai. Thiet bi mau: rieng cua phien.
  late final Map<String, List<TrendPoint>> trends;

  /// Thoi diem nhan goi VALUES gan nhat
  DateTime? lastValuesAt;
  final DateTime Function() _clock;

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
    this.deviceId,
    this.rssiReader,
    DateTime Function()? clock,
    TrendStore? trendStore,
    this.reconnectDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ],
  }) : _clock = clock ?? DateTime.now {
    final id = deviceId;
    trends = id == null ? {} : (trendStore ?? TrendStore.instance).of(id);
  }

  /// Da bao lau khong co VALUES moi; null khi chua nhan goi nao
  Duration? get dataAge {
    final t = lastValuesAt;
    return t == null ? null : _clock().difference(t);
  }

  /// Dang ket noi nhung so lieu da cu (qua staleAfter khong co goi moi)
  bool get stale => ready && (dataAge ?? Duration.zero) > staleAfter;

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

  void _done(MsgKind kind, {String label = '', String value = ''}) {
    if (!_messages.isClosed) _messages.add(SessionMessage.done(kind, label: label, value: value));
  }

  void _fail(AppError e) {
    logVph('LOI ${e.kind.name}${e.deviceText != null ? ' "${e.deviceText}"' : ''}${e.detail != null ? ' | ${e.detail}' : ''}');
    if (!_messages.isClosed) _messages.add(SessionMessage.failed(e));
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
    logVph('${hasEverConnected ? 'Ket noi lai' : 'Ket noi'} ${deviceId ?? title}');
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
      logVph('Da ket noi ${i.name} model=${i.model} fw=${i.fw} proto=${t.protoId} man=${screens.length} mtu=${t.stats.mtu}'
          ' schema=${t.stats.schemaFromCache ? 'cache' : 'thiet bi'}');
      notifyListeners();
      return true;
    } catch (e) {
      if (gen != _gen) return false;
      error = AppError.from(e, fallback: ErrorKind.unreachable);
      logVph('Ket noi loi ${error!.kind.name} | $e');
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
    logVph('Mat ket noi ${deviceId ?? title}, se thu lai ${reconnectDelays.length} lan');
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
    logVph('Khong ket noi lai duoc ${deviceId ?? title}');
    status = LinkStatus.failed;
    notifyListeners();
  }

  /// Ngat ket noi do nguoi dung, khong tu ket noi lai
  Future<void> close() async {
    _gen++;
    logVph('Ngat ket noi ${deviceId ?? title} (nguoi dung)');
    await _teardown();
    status = LinkStatus.closed;
    notifyListeners();
  }

  // ---------- Du lieu ----------

  VphField? fieldById(String id) => _fieldById[id];

  void _onValues(Map<String, dynamic> m) {
    values = {...values, ...m};
    final now = _clock();
    lastValuesAt = now;
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
      _fail(AppError.from(e));
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
      _fail(const AppError(ErrorKind.notConnected));
      return;
    }
    if (busy.contains(f.id)) return;
    busy.add(f.id);
    if (f.type != 'act') _pending[f.id] = v;
    notifyListeners();
    final r = await t.write(f.id, f.type == 'act' ? 1 : v);
    // Nhat ky: id va gia tri; khong ghi noi dung chuoi nguoi dung nhap
    logVph('GHI ${f.id}=${f.type == 'act' ? 1 : logValue(f.type, v)} -> ${r.ok ? 'ok' : 'loi'}');
    busy.remove(f.id);
    _pending.remove(f.id);
    if (r.ok) {
      if (f.type == 'act') {
        _done(MsgKind.commandSent, label: f.label);
      } else {
        values = {...values, f.id: v};
        if (f.type == 'bool') {
          _done(asBool(v) == true ? MsgKind.turnedOn : MsgKind.turnedOff, label: f.label);
        } else if (f.type == 'enum') {
          _done(MsgKind.changedTo, label: f.label, value: f.optionLabel(v) ?? '$v');
        }
      }
    } else {
      // Loi: bo gia tri tam, o tro ve gia tri thiet bi
      _fail(r.error ?? const AppError(ErrorKind.rejected));
    }
    notifyListeners();
  }

  Future<bool> saveBatch(int screen) async {
    final d = drafts[screen];
    final t = transport;
    if (d == null || d.isEmpty) return true;
    if (t == null || !ready) {
      _fail(const AppError(ErrorKind.notConnected));
      return false;
    }
    if (saving) return false;
    saving = true;
    notifyListeners();
    final set = Map<String, dynamic>.from(d);
    final r = await t.writeBatch(set);
    logVph('GHI LO ${[for (final e in set.entries) '${e.key}=${logValue(_fieldById[e.key]?.type, e.value)}'].join(' ')}'
        ' -> ${r.ok ? 'ok' : 'loi'}');
    saving = false;
    if (r.ok) {
      values = {...values, ...set};
      drafts.remove(screen);
      _done(MsgKind.saved);
    } else {
      _fail(r.error ?? const AppError(ErrorKind.rejected));
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
      _fail(const AppError(ErrorKind.notConnected));
      return;
    }
    try {
      _setScreens(await t.loadScreens(refresh: true));
      drafts.clear();
      if (current >= screens.length) current = 0;
      if (screens.isNotEmpty) await t.select(current);
      _done(MsgKind.interfaceReloaded);
    } catch (e) {
      _fail(AppError.from(e));
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
