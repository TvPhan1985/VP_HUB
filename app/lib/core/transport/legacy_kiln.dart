import 'dart:async';
import 'dart:convert';

import '../../l10n/strings_vi.dart';
import '../model/vph_info.dart';
import '../model/vph_schema.dart';
import '../model/vph_value.dart';
import '../schema_cache.dart';
import 'gatt_link.dart';
import 'transport.dart';
import 'uuids.dart';

/// Nhan tieng Viet cho schema lo nung (firmware cu gui nhan tieng Anh)
const Map<String, String> _kilnTitles = {
  'operation': 'Vận hành',
  'pid': 'PID',
  'alarm': 'Cảnh báo',
  'calibration': 'Hiệu chuẩn',
  'autotune': 'Tự dò PID',
  'program': 'Chương trình',
  'program_steps': 'Các bước',
};

const Map<String, String> _kilnLabels = {
  'pv': 'Nhiệt độ',
  'sv': 'Nhiệt độ đặt',
  'running': 'Đốt lò',
  'alarm_dev': 'Cảnh báo lệch nhiệt',
  'tc_offset': 'Bù sai số cảm biến',
  'autotune_info': 'Trạng thái',
  'autotune_run': 'Chạy tự dò',
  'autotune_apply': 'Áp dụng kết quả',
  'program_enabled': 'Dùng chương trình nhiều bước',
  'program_step_count': 'Số bước',
  'program_running': 'Chạy chương trình',
  'program_info': 'Tiến trình',
  't': 'Nhiệt độ đích',
  'r': 'Thời gian tăng',
  's': 'Thời gian giữ',
};

const Map<String, String> _kilnConfirm = {
  'running': 'Bật đốt lò?',
  'program_running': 'Chạy chương trình nhiệt? Lò sẽ bắt đầu đốt.',
  'autotune_run': 'Chạy tự dò PID? Lò sẽ đốt để thử.',
  'autotune_apply': 'Áp dụng kết quả tự dò vào PID?',
};

void _patchField(Map<String, dynamic> f) {
  final id = f['id'];
  if (_kilnLabels.containsKey(id)) f['label'] = _kilnLabels[id];
  if (_kilnConfirm.containsKey(id)) f['c'] = _kilnConfirm[id];
  if (f['unit'] == 'min') f['unit'] = 'phút';
}

/// Va schema lo nung (LEGACY L2). Ham thuan, khong sua [raw].
Map<String, dynamic> patchKilnSchema(Map<String, dynamic> raw) {
  final s = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
  final id = s['id'];
  s['save'] = 'live';
  if (_kilnTitles.containsKey(id)) s['title'] = _kilnTitles[id];
  final fields = s['fields'] is List ? s['fields'] as List : (s['fields'] = <dynamic>[]);
  for (final f in fields) {
    if (f is Map<String, dynamic>) _patchField(f);
  }
  final rep = s['repeat'];
  if (rep is Map<String, dynamic>) {
    rep['label'] = 'Bước';
    if (rep['fields'] is List) {
      for (final f in rep['fields'] as List) {
        if (f is Map<String, dynamic>) _patchField(f);
      }
    }
  }
  if (id == 'operation') {
    for (final f in fields) {
      if (f is Map && f['id'] == 'pv') f['w'] = 'big,trend';
    }
    bool has(String fid) => fields.any((f) => f is Map && f['id'] == fid);
    void add(Map<String, dynamic> f) {
      if (!has(f['id'] as String)) fields.add(f);
    }

    add({'id': 'sensor_ok', 'label': 'Cảm biến', 'type': 'bool', 'readonly': true, 'w': 'led'});
    add({
      'id': 'program_info',
      'label': 'Chương trình',
      'type': 'text',
      'readonly': true,
      'if': 'program_running==true',
    });
    add({'id': 'safety_latched', 'label': 'Khóa an toàn', 'type': 'bool', 'readonly': true, 'w': 'led,warn'});
    add({
      'id': 'safety_reason',
      'label': 'Lý do khóa',
      'type': 'text',
      'readonly': true,
      'if': 'safety_latched==true',
    });
    add({
      'id': 'safety_clear',
      'label': 'Xóa lỗi',
      'type': 'act',
      'if': 'safety_latched==true',
      'c': 'Xóa khóa an toàn và cho lò chạy lại?',
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
        return await _verify(id, expected, tol) ? const VphResult.ok() : const VphResult.fail(S.kilnNotAccepted);
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
