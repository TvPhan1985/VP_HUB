import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/schema_cache.dart';
import 'package:vphub/core/transport/transport_registry.dart';
import 'package:vphub/core/transport/uuids.dart';
import 'package:vphub/core/transport/vph_transport.dart';

import 'fake_link.dart';

Map<String, dynamic> _info({List<String> caps = const [], int n = 2, String? sch = '9f3a'}) => {
      'proto': 'vph', 'pv': 1, 'model': 'vphdemo', 'name': 'VPHDEMO-A1B2', 'fw': '1.0.0', 'n': n,
      'sch': ?sch, 'hdr': ['t'], 'caps': caps,
    };

/// Schema dai hon 480 byte de thu doc theo trang
String _bigSchema(int fields) => jsonEncode({
      'id': 'big', 'l': 'Màn lớn', 'save': 'batch',
      'f': [for (var i = 0; i < fields; i++) {'id': 'f$i', 'l': 'Trường số $i', 't': 'num', 'u': '°C', 'min': 0, 'max': 100}],
    });

const _small = '{"id":"ov","l":"Tổng quan","save":"live","f":[{"id":"t","l":"Nhiệt độ","t":"num","ro":1},{"id":"sv","l":"Đặt","t":"num"}]}';

void main() {
  test('registry chon transport theo UUID dich vu', () {
    expect(kindForServices([kVphService]), TransportKind.vph);
    expect(kindForServices([kC3Service.toUpperCase()]), TransportKind.c3relay);
    expect(kindForServices([kKilnService]), TransportKind.kiln);
    expect(kindForServices(['0000180a-0000-1000-8000-00805f9b34fb']), isNull);
    expect(kindForServices([kC3Service, kVphService]), TransportKind.vph);
  });

  test('doc INFO va schema nhieu trang (PROTOCOL §8.1)', () async {
    final big = _bigSchema(20);
    expect(utf8.encode(big).length, greaterThan(960));
    final dev = FakeVphDevice(info: _info(), schemas: [_small, big]);
    final t = VphTransport(dev.link, SchemaCache(MemoryStore()));
    final info = await t.open();
    expect(info.model, 'vphdemo');
    final screens = await t.loadScreens();
    expect(screens.length, 2);
    expect(screens[0].error, isNull);
    expect(screens[1].error, isNull);
    expect(screens[1].fields.length, 20);
    expect(screens[1].batch, isTrue);
    expect(screens[1].fields.last.label, 'Trường số 19');
    // Man nho: 1 trang. Man lon: du cac trang [1,0],[1,1],[1,2]...
    final selects = [for (final w in dev.link.writeLog) if (w.$1 == kVphSelect) w.$2];
    expect(selects.first, [0, 0]);
    expect(selects.where((s) => s[0] == 0).length, 1);
    expect(selects.where((s) => s[0] == 1).length, (utf8.encode(big).length ~/ 480) + 1);
    expect(t.stats.schemaFromCache, isFalse);
  });

  test('trang cuoi dung 480 byte thi doc them mot trang rong', () async {
    var s = '{"id":"x","l":"';
    s = '$s${'a' * (480 - utf8.encode(s).length - 9)}","f":[]}';
    expect(utf8.encode(s).length, 480);
    final dev = FakeVphDevice(info: _info(n: 1), schemas: [s]);
    final t = VphTransport(dev.link, SchemaCache(MemoryStore()));
    await t.open();
    final screens = await t.loadScreens();
    expect(screens.single.error, isNull);
    expect(dev.link.writeLog.where((w) => w.$1 == kVphSelect).map((w) => w.$2), [
      [0, 0],
      [0, 1],
    ]);
  });

  test('cache schema theo model+sch: lan 2 khong doc lai, refresh thi doc lai', () async {
    final store = MemoryStore();
    final dev1 = FakeVphDevice(info: _info(), schemas: [_small, _small]);
    final t1 = VphTransport(dev1.link, SchemaCache(store));
    await t1.open();
    await t1.loadScreens();
    expect(dev1.link.readLog.where((c) => c == kVphSchema).length, 2);

    final dev2 = FakeVphDevice(info: _info(), schemas: [_small, _small]);
    final t2 = VphTransport(dev2.link, SchemaCache(store));
    await t2.open();
    final screens = await t2.loadScreens();
    expect(screens.length, 2);
    expect(dev2.link.readLog.where((c) => c == kVphSchema), isEmpty);
    expect(t2.stats.schemaFromCache, isTrue);

    await t2.loadScreens(refresh: true);
    expect(dev2.link.readLog.where((c) => c == kVphSchema).length, 2);

    // sch khac thi khong dung cache cu
    final dev3 = FakeVphDevice(info: _info(sch: 'beef'), schemas: [_small, _small]);
    final t3 = VphTransport(dev3.link, SchemaCache(store));
    await t3.open();
    await t3.loadScreens();
    expect(dev3.link.readLog.where((c) => c == kVphSchema).length, 2);
  });

  test('ghi don: q tang dan, RESULT ok va loi tieng Viet', () async {
    final dev = FakeVphDevice(info: _info(), schemas: [_small, _small]);
    final t = VphTransport(dev.link, SchemaCache(MemoryStore()));
    await t.open();
    await t.loadScreens();
    await t.start();
    final r1 = await t.write('sv', 150);
    expect(r1.ok, isTrue);
    dev.onWrite = (_) => 'Ngưỡng bật phải nhỏ hơn ngưỡng tắt';
    final r2 = await t.writeBatch({'on_at': 90, 'off_at': 80});
    expect(r2.ok, isFalse);
    expect(r2.err, 'Ngưỡng bật phải nhỏ hơn ngưỡng tắt');
    expect(dev.commands, [
      {'q': 1, 'id': 'sv', 'v': 150},
      {'q': 2, 'set': {'on_at': 90, 'off_at': 80}},
    ]);
  });

  test('caps co time thi gui _time ngay khi start', () async {
    final dev = FakeVphDevice(info: _info(caps: ['time']), schemas: [_small, _small]);
    final t = VphTransport(dev.link, SchemaCache(MemoryStore()), epochNow: () => 1759300000);
    await t.open();
    await t.loadScreens();
    await t.start();
    expect(dev.commands.single, {'q': 1, 'id': '_time', 'v': 1759300000});
  });

  test('khong co RESULT thi bao "Thiet bi khong phan hoi"', () async {
    final dev = FakeVphDevice(info: _info(), schemas: [_small, _small])..silent = true;
    final t = VphTransport(dev.link, SchemaCache(MemoryStore()), resultTimeout: const Duration(milliseconds: 50));
    await t.open();
    await t.start();
    final r = await t.write('sv', 1);
    expect(r.ok, isFalse);
    expect(r.err, 'No response from the device');
  });

  test('lenh qua 500 byte bi tu choi truoc khi gui', () async {
    final dev = FakeVphDevice(info: _info(), schemas: [_small, _small]);
    final t = VphTransport(dev.link, SchemaCache(MemoryStore()));
    await t.open();
    await t.start();
    final r = await t.writeBatch({for (var i = 0; i < 60; i++) 'truong_$i': 123456});
    expect(r.ok, isFalse);
    expect(dev.commands, isEmpty);
  });

  test('v1.1: luu 5 khung gio mot lan (hon 240 byte) gui duoc trong MOT lenh set', () async {
    final dev = FakeVphDevice(info: _info(), schemas: [_small, _small]);
    final t = VphTransport(dev.link, SchemaCache(MemoryStore()));
    await t.open();
    await t.start();
    final set = <String, dynamic>{
      for (var i = 1; i <= 5; i++) ...{'s${i}_en': true, 's${i}_days': 127, 's${i}_on': '08:00', 's${i}_off': '17:30'},
    };
    final r = await t.writeBatch(set);
    expect(r.ok, isTrue);
    expect(dev.commands.single['set'], set);
    final sent = dev.link.written(kVphWrite).single;
    expect(utf8.encode(sent).length, inInclusiveRange(241, 500));
  });

  test('VALUES: select doc ngay, notify gop, goi hong duoc dem', () async {
    final dev = FakeVphDevice(info: _info(), schemas: [_small, _small], values: [
      {'t': 28.4, 'sv': 100},
      {'a': 1, 't': 28.4},
    ]);
    final t = VphTransport(dev.link, SchemaCache(MemoryStore()));
    await t.open();
    await t.loadScreens();
    await t.start();
    final got = <Map<String, dynamic>>[];
    t.values.listen(got.add);
    await t.select(1);
    await Future<void>.delayed(Duration.zero);
    expect(dev.link.writeLog.last.$2, [1]);
    expect(got.last, {'a': 1, 't': 28.4});
    dev.link.notify(kVphValues, '{"t":29.1,"sv":10');
    dev.link.notify(kVphValues, '{"t":29.1}');
    await Future<void>.delayed(Duration.zero);
    expect(got.last, {'t': 29.1});
    expect(t.stats.badPackets, 1);
    expect(t.stats.valuesCount, 2);
    expect(t.stats.maxValuesLen, greaterThan(0));
  });

  test('INFO sai thi open nem loi', () async {
    final dev = FakeVphDevice(info: {'proto': 'khac'}, schemas: []);
    final t = VphTransport(dev.link, SchemaCache(MemoryStore()));
    expect(t.open(), throwsException);
  });
}
