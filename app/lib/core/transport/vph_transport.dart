import 'dart:async';
import 'dart:convert';

import '../errors.dart';
import '../model/vph_info.dart';
import '../model/vph_schema.dart';
import '../model/vph_value.dart';
import '../schema_cache.dart';
import 'gatt_link.dart';
import 'transport.dart';
import 'uuids.dart';

/// Giao thuc VPH v1 that (PROTOCOL §9)
class VphTransport implements DeviceTransport {
  static const int supportedPv = 1;
  static const int pageSize = 480;
  static const int maxPages = 8;
  /// PROTOCOL §8 (v1.1). Goi dai hon MTU-3: Android tu gui bang long write (SPEC §11.49).
  static const int maxWrite = 500;

  final GattLink link;
  final SchemaCache cache;
  final int Function() _epochNow;

  /// Cho RESULT toi da 3 giay (PROTOCOL §6.4)
  final Duration resultTimeout;

  VphInfo? _info;
  int _q = 0;
  final Map<int, Completer<VphResult>> _pending = {};
  final StreamController<Map<String, dynamic>> _values = StreamController.broadcast();

  @override
  final TransportStats stats = TransportStats();

  VphTransport(this.link, this.cache, {int Function()? epochNow, this.resultTimeout = const Duration(seconds: 3)})
      : _epochNow = epochNow ?? (() => DateTime.now().millisecondsSinceEpoch ~/ 1000);

  @override
  String get protoId => 'VPH v${_info?.pv ?? supportedPv}';

  @override
  bool get legacy => false;

  @override
  Stream<Map<String, dynamic>> get values => _values.stream;

  @override
  Stream<void> get lost => link.lost;

  @override
  Future<VphInfo> open() async {
    stats.mtu = link.mtu;
    final raw = await link.read(kVphInfo);
    try {
      _info = VphInfo.fromJson(jsonDecode(utf8.decode(raw)) as Map<String, dynamic>);
    } catch (e) {
      throw AppError(ErrorKind.badData, 'INFO: $e');
    }
    return _info!;
  }

  String _cacheKey(VphInfo i) => 'vph/${i.model}/${i.sch}';

  @override
  Future<List<VphScreen>> loadScreens({bool refresh = false}) async {
    final info = _info!;
    List<String>? jsons;
    stats.schemaFromCache = false;
    if (!refresh && info.sch != null) {
      jsons = cache.get(_cacheKey(info));
      if (jsons != null && jsons.length != info.n) jsons = null;
      stats.schemaFromCache = jsons != null;
    }
    if (jsons == null) {
      jsons = [for (var i = 0; i < info.n; i++) await _readSchema(i)];
      if (info.sch != null) await cache.put(_cacheKey(info), jsons);
    }
    return [for (var i = 0; i < jsons.length; i++) VphScreen.tryParse(jsons[i], index: i)];
  }

  /// Doc schema theo trang (PROTOCOL §8.1): dung khi trang nhan duoc < 480 byte
  Future<String> _readSchema(int screen) async {
    final bytes = <int>[];
    for (var page = 0; page < maxPages; page++) {
      await link.write(kVphSelect, [screen, page]);
      final part = await link.read(kVphSchema);
      bytes.addAll(part);
      if (part.length < pageSize) break;
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  @override
  Future<void> start() async {
    await link.subscribe(kVphResult, _onResult);
    await link.subscribe(kVphValues, _onValues);
    if (_info?.hasTime ?? false) await write('_time', _epochNow());
  }

  void _onValues(List<int> data) {
    if (data.length > stats.maxValuesLen) stats.maxValuesLen = data.length;
    try {
      final j = jsonDecode(utf8.decode(data));
      if (j is! Map<String, dynamic>) throw const FormatException();
      stats.valuesCount++;
      if (!_values.isClosed) _values.add(j);
    } catch (_) {
      // Goi bi cat hoac hong: bo qua, dem lai de canh bao (SPEC §7)
      stats.badPackets++;
    }
  }

  void _onResult(List<int> data) {
    try {
      final j = jsonDecode(utf8.decode(data));
      if (j is! Map) return;
      final q = j['q'];
      final c = q is num ? _pending.remove(q.toInt()) : null;
      if (c == null || c.isCompleted) return;
      final ok = j['ok'] == 1 || j['ok'] == true;
      c.complete(ok
          ? const VphResult.ok()
          : VphResult.fail(j['err'] is String ? AppError.device(j['err'] as String) : const AppError(ErrorKind.rejected)));
    } catch (_) {}
  }

  @override
  Future<void> select(int screen) async {
    await link.write(kVphSelect, [screen]);
    _onValues(await link.read(kVphValues));
  }

  @override
  Future<VphResult> write(String id, dynamic v) => _send({'id': id, 'v': v});

  @override
  Future<VphResult> writeBatch(Map<String, dynamic> set) => _send({'set': set});

  Future<VphResult> _send(Map<String, dynamic> body) async {
    _q = _q >= 65535 ? 1 : _q + 1;
    final q = _q;
    final payload = utf8.encode(jsonEncode({'q': q, ...body}));
    if (payload.length > maxWrite) {
      return VphResult.fail(AppError(ErrorKind.tooLong, 'WRITE ${payload.length} byte, max $maxWrite'));
    }
    final c = Completer<VphResult>();
    _pending[q] = c;
    try {
      await link.write(kVphWrite, payload);
      return await c.future.timeout(resultTimeout);
    } on TimeoutException {
      return const VphResult.fail(AppError(ErrorKind.noResponse));
    } catch (e) {
      return VphResult.fail(AppError.from(e));
    } finally {
      _pending.remove(q);
    }
  }

  @override
  Future<void> close() async {
    for (final c in _pending.values) {
      if (!c.isCompleted) c.complete(const VphResult.fail(AppError(ErrorKind.notConnected)));
    }
    _pending.clear();
    await link.disconnect();
    await _values.close();
  }
}
