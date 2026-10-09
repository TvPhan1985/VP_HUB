import 'dart:async';
import 'dart:convert';

import '../../l10n/strings.dart';
import '../model/vph_info.dart';
import '../model/vph_schema.dart';
import '../model/vph_value.dart';
import '../schema_cache.dart';
import 'gatt_link.dart';
import 'transport.dart';
import 'uuids.dart';

/// Nhan chuan cho schema lo nung (thay nhan cua firmware cu)
const Map<String, String> _kilnTitles = {
  'operation': 'Operation',
  'pid': 'PID',
  'alarm': 'Alarm',
  'calibration': 'Calibration',
  'autotune': 'Auto-tune',
  'program': 'Program',
  'program_steps': 'Steps',
};

const Map<String, String> _kilnLabels = {
  'pv': 'Temperature',
  'sv': 'Setpoint',
  'running': 'Burner',
  'alarm_dev': 'Deviation alarm',
  'tc_offset': 'Sensor offset',
  'autotune_info': 'Status',
  'autotune_run': 'Run auto-tune',
  'autotune_apply': 'Apply result',
  'program_enabled': 'Use multi-step program',
  'program_step_count': 'Step count',
  'program_running': 'Run program',
  'program_info': 'Progress',
  't': 'Target temperature',
  'r': 'Ramp time',
  's': 'Hold time',
};

/// Ban tieng Viet cua cac nhan o tren va nhan them trong patchKilnSchema
const Map<String, String> _kilnVi = {
  'Operation': 'Vận hành',
  'Alarm': 'Cảnh báo',
  'Calibration': 'Hiệu chuẩn',
  'Auto-tune': 'Tự dò PID',
  'Program': 'Chương trình',
  'Steps': 'Các bước',
  'Temperature': 'Nhiệt độ',
  'Setpoint': 'Nhiệt độ đặt',
  'Burner': 'Đốt lò',
  'Deviation alarm': 'Cảnh báo lệch nhiệt',
  'Sensor offset': 'Bù sai số cảm biến',
  'Status': 'Trạng thái',
  'Run auto-tune': 'Chạy tự dò',
  'Apply result': 'Áp dụng kết quả',
  'Use multi-step program': 'Dùng chương trình nhiều bước',
  'Step count': 'Số bước',
  'Run program': 'Chạy chương trình',
  'Progress': 'Tiến trình',
  'Target temperature': 'Nhiệt độ đích',
  'Ramp time': 'Thời gian tăng',
  'Hold time': 'Thời gian giữ',
  'Start firing the kiln?': 'Bật đốt lò?',
  'Run the firing program? The kiln will start heating.': 'Chạy chương trình nhiệt? Lò sẽ bắt đầu đốt.',
  'Run PID auto-tune? The kiln will heat for the test.': 'Chạy tự dò PID? Lò sẽ đốt để thử.',
  'Apply the auto-tune result to PID?': 'Áp dụng kết quả tự dò vào PID?',
  'Step': 'Bước',
  'Stopped': 'Dừng',
  'Firing': 'Đang đốt',
  'Sensor': 'Cảm biến',
  'Safety lock': 'Khóa an toàn',
  'Lock reason': 'Lý do khóa',
  'Clear fault': 'Xóa lỗi',
  'Clear the safety lock and allow the kiln to run again?': 'Xóa khóa an toàn và cho lò chạy lại?',
  'min': 'phút',
};

String _l(String en) => Lang.isVi ? (_kilnVi[en] ?? en) : en;

const Map<String, String> _kilnConfirm = {
  'running': 'Start firing the kiln?',
  'program_running': 'Run the firing program? The kiln will start heating.',
  'autotune_run': 'Run PID auto-tune? The kiln will heat for the test.',
  'autotune_apply': 'Apply the auto-tune result to PID?',
};

void _patchField(Map<String, dynamic> f) {
  final id = f['id'];
  if (_kilnLabels.containsKey(id)) f['label'] = _l(_kilnLabels[id]!);
  if (_kilnConfirm.containsKey(id)) f['c'] = _l(_kilnConfirm[id]!);
  if (f['unit'] == 'min') f['unit'] = _l('min');
}

/// Va schema lo nung (LEGACY L2). Ham thuan, khong sua [raw].
Map<String, dynamic> patchKilnSchema(Map<String, dynamic> raw) {
  final s = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
  final id = s['id'];
  s['save'] = 'live';
  if (_kilnTitles.containsKey(id)) s['title'] = _l(_kilnTitles[id]!);
  final fields = s['fields'] is List ? s['fields'] as List : (s['fields'] = <dynamic>[]);
  for (final f in fields) {
    if (f is Map<String, dynamic>) _patchField(f);
  }
  final rep = s['repeat'];
  if (rep is Map<String, dynamic>) {
    rep['label'] = _l('Step');
    if (rep['fields'] is List) {
      for (final f in rep['fields'] as List) {
        if (f is Map<String, dynamic>) _patchField(f);
      }
    }
  }
  const icons = {
    'operation': 'fire',
    'pid': 'tune',
    'alarm': 'alarm',
    'calibration': 'gauge',
    'autotune': 'auto',
    'program': 'schedule',
    'program_steps': 'timer',
  };
  if (icons.containsKey(id)) s['ic'] = icons[id];
  // PID, tu do, hieu chuan, nguong bao ve: chi danh cho nguoi ky thuat (PROTOCOL v1.3 `adv`)
  if (const {'pid', 'alarm', 'calibration', 'autotune'}.contains(id)) s['adv'] = 1;
  if (id == 'operation') {
    for (final f in fields) {
      if (f is! Map) continue;
      if (f['id'] == 'pv') {
        f['w'] = 'big,trend';
        f['ic'] = 'fire';
      }
      // Cong tac dot lo thanh the trang thai lon, dong phu la nhiet do dat
      if (f['id'] == 'running') {
        f['w'] = 'hero';
        f['ic'] = 'fire';
        f['opt'] = [_l('Stopped'), _l('Firing')];
        f['sub'] = 'sv';
      }
    }
    bool has(String fid) => fields.any((f) => f is Map && f['id'] == fid);
    void add(Map<String, dynamic> f) {
      if (!has(f['id'] as String)) fields.add(f);
    }

    add({'id': 'sensor_ok', 'label': _l('Sensor'), 'type': 'bool', 'readonly': true, 'w': 'led'});
    add({
      'id': 'program_info',
      'label': _l('Program'),
      'type': 'text',
      'readonly': true,
      'if': 'program_running==true',
    });
    // Khoa an toan thanh the bao dong, gom ly do va nut xoa loi (cung nhom)
    add({
      'id': 'safety_latched',
      'label': _l('Safety lock'),
      'type': 'bool',
      'readonly': true,
      'w': 'alarm,led,warn',
      'g': 'safety',
    });
    add({
      'id': 'safety_reason',
      'label': _l('Lock reason'),
      'type': 'text',
      'readonly': true,
      'if': 'safety_latched==true',
      'g': 'safety',
    });
    add({
      'id': 'safety_clear',
      'label': _l('Clear fault'),
      'type': 'act',
      'ic': 'reset',
      'if': 'safety_latched==true',
      'c': _l('Clear the safety lock and allow the kiln to run again?'),
      'g': 'safety',
    });
  }
  if (id == 'program_steps' && rep is Map<String, dynamic>) rep['cnt'] = 'program_step_count';
  return s;
}

/// Adapter cho bo dieu khien lo nung MAX31856 firmware cu (LEGACY L2)
class KilnTransport implements DeviceTransport {
  static const int maxScreens = 16;

  /// Bo dem WRITE cua firmware cu chi 64 byte
  static const int maxWrite = 63;

  /// Truong bool tu tra ve false ngay sau khi nhan, khong xac nhan duoc qua VALUES
  static const Set<String> _momentary = {'autotune_apply'};

  final GattLink link;
  final SchemaCache cache;

  /// Thoi gian cho VALUES xac nhan gia tri vua ghi
  final Duration verifyTimeout;
  final Duration verifyPoll;
  final StreamController<Map<String, dynamic>> _values = StreamController.broadcast();
  final OpQueue _writes = OpQueue();
  List<String> _rawSchemas = [];
  List<VphScreen> _screens = [];
  Map<String, dynamic> _last = {};

  @override
  final TransportStats stats = TransportStats();

  KilnTransport(this.link, this.cache,
      {this.verifyTimeout = const Duration(seconds: 2), this.verifyPoll = const Duration(milliseconds: 250)});

  static const String _cacheKey = 'kiln31856/?';

  @override
  String get protoLabel => S.protoKiln;

  @override
  bool get legacy => true;

  @override
  Stream<Map<String, dynamic>> get values => _values.stream;

  @override
  Stream<void> get lost => link.lost;

  @override
  Future<VphInfo> open() async {
    stats.mtu = link.mtu;
    // Khong co INFO: phai biet so man hinh truoc, nen doc schema ngay o day
    final cached = cache.get(_cacheKey);
    if (cached != null) {
      _rawSchemas = cached;
      stats.schemaFromCache = true;
    } else {
      await _readSchemas();
    }
    return VphInfo(
      model: 'kiln31856',
      name: link.name.isNotEmpty ? link.name : 'Temp_Control',
      fw: '?',
      n: _rawSchemas.length,
      hdr: const ['pv', 'sv', 'running', 'sensor_ok', 'safety_latched'],
      icon: 'heater',
    );
  }

  Future<void> _readSchemas() async {
    final out = <String>[];
    for (var i = 0; i < maxScreens; i++) {
      await link.write(kKilnSelect, [i]);
      final s = utf8.decode(await link.read(kKilnSchema), allowMalformed: true);
      try {
        final j = jsonDecode(s);
        if (j is! Map || !j.containsKey('id')) break;
      } catch (_) {
        // Man hinh hong van giu de hien the canh bao
      }
      out.add(s);
    }
    if (out.isEmpty) throw Exception(S.emptySchema);
    _rawSchemas = out;
    stats.schemaFromCache = false;
    await cache.put(_cacheKey, out);
  }

  @override
  Future<List<VphScreen>> loadScreens({bool refresh = false}) async {
    if (refresh) await _readSchemas();
    _screens = [
      for (var i = 0; i < _rawSchemas.length; i++) _parse(_rawSchemas[i], i),
    ];
    return _screens;
  }

  static VphScreen _parse(String raw, int index) {
    try {
      return VphScreen.fromJson(patchKilnSchema(jsonDecode(raw) as Map<String, dynamic>));
    } catch (e) {
      return VphScreen(id: 'screen$index', title: '#${index + 1}', error: '$e');
    }
  }

  @override
  Future<void> start() async {
    // Doc VALUES cua moi man mot lan de co du du lieu ngay (vd program_step_count
    // nam o man "program" nhung man "program_steps" can de biet so the)
    for (var i = 0; i < _rawSchemas.length; i++) {
      await link.write(kKilnSelect, [i]);
      _onValues(await link.read(kKilnValues));
    }
    await link.subscribe(kKilnValues, _onValues);
  }

  void _onValues(List<int> data) {
    if (data.length > stats.maxValuesLen) stats.maxValuesLen = data.length;
    try {
      final j = jsonDecode(utf8.decode(data));
      if (j is! Map<String, dynamic>) throw const FormatException();
      stats.valuesCount++;
      _last = {..._last, ...j};
      if (!_values.isClosed) _values.add(j);
    } catch (_) {
      stats.badPackets++;
    }
  }

  @override
  Future<void> select(int screen) async {
    await link.write(kKilnSelect, [screen]);
    _onValues(await link.read(kKilnValues));
  }

  VphField? _field(String id) {
    for (final s in _screens) {
      final f = s.field(id);
      if (f != null) return f;
    }
    return null;
  }

  /// Doi lenh ghi VPH {"id","v"} sang dang cu {"id","value"}
  static String encodeWrite(String id, dynamic v, {String? type}) {
    dynamic value = v;
    if (type == 'act') {
      value = true; // firmware cu chi nhan bool true cho cac nut lenh
    } else if (type == 'bool') {
      value = asBool(v) ?? false;
    }
    return jsonEncode({'id': id, 'value': value});
  }

  @override
  Future<VphResult> write(String id, dynamic v) => _writes.run(() async {
        final f = _field(id);
        final json = encodeWrite(id, v, type: f?.type);
        final payload = utf8.encode(json);
        if (payload.length > maxWrite) return VphResult.fail(S.writeTooLong(payload.length, maxWrite));
        try {
          await link.write(kKilnWrite, payload);
        } catch (e) {
          return VphResult.fail(S.sendFailed(e));
        }
        if (f == null || f.type == 'act' || _momentary.contains(id)) return const VphResult.ok();
        final expected = f.type == 'bool' ? (asBool(v) ?? false) : v;
        final tol = f.type == 'num' ? ((f.step ?? 0.1) / 2 + 0.011).clamp(0.06, 1e9).toDouble() : 1e-6;
        return await _verify(id, expected, tol) ? const VphResult.ok() : VphResult.fail(S.kilnNotAccepted);
      });

  /// Khong co RESULT: xem VALUES trong 2 giay toi co dung gia tri vua ghi khong
  Future<bool> _verify(String id, dynamic expected, double tol) async {
    final end = DateTime.now().add(verifyTimeout);
    var delay = verifyPoll;
    while (true) {
      await Future.delayed(delay);
      try {
        _onValues(await link.read(kKilnValues));
      } catch (_) {
        return false;
      }
      // Truong khong nam trong VALUES cua man dang chon thi khong kiem duoc, coi la ok
      if (!_last.containsKey(id)) return true;
      if (sameValue(_last[id], expected, tol: tol)) return true;
      if (!DateTime.now().isBefore(end)) return false;
      delay = verifyPoll * 2;
    }
  }

  @override
  Future<VphResult> writeBatch(Map<String, dynamic> set) async {
    // Firmware cu khong co ghi theo lo: ghi lan luot, dung o loi dau tien
    for (final e in set.entries) {
      final r = await write(e.key, e.value);
      if (!r.ok) return r;
    }
    return const VphResult.ok();
  }

  @override
  Future<void> close() async {
    await link.disconnect();
    await _values.close();
  }
}
