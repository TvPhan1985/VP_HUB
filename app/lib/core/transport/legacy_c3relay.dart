import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../l10n/strings.dart';
import '../model/vph_info.dart';
import '../model/vph_schema.dart';
import '../model/vph_value.dart';
import 'gatt_link.dart';
import 'transport.dart';
import 'uuids.dart';

const int kC3Slots = 5;
/// Schema luu san cua relay C3, theo ngon ngu dang dung
String c3SchemaAsset() => Lang.isVi ? 'assets/legacy/c3relay_v1.vi.json' : 'assets/legacy/c3relay_v1.json';

/// Ban tieng Viet cua cac loi kiem tra CONFIG (c3BuildConfig tra loi tieng Anh)
const Map<String, String> _c3ErrVi = {
  'Name must be 1-20 characters': 'Tên phải dài 1-20 ký tự',
  'Name must use ASCII characters only': 'Tên chỉ dùng ký tự ASCII',
  'Invalid auto source': 'Nguồn tự động sai',
  'Date must be YYYY-MM-DD': 'Ngày phải dạng YYYY-MM-DD',
  'Start date must be before end date': 'Ngày bắt đầu phải trước ngày kết thúc',
  'Time must be HH:MM': 'Giờ phải dạng HH:MM',
  'Invalid weekdays': 'Thứ trong tuần sai',
  'Invalid sensor type': 'Loại cảm biến sai',
  'Invalid threshold type': 'Kiểu ngưỡng sai',
  'Invalid threshold': 'Ngưỡng không hợp lệ',
  'On when low: on threshold must be below off threshold': 'Bật khi thấp: ngưỡng bật phải nhỏ hơn ngưỡng tắt',
  'On when high: on threshold must be above off threshold': 'Bật khi cao: ngưỡng bật phải lớn hơn ngưỡng tắt',
  'Modbus address must be 1-247': 'Địa chỉ Modbus phải 1-247',
  'Start register must be 0-65535': 'Thanh ghi đầu phải 0-65535',
  'Register count must be 1-10': 'Số thanh ghi phải 1-10',
  'Humidity / temperature index exceeds register count': 'Vị trí độ ẩm / nhiệt độ vượt quá số thanh ghi',
  'Scale divisor must be greater than 0': 'Hệ số chia phải lớn hơn 0',
  'Poll interval must be 1-3600 s': 'Chu kỳ đọc phải 1-3600 giây',
  'Invalid alarm threshold': 'Ngưỡng báo động không hợp lệ',
  'Alarm: low temperature must be below high temperature': 'Báo động: nhiệt độ thấp phải nhỏ hơn nhiệt độ cao',
  'Alarm: low humidity must be below high humidity': 'Báo động: độ ẩm thấp phải nhỏ hơn độ ẩm cao',
  'Nothing to save': 'Không có gì để lưu',
  'Name must not contain " or \\': 'Tên không được chứa " hoặc \\',
};

String? c3ErrText(String? err) => Lang.isVi ? (_c3ErrVi[err] ?? err) : err;

final RegExp _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
final RegExp _ymd = RegExp(r'^\d{4}-\d{2}-\d{2}$');

int _i(dynamic v, int def) => v is num ? v.toInt() : (v is bool ? (v ? 1 : 0) : def);
double _d(dynamic v, double def) => v is num ? v.toDouble() : def;
double _r1(double v) => (v * 10).roundToDouble() / 10;
Map<String, dynamic> _m(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// STATUS (SPEC §7 cua c3) -> phan VALUES phang
Map<String, dynamic> c3FlattenStatus(Map<String, dynamic> s) => {
      for (final k in const ['t', 'h', 'ec', 'sal', 'tds', 'alarm', 'up']) k: s[k],
      'sok': asBool(s['sok']) ?? false,
      'tok': asBool(s['tok']) ?? false,
      'out': asBool(s['out']) ?? false,
      'muted': asBool(s['muted']) ?? false,
      'time': s['time'] is String && (s['time'] as String).isNotEmpty ? s['time'] : null,
      'mode': s['mode'],
      '_name': s['name'],
      'fw': s['fw'],
    };

/// Mot khung gio: nhan ca dang mang [en,days,"on","off"] va dang object
List<dynamic> _slot(dynamic j) {
  if (j is List && j.length == 4) return [asBool(j[0]) ?? false, _i(j[1], 127), '${j[2]}', '${j[3]}'];
  if (j is Map) return [asBool(j['en']) ?? false, _i(j['days'], 127), '${j['on'] ?? '00:00'}', '${j['off'] ?? '00:00'}'];
  return [false, 127, '00:00', '00:00'];
}

/// CONFIG (SPEC §6 cua c3) -> phan VALUES phang. Luon du 5 khung gio.
Map<String, dynamic> c3FlattenConfig(Map<String, dynamic> c) {
  final auto = _m(c['auto']), sen = _m(auto['sensor']), mb = _m(c['modbus']), al = _m(c['alarm']);
  final slots = auto['slots'] is List ? auto['slots'] as List : const [];
  String? date(dynamic v) => v is String && v.isNotEmpty ? v : null;
  final out = <String, dynamic>{
    'src': auto['src'] ?? 'both',
    'date_from': date(auto['dateFrom']),
    'date_to': date(auto['dateTo']),
    'sen_type': sen['type'] ?? 'hum',
    'sen_act': sen['action'] ?? 'low',
    'on_at': _d(sen['onAt'], 70),
    'off_at': _d(sen['offAt'], 80),
    'mb_addr': _i(mb['addr'], 7),
    'mb_baud': _i(mb['baud'], 9600),
    'mb_fc': _i(mb['fc'], 3),
    'mb_start': _i(mb['start'], 0),
    'mb_count': _i(mb['count'], 5),
    'mb_idx_h': _i(mb['idxH'], 0),
    'mb_idx_t': _i(mb['idxT'], 1),
    'mb_scale': _d(mb['scale'], 10),
    'mb_period': _i(mb['periodS'], 5),
    'al_en': asBool(al['en']) ?? false,
    'al_t_lo': _d(al['tLo'], 0),
    'al_t_hi': _d(al['tHi'], 45),
    'al_h_lo': _d(al['hLo'], 0),
    'al_h_hi': _d(al['hHi'], 100),
  };
  for (var i = 1; i <= kC3Slots; i++) {
    final s = _slot(i <= slots.length ? slots[i - 1] : null);
    out['s${i}_en'] = s[0];
    out['s${i}_days'] = s[1];
    out['s${i}_on'] = s[2];
    out['s${i}_off'] = s[3];
  }
  return out;
}

/// Ket qua dung JSON CONFIG mot phan: [json] hoac [err] (tieng Viet)
class C3ConfigBuild {
  final Map<String, dynamic>? json;
  final String? err;
  const C3ConfigBuild.ok(this.json) : err = null;
  const C3ConfigBuild.fail(this.err) : json = null;
}

/// Gom cac truong doi trong [set] thanh MOT JSON CONFIG mot phan (LEGACY L1).
/// [current] la VALUES phang hien tai (tu c3FlattenConfig). Gui du object con,
/// khong gui le mot khoa cua sensor/modbus/alarm; slots luon du 5 khung.
C3ConfigBuild c3BuildConfig(Map<String, dynamic> set, Map<String, dynamic> current) {
  final v = {...current, ...set};
  final out = <String, dynamic>{};
  final auto = <String, dynamic>{};
  bool touched(bool Function(String) test) => set.keys.any(test);

  if (set.containsKey('_name')) {
    final name = '${set['_name']}'.trim();
    if (name.isEmpty || name.length > 20) return const C3ConfigBuild.fail('Name must be 1-20 characters');
    for (final c in name.codeUnits) {
      if (c < 0x20 || c > 0x7E) return const C3ConfigBuild.fail('Name must use ASCII characters only');
      if (c == 0x22 || c == 0x5C) return const C3ConfigBuild.fail('Name must not contain " or \\');
    }
    out['name'] = name;
  }

  if (set.containsKey('src')) {
    if (!const ['schedule', 'sensor', 'both'].contains(v['src'])) return const C3ConfigBuild.fail('Invalid auto source');
    auto['src'] = v['src'];
  }
  if (set.containsKey('date_from') || set.containsKey('date_to')) {
    final from = v['date_from'], to = v['date_to'];
    for (final d in [from, to]) {
      if (d != null && !(d is String && _ymd.hasMatch(d))) return const C3ConfigBuild.fail('Date must be YYYY-MM-DD');
    }
    if (from != null && to != null && (from as String).compareTo(to as String) > 0) {
      return const C3ConfigBuild.fail('Start date must be before end date');
    }
    if (set.containsKey('date_from')) auto['dateFrom'] = from;
    if (set.containsKey('date_to')) auto['dateTo'] = to;
  }
  if (touched((k) => RegExp(r'^s\d_').hasMatch(k))) {
    final slots = <List<dynamic>>[];
    for (var i = 1; i <= kC3Slots; i++) {
      final on = '${v['s${i}_on']}', off = '${v['s${i}_off']}';
      if (!_hhmm.hasMatch(on) || !_hhmm.hasMatch(off)) return const C3ConfigBuild.fail('Time must be HH:MM');
      final days = _i(v['s${i}_days'], 127);
      if (days < 0 || days > 127) return const C3ConfigBuild.fail('Invalid weekdays');
      slots.add([(asBool(v['s${i}_en']) ?? false) ? 1 : 0, days, on, off]);
    }
    auto['slots'] = slots;
  }
  if (touched((k) => k.startsWith('sen_') || k == 'on_at' || k == 'off_at')) {
    final act = v['sen_act'], type = v['sen_type'];
    final onAt = asNum(v['on_at']), offAt = asNum(v['off_at']);
    if (type != 'hum' && type != 'temp') return const C3ConfigBuild.fail('Invalid sensor type');
    if (act != 'low' && act != 'high') return const C3ConfigBuild.fail('Invalid threshold type');
    if (onAt == null || offAt == null) return const C3ConfigBuild.fail('Invalid threshold');
    if (act == 'low' && !(onAt < offAt)) {
      return const C3ConfigBuild.fail('On when low: on threshold must be below off threshold');
    }
    if (act == 'high' && !(onAt > offAt)) {
      return const C3ConfigBuild.fail('On when high: on threshold must be above off threshold');
    }
    auto['sensor'] = {'type': type, 'action': act, 'onAt': _r1(onAt), 'offAt': _r1(offAt)};
  }
  if (auto.isNotEmpty) out['auto'] = auto;

  if (touched((k) => k.startsWith('mb_'))) {
    final addr = _i(v['mb_addr'], 0), count = _i(v['mb_count'], 0);
    final idxH = _i(v['mb_idx_h'], -1), idxT = _i(v['mb_idx_t'], -1);
    final scale = asNum(v['mb_scale']) ?? 0, period = _i(v['mb_period'], 0), start = _i(v['mb_start'], -1);
    if (addr < 1 || addr > 247) return const C3ConfigBuild.fail('Modbus address must be 1-247');
    if (start < 0 || start > 65535) return const C3ConfigBuild.fail('Start register must be 0-65535');
    if (count < 1 || count > 10) return const C3ConfigBuild.fail('Register count must be 1-10');
    if (idxH < 0 || idxT < 0 || idxH >= count || idxT >= count) {
      return const C3ConfigBuild.fail('Humidity / temperature index exceeds register count');
    }
    if (!(scale > 0)) return const C3ConfigBuild.fail('Scale divisor must be greater than 0');
    if (period < 1 || period > 3600) return const C3ConfigBuild.fail('Poll interval must be 1-3600 s');
    out['modbus'] = {
      'addr': addr,
      'baud': _i(v['mb_baud'], 9600),
      'fc': _i(v['mb_fc'], 3),
      'start': start,
      'count': count,
      'idxH': idxH,
      'idxT': idxT,
      'scale': _r1(scale),
      'periodS': period,
    };
  }
  if (touched((k) => k.startsWith('al_'))) {
    final tLo = asNum(v['al_t_lo']), tHi = asNum(v['al_t_hi']), hLo = asNum(v['al_h_lo']), hHi = asNum(v['al_h_hi']);
    if (tLo == null || tHi == null || hLo == null || hHi == null) {
      return const C3ConfigBuild.fail('Invalid alarm threshold');
    }
    if (!(tLo < tHi)) return const C3ConfigBuild.fail('Alarm: low temperature must be below high temperature');
    if (!(hLo < hHi)) return const C3ConfigBuild.fail('Alarm: low humidity must be below high humidity');
    out['alarm'] = {
      'en': (asBool(v['al_en']) ?? false) ? 1 : 0,
      'tHi': _r1(tHi),
      'tLo': _r1(tLo),
      'hHi': _r1(hHi),
      'hLo': _r1(hLo),
    };
  }
  if (out.isEmpty) return const C3ConfigBuild.fail('Nothing to save');
  return C3ConfigBuild.ok(out);
}

/// Lenh CMD cho cac truong ghi truc tiep. Tra null neu truong di qua CONFIG.
Map<String, dynamic>? c3Command(String id, dynamic v) {
  switch (id) {
    case 'mode':
      return {'cmd': 'mode', 'v': v};
    case 'out':
      return {'cmd': 'out', 'v': (asBool(v) ?? false) ? 1 : 0};
    case 'silence':
      return {'cmd': 'silence'};
    case '_reboot':
      return {'cmd': 'reboot'};
    case '_time':
      return {'cmd': 'time', 'epoch': v};
  }
  return null;
}

/// Adapter cho bo relay ESP32-C3 firmware cu (LEGACY L1)
class C3RelayTransport implements DeviceTransport {
  static const int maxConfig = 500;

  final GattLink link;
  final Future<String> Function() _loadSchema;
  final int Function() _epochNow;
  final Duration resultTimeout;
  final StreamController<Map<String, dynamic>> _values = StreamController.broadcast();
  final OpQueue _ops = OpQueue();
  Completer<VphResult>? _pending;
  Map<String, dynamic> _cfgFlat = {};

  @override
  final TransportStats stats = TransportStats();

  C3RelayTransport(this.link,
      {Future<String> Function()? loadSchema,
      int Function()? epochNow,
      this.resultTimeout = const Duration(seconds: 3)})
      : _loadSchema = loadSchema ?? (() => rootBundle.loadString(c3SchemaAsset())),
        _epochNow = epochNow ?? (() => DateTime.now().millisecondsSinceEpoch ~/ 1000);

  @override
  String get protoLabel => S.protoC3;

  @override
  bool get legacy => true;

  @override
  Stream<Map<String, dynamic>> get values => _values.stream;

  @override
  Stream<void> get lost => link.lost;

  @override
  Future<VphInfo> open() async {
    stats.mtu = link.mtu;
    Map<String, dynamic> st = {};
    try {
      st = jsonDecode(utf8.decode(await link.read(kC3Status))) as Map<String, dynamic>;
    } catch (_) {}
    return VphInfo(
      model: 'c3relay',
      name: st['name'] is String ? st['name'] as String : (link.name.isNotEmpty ? link.name : 'C3-RELAY'),
      fw: st['fw'] is String ? st['fw'] as String : '?',
      hw: 'esp32c3',
      n: 4,
      hdr: const ['t', 'h', 'out', 'mode', 'alarm'],
      caps: const ['time'],
      icon: 'relay',
    );
  }

  @override
  Future<List<VphScreen>> loadScreens({bool refresh = false}) async {
    final j = jsonDecode(await _loadSchema());
    final list = j is Map && j['screens'] is List ? j['screens'] as List : const [];
    return [for (var i = 0; i < list.length; i++) VphScreen.tryFromMap(list[i], index: i)];
  }

  @override
  Future<void> start() async {
    await link.subscribe(kC3Result, _onResult);
    await link.subscribe(kC3Status, _onStatus);
    // Gui gio ngay khi ket noi, nhu app cu
    await write('_time', _epochNow());
    await _readConfig();
    try {
      _onStatus(await link.read(kC3Status));
    } catch (_) {}
  }

  void _onStatus(List<int> data) {
    if (data.length > stats.maxValuesLen) stats.maxValuesLen = data.length;
    try {
      final j = jsonDecode(utf8.decode(data));
      if (j is! Map<String, dynamic>) throw const FormatException();
      stats.valuesCount++;
      if (!_values.isClosed) _values.add(c3FlattenStatus(j));
    } catch (_) {
      stats.badPackets++;
    }
  }

  void _onResult(List<int> data) {
    final p = _pending;
    if (p == null || p.isCompleted) return;
    try {
      final j = jsonDecode(utf8.decode(data)) as Map;
      final ok = j['ok'] == true || j['ok'] == 1;
      p.complete(ok ? const VphResult.ok() : VphResult.fail(j['err'] is String ? j['err'] as String : S.deviceRefused));
    } catch (_) {}
  }

  Future<void> _readConfig() async {
    try {
      final j = jsonDecode(utf8.decode(await link.read(kC3Config))) as Map<String, dynamic>;
      _cfgFlat = c3FlattenConfig(j);
      if (!_values.isClosed) _values.add(Map.of(_cfgFlat));
    } catch (_) {
      stats.badPackets++;
    }
  }

  /// RESULT cu khong co `q`: chi mot lenh cho tai mot thoi diem
  Future<VphResult> _writeAndWait(String chr, Map<String, dynamic> body) => _ops.run(() async {
        final c = Completer<VphResult>();
        _pending = c;
        try {
          await link.write(chr, utf8.encode(jsonEncode(body)));
          return await c.future.timeout(resultTimeout);
        } on TimeoutException {
          return VphResult.fail(S.noResponse);
        } catch (e) {
          return VphResult.fail(S.sendFailed(e));
        } finally {
          _pending = null;
        }
      });

  @override
  Future<void> select(int screen) async {
    // Thiet bi cu khong co SELECT: STATUS + CONFIG luon du cho moi man hinh
  }

  @override
  Future<VphResult> write(String id, dynamic v) {
    final cmd = c3Command(id, v);
    if (cmd != null) return _writeAndWait(kC3Cmd, cmd);
    return writeBatch({id: v});
  }

  @override
  Future<VphResult> writeBatch(Map<String, dynamic> set) async {
    final b = c3BuildConfig(set, _cfgFlat);
    if (b.json == null) return VphResult.fail(c3ErrText(b.err));
    final len = utf8.encode(jsonEncode(b.json)).length;
    if (len > maxConfig) return VphResult.fail(S.writeTooLong(len, maxConfig));
    final r = await _writeAndWait(kC3Config, b.json!);
    if (r.ok) await _readConfig();
    return r;
  }

  @override
  Future<void> close() async {
    final p = _pending;
    if (p != null && !p.isCompleted) p.complete(VphResult.fail(S.linkLost));
    await link.disconnect();
    await _values.close();
  }
}
