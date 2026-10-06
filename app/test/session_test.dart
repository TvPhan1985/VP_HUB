import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/device_session.dart';
import 'package:vphub/core/schema_cache.dart';
import 'package:vphub/core/transport/demo_transport.dart';
import 'package:vphub/core/transport/uuids.dart';
import 'package:vphub/core/transport/vph_transport.dart';

import 'fake_link.dart';

String _demo(String name) => File('assets/demo/$name').readAsStringSync();

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  test('demo: ket noi, VALUES, sua live, sua batch', () async {
    late DemoTransport demo;
    final s = DeviceSession(
      connector: () async => demo = DemoTransport.fromJson(_demo('demo_relay.json'), tick: null, seed: 1),
    );
    final msgs = <SessionMessage>[];
    s.messages.listen(msgs.add);
    await s.connect();
    await _settle();
    expect(s.status, LinkStatus.ready);
    expect(s.info!.model, 'demorelay');
    expect(s.screens.length, 2);
    expect(s.values['t'], 28.4);
    expect(s.displayName, 'DEMO-RELAY');

    // Man live: gui ngay
    final out = s.fieldById('out')!;
    await s.edit(0, out, false);
    expect(demo.writes.last, {'id': 'out', 'v': false});
    expect(s.values['out'], false);
    expect(s.busy, isEmpty);

    // Nut lenh gui v = 1
    await s.edit(0, s.fieldById('silence')!, 1);
    expect(demo.writes.last, {'id': 'silence', 'v': 1});

    // Man batch: giu tam, chua gui
    await s.selectScreen(1);
    final n = demo.writes.length;
    await s.edit(1, s.fieldById('on_at')!, 60);
    await s.edit(1, s.fieldById('s2_en')!, true);
    expect(demo.writes.length, n);
    expect(s.draftCount(1), 2);
    expect(s.valueOf(1, 'on_at'), 60);
    expect(s.values['on_at'], 70);
    expect(s.isDraft(1, 'on_at'), isTrue);
    // Sua ve dung gia tri thiet bi thi het la thay doi
    await s.edit(1, s.fieldById('on_at')!, 70);
    expect(s.draftCount(1), 1);
    await s.edit(1, s.fieldById('on_at')!, 65);

    // Luu: dung MOT lenh set
    expect(await s.saveBatch(1), isTrue);
    expect(demo.writes.length, n + 1);
    expect(demo.writes.last, {
      'set': {'s2_en': true, 'on_at': 65},
    });
    expect(s.draftCount(1), 0);
    expect(s.values['on_at'], 65);
    expect(msgs.last.ok, isTrue);

    // Huy
    await s.edit(1, s.fieldById('off_at')!, 99);
    s.discardBatch(1);
    expect(s.draftCount(1), 0);
    expect(s.valueOf(1, 'off_at'), 80);
    s.dispose();
  });

  test('lich su trend chi gom truong co goi y trend', () async {
    late DemoTransport demo;
    final s = DeviceSession(
      connector: () async => demo = DemoTransport.fromJson(_demo('demo_relay.json'), tick: null, seed: 1),
    );
    await s.connect();
    for (var i = 0; i < 5; i++) {
      demo.step();
    }
    await _settle();
    expect(s.trends['t']!.length, greaterThanOrEqualTo(5));
    expect(s.trends.containsKey('h'), isFalse);
    s.dispose();
  });

  test('loi ghi: bao loi, o tro ve gia tri thiet bi', () async {
    final dev = FakeVphDevice(
      info: {'proto': 'vph', 'pv': 1, 'model': 'm', 'name': 'M', 'fw': '1', 'n': 1},
      schemas: ['{"id":"a","l":"A","f":[{"id":"sv","l":"Đặt","t":"num"}]}'],
      values: [
        {'sv': 100},
      ],
    )..onWrite = (_) => 'Ngoài giới hạn';
    final s = DeviceSession(connector: () async => VphTransport(dev.link, SchemaCache(MemoryStore())));
    final msgs = <SessionMessage>[];
    s.messages.listen(msgs.add);
    await s.connect();
    await _settle();
    await s.edit(0, s.fieldById('sv')!, 5000);
    await _settle();
    expect(msgs.last.ok, isFalse);
    expect(msgs.last.text, 'Ngoài giới hạn');
    expect(s.valueOf(0, 'sv'), 100);
    s.dispose();
  });

  test('mat ket noi: tu ket noi lai, giu gia tri cu', () async {
    var made = 0;
    late FakeVphDevice dev;
    FakeVphDevice make() => FakeVphDevice(
          info: {'proto': 'vph', 'pv': 1, 'model': 'm', 'name': 'M', 'fw': '1', 'n': 1},
          schemas: ['{"id":"a","l":"A","f":[{"id":"t","l":"T","t":"num","ro":1}]}'],
          values: [
            {'t': 20 + made},
          ],
        );
    final s = DeviceSession(
      connector: () async {
        made++;
        dev = make();
        return VphTransport(dev.link, SchemaCache(MemoryStore()));
      },
      reconnectDelays: const [Duration(milliseconds: 10), Duration(milliseconds: 10)],
    );
    await s.connect();
    await _settle();
    expect(s.status, LinkStatus.ready);
    expect(s.values['t'], 21);
    final statuses = <LinkStatus>[];
    s.addListener(() => statuses.add(s.status));
    dev.link.lostCtl.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(statuses, contains(LinkStatus.reconnecting));
    expect(s.status, LinkStatus.ready);
    expect(made, 2);
    expect(s.values['t'], 22);
    s.dispose();
  });

  test('ket noi lai that bai het cac lan thi dung o failed', () async {
    var made = 0;
    late FakeVphDevice dev;
    final s = DeviceSession(
      connector: () async {
        if (made++ > 0) throw Exception('khong thay thiet bi');
        dev = FakeVphDevice(
          info: {'proto': 'vph', 'pv': 1, 'model': 'm', 'name': 'M', 'fw': '1', 'n': 1},
          schemas: ['{"id":"a","l":"A","f":[]}'],
        );
        return VphTransport(dev.link, SchemaCache(MemoryStore()));
      },
      reconnectDelays: const [Duration(milliseconds: 5), Duration(milliseconds: 5), Duration(milliseconds: 5)],
    );
    await s.connect();
    await _settle();
    dev.link.lostCtl.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(s.status, LinkStatus.failed);
    expect(made, 4);
    expect(s.hasEverConnected, isTrue);
    expect(s.error, contains('khong thay thiet bi'));
    s.dispose();
  });

  test('ket noi lan dau that bai: failed kem thong bao', () async {
    final s = DeviceSession(connector: () async => throw Exception('Thiết bị không trả lời'));
    await s.connect();
    expect(s.status, LinkStatus.failed);
    expect(s.hasEverConnected, isFalse);
    expect(s.error, 'Thiết bị không trả lời');
    s.dispose();
  });

  test('uuid VPH dung theo PROTOCOL §3', () {
    expect(kVphService, '5b390001-5578-4ab2-9265-4b994a7bc724');
    expect(kVphResult, '5b390007-5578-4ab2-9265-4b994a7bc724');
  });
}
