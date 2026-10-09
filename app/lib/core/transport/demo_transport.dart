import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../l10n/strings.dart';
import '../model/vph_info.dart';
import '../model/vph_schema.dart';
import '../model/vph_value.dart';
import 'transport.dart';

/// Thiet bi gia doc tu file JSON (SPEC §6): {"info":{...},"screens":[...],"values":{...}}
/// VALUES doi ngau nhien nhe moi giay, lenh ghi luon ok.
class DemoTransport implements DeviceTransport {
  final VphInfo _info;
  final List<VphScreen> _screens;
  final Map<String, dynamic> _state;
  final Duration? tick;
  final Random _rnd;
  final StreamController<Map<String, dynamic>> _values = StreamController.broadcast();
  final StreamController<void> _lost = StreamController.broadcast();
  Timer? _timer;
  int _selected = 0;

  /// Lenh ghi da nhan (de test kiem tra)
  final List<Map<String, dynamic>> writes = [];

  @override
  final TransportStats stats = TransportStats();

  DemoTransport._(this._info, this._screens, this._state, this.tick, int? seed) : _rnd = Random(seed);

  /// Nem FormatException (thong bao tieng Viet) neu file sai dinh dang
  factory DemoTransport.fromJson(String src, {Duration? tick = const Duration(seconds: 1), int? seed}) {
    dynamic j;
    try {
      j = jsonDecode(src);
    } catch (e) {
      throw FormatException(S.errFileFormat);
    }
    if (j is! Map || j['screens'] is! List) throw FormatException(S.errFileFormat);
    final rawScreens = j['screens'] as List;
    final screens = [for (var i = 0; i < rawScreens.length; i++) VphScreen.tryFromMap(rawScreens[i], index: i)];
    final infoJson = <String, dynamic>{
      'proto': 'vph',
      'pv': 1,
      'model': 'demo',
      'name': 'DEMO',
      'fw': '0.0.0',
      if (j['info'] is Map) ...Map<String, dynamic>.from(j['info'] as Map),
      'n': screens.length,
    };
    final VphInfo info;
    try {
      info = VphInfo.fromJson(infoJson);
    } catch (e) {
      throw FormatException(S.errFileFormat);
    }
    final values = j['values'] is Map ? Map<String, dynamic>.from(j['values'] as Map) : <String, dynamic>{};
    return DemoTransport._(info, screens, values, tick, seed);
  }

  @override
  String get protoLabel => S.protoDemo;

  @override
  bool get legacy => false;

  @override
  Stream<Map<String, dynamic>> get values => _values.stream;

  @override
  Stream<void> get lost => _lost.stream;

  @override
  Future<VphInfo> open() async => _info;

  @override
  Future<List<VphScreen>> loadScreens({bool refresh = false}) async => _screens;

  @override
  Future<void> start() async {
    _timer?.cancel();
    if (tick != null) _timer = Timer.periodic(tick!, (_) => step());
  }

  /// Mot nhip gia lap: lam nhieu cac so chi doc roi phat VALUES cua man dang chon
  void step() {
    for (final s in _screens) {
      for (final f in s.allFields) {
        final v = _state[f.id];
        if (f.type != 'num' || !f.readOnly || v is! num) continue;
        final dec = f.decimals ?? 1;
        if (dec == 0) continue;
        var nv = v + (_rnd.nextDouble() - 0.5) * 6 * pow(10, -dec);
        if (f.min != null && nv < f.min!) nv = f.min!;
        if (f.max != null && nv > f.max!) nv = f.max!;
        _state[f.id] = roundTo(nv.toDouble(), dec.clamp(0, 2));
      }
    }
    _emit();
  }

  void _emit() {
    if (_values.isClosed || _screens.isEmpty) return;
    final ids = <String>{
      ..._screens[_selected.clamp(0, _screens.length - 1)].allFields.map((f) => f.id),
      ..._info.hdr,
    };
    final out = <String, dynamic>{for (final id in ids) if (_state.containsKey(id)) id: _state[id]};
    stats.valuesCount++;
    final len = utf8.encode(jsonEncode(out)).length;
    if (len > stats.maxValuesLen) stats.maxValuesLen = len;
    _values.add(out);
  }

  @override
  Future<void> select(int screen) async {
    _selected = screen;
    _emit();
  }

  @override
  Future<VphResult> write(String id, dynamic v) async {
    writes.add({'id': id, 'v': v});
    if (_state.containsKey(id)) _state[id] = v;
    _emit();
    return const VphResult.ok();
  }

  @override
  Future<VphResult> writeBatch(Map<String, dynamic> set) async {
    writes.add({'set': Map<String, dynamic>.from(set)});
    _state.addAll(set);
    _emit();
    return const VphResult.ok();
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _timer = null;
    await _values.close();
    await _lost.close();
  }
}
