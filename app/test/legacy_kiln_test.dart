import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/errors.dart';
import 'package:vphub/core/model/vph_schema.dart';
import 'package:vphub/core/schema_cache.dart';
import 'package:vphub/core/transport/legacy_kiln.dart';
import 'package:vphub/core/transport/uuids.dart';

import 'fake_link.dart';
import 'kiln_schemas.dart';

/// Lo nung gia: SELECT 1 byte, SCHEMA/VALUES theo man dang chon, WRITE {"id","value"}
class FakeKiln {
  final FakeGattLink link = FakeGattLink(name: 'Temp_Control', services: [kKilnService]);
  final List<Map<String, dynamic>> values = [
    for (final v in kKilnSampleValues) jsonDecode(v) as Map<String, dynamic>,
  ];
  int screen = 0;

  /// false = thiet bi lo di lenh ghi (vd dang khoa an toan)
  bool accept = true;

  FakeKiln() {
    link.writers[kKilnSelect] = (d) => screen = d[0];
    link.readers[kKilnSchema] =
        () => utf8.encode(screen < kKilnSchemas.length ? kKilnSchemas[screen] : '{}');
    link.readers[kKilnValues] = () => utf8.encode(jsonEncode(screen < values.length ? values[screen] : {}));
    link.writers[kKilnWrite] = (d) {
      final j = jsonDecode(utf8.decode(d)) as Map<String, dynamic>;
      if (!accept) return;
      for (final v in values) {
        if (v.containsKey(j['id']) && j['id'] != 'autotune_apply') v[j['id'] as String] = j['value'];
      }
    };
  }
}

KilnTransport _transport(FakeKiln k, [KvStore? store]) => KilnTransport(k.link, SchemaCache(store ?? MemoryStore()),
    verifyTimeout: const Duration(milliseconds: 60), verifyPoll: const Duration(milliseconds: 5));

void main() {
  group('va schema', () {
    final patched = [
      for (final s in kKilnSchemas) VphScreen.fromJson(patchKilnSchema(jsonDecode(s) as Map<String, dynamic>)),
    ];

    test('moi man hinh la live, tieu de va nhan chuan', () {
      expect(patched.every((s) => !s.batch), isTrue);
      expect(patched[0].title, 'Operation');
      expect(patched[0].field('sv')!.label, 'Setpoint');
      expect(patched[6].rep!.label, 'Step');
      expect(patched[6].field('step1_r')!.unit, 'min');
    });

    test('man operation: pv big+trend, them program_info / safety_reason / safety_clear', () {
      final op = patched[0];
      expect(op.field('pv')!.hints, {'big', 'trend'});
      expect(op.field('pv')!.icon, 'fire');
      expect(op.icon, 'fire');
      // v1.1: cong tac dot lo la the hero co chu rieng; khoa an toan la the bao dong gom ly do + nut xoa
      final run = op.field('running')!;
      expect(run.hint('hero'), isTrue);
      expect(run.boolLabels, ['Stopped', 'Firing']);
      expect(run.sub, 'sv');
      expect(run.confirm, isNotNull);
      expect(op.field('safety_latched')!.hint('alarm'), isTrue);
      expect({for (final id in ['safety_latched', 'safety_reason', 'safety_clear']) op.field(id)!.group}, {'safety'});
      expect(op.field('program_info')!.type, 'text');
      expect(op.field('program_info')!.ifCond, 'program_running==true');
      expect(op.field('safety_reason')!.ifCond, 'safety_latched==true');
      final clear = op.field('safety_clear')!;
      expect(clear.type, 'act');
      expect(clear.ifCond, 'safety_latched==true');
      expect(clear.confirm, isNotNull);
      // Cac truong hdr deu co mo ta de thanh dau trang ve duoc
      for (final id in ['pv', 'sv', 'running', 'sensor_ok', 'safety_latched']) {
        expect(op.field(id), isNotNull, reason: id);
      }
    });

    test('cac nut nguy hiem co cau hoi xac nhan', () {
      expect(patched[0].field('running')!.confirm, isNotNull);
      expect(patched[5].field('program_running')!.confirm, isNotNull);
      expect(patched[4].field('autotune_run')!.confirm, isNotNull);
      expect(patched[4].field('autotune_apply')!.confirm, isNotNull);
      expect(patched[4].field('autotune_run')!.type, 'bool');
    });

    test('man program_steps co cnt = program_step_count', () {
      expect(patched[6].rep!.cnt, 'program_step_count');
    });

    test('ham va khong sua ban goc', () {
      final raw = jsonDecode(kKilnSchemas[0]) as Map<String, dynamic>;
      final before = jsonEncode(raw);
      patchKilnSchema(raw);
      expect(jsonEncode(raw), before);
    });
  });

  group('ghi', () {
    test('{"id","v"} -> {"id","value"}', () {
      expect(KilnTransport.encodeWrite('sv', 150, type: 'num'), '{"id":"sv","value":150}');
      expect(KilnTransport.encodeWrite('running', 1, type: 'bool'), '{"id":"running","value":true}');
      expect(KilnTransport.encodeWrite('running', false, type: 'bool'), '{"id":"running","value":false}');
      // Nut lenh: firmware cu chi nhan bool true
      expect(KilnTransport.encodeWrite('safety_clear', 1, type: 'act'), '{"id":"safety_clear","value":true}');
    });
  });

  group('KilnTransport', () {
    test('doc schema den khi gap {}, INFO gia lap', () async {
      final k = FakeKiln();
      final t = _transport(k);
      final info = await t.open();
      expect(info.model, 'kiln31856');
      expect(info.name, 'Temp_Control');
      expect(info.n, 7);
      expect(info.icon, 'heater');
      expect(info.hdr, ['pv', 'sv', 'running', 'sensor_ok', 'safety_latched']);
      expect(info.hasTime, isFalse);
      final screens = await t.loadScreens();
      expect(screens.length, 7);
      expect(screens.every((s) => s.error == null), isTrue);
      // Da hoi toi man thu 8 (chi so 7) moi biet het
      expect(k.link.writeLog.where((w) => w.$1 == kKilnSelect).map((w) => w.$2[0]).reduce((a, b) => a > b ? a : b), 7);
    });

    test('cache schema: lan sau khong doc lai, refresh thi doc lai', () async {
      final store = MemoryStore();
      final k1 = FakeKiln();
      await _transport(k1, store).open();
      final k2 = FakeKiln();
      final t2 = _transport(k2, store);
      final info = await t2.open();
      expect(info.n, 7);
      expect(k2.link.readLog.where((c) => c == kKilnSchema), isEmpty);
      expect(t2.stats.schemaFromCache, isTrue);
      await t2.loadScreens(refresh: true);
      expect(k2.link.readLog.where((c) => c == kKilnSchema).length, 8);
    });

    test('start doc VALUES moi man mot lan (co program_step_count ngay)', () async {
      final k = FakeKiln();
      final t = _transport(k);
      await t.open();
      await t.loadScreens();
      final all = <String, dynamic>{};
      t.values.listen(all.addAll);
      await t.start();
      await Future<void>.delayed(Duration.zero);
      expect(all['program_step_count'], 2);
      expect(all['step2_t'], 200);
      expect(all['pv'], 25.4);
    });

    test('ghi duoc xac nhan qua VALUES', () async {
      final k = FakeKiln();
      final t = _transport(k);
      await t.open();
      await t.loadScreens();
      await t.start();
      await t.select(0);
      final r = await t.write('sv', 150);
      expect(r.ok, isTrue);
      expect(k.link.written(kKilnWrite).last, '{"id":"sv","value":150}');
    });

    test('thiet bi khong nhan thi bao "Thiet bi khong nhan gia tri"', () async {
      final k = FakeKiln()..accept = false;
      final t = _transport(k);
      await t.open();
      await t.loadScreens();
      await t.start();
      await t.select(0);
      final r = await t.write('running', true);
      expect(r.ok, isFalse);
      expect(r.error!.kind, ErrorKind.notAccepted);
    });

    test('nut lenh va truong tu nha khong can xac nhan', () async {
      final k = FakeKiln()..accept = false;
      final t = _transport(k);
      await t.open();
      await t.loadScreens();
      await t.start();
      expect((await t.write('safety_clear', 1)).ok, isTrue);
      expect(k.link.written(kKilnWrite).last, '{"id":"safety_clear","value":true}');
      expect((await t.write('autotune_apply', true)).ok, isTrue);
    });
  });
}
