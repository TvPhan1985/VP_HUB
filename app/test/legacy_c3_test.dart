import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/errors.dart';
import 'package:vphub/core/model/vph_schema.dart';
import 'package:vphub/core/transport/legacy_c3relay.dart';
import 'package:vphub/core/transport/uuids.dart';

import 'fake_link.dart';

/// STATUS va CONFIG mau theo SPEC §6/§7 cua c3_relay_ctrl
const _status = '{"t":28.4,"h":72.5,"ec":120,"sal":40,"tds":60,"sok":1,"tok":1,'
    '"mode":"auto","src":"both","out":1,"alarm":0,"muted":0,'
    '"time":"2026-10-01 14:32:05","name":"C3-RELAY-A1B2","fw":"1.0.0","up":3600}';

const _config = '{"v":1,"name":"C3-RELAY","mode":"auto",'
    '"auto":{"src":"both","dateFrom":null,"dateTo":null,'
    '"slots":[[1,127,"08:00","17:00"]],'
    '"sensor":{"type":"hum","action":"low","onAt":70.0,"offAt":80.0}},'
    '"modbus":{"addr":7,"baud":9600,"fc":3,"start":0,"count":5,"idxH":0,"idxT":1,"scale":10,"periodS":5},'
    '"alarm":{"en":0,"tHi":45,"tLo":0,"hHi":100,"hLo":0}}';

Map<String, dynamic> _flatCfg() => c3FlattenConfig(jsonDecode(_config) as Map<String, dynamic>);

/// Thiet bi C3 gia: tra RESULT khong co q sau moi lan ghi CMD/CONFIG
FakeGattLink _device({String? Function(String chr, Map<String, dynamic> body)? onWrite}) {
  final link = FakeGattLink(name: 'C3-RELAY-A1B2', services: [kC3Service], mtu: 512);
  link.readers[kC3Status] = () => utf8.encode(_status);
  link.readers[kC3Config] = () => utf8.encode(_config);
  void handle(String chr, List<int> d) {
    final err = onWrite?.call(chr, jsonDecode(utf8.decode(d)) as Map<String, dynamic>);
    scheduleMicrotask(
        () => link.notify(kC3Result, err == null ? '{"ok":true}' : jsonEncode({'ok': false, 'err': err})));
  }

  link.writers[kC3Cmd] = (d) => handle(kC3Cmd, d);
  link.writers[kC3Config] = (d) => handle(kC3Config, d);
  return link;
}

Future<String> _schema() => File('assets/legacy/c3relay_v1.json').readAsString();

void main() {
  group('STATUS + CONFIG -> VALUES phang', () {
    test('STATUS', () {
      final v = c3FlattenStatus(jsonDecode(_status) as Map<String, dynamic>);
      expect(v['t'], 28.4);
      expect(v['h'], 72.5);
      expect(v['ec'], 120);
      expect(v['sok'], isTrue);
      expect(v['tok'], isTrue);
      expect(v['out'], isTrue);
      expect(v['muted'], isFalse);
      expect(v['mode'], 'auto');
      expect(v['alarm'], 0);
      expect(v['time'], '2026-10-01 14:32:05');
      expect(v['_name'], 'C3-RELAY-A1B2');
      expect(v['fw'], '1.0.0');
      expect(v['up'], 3600);
    });

    test('STATUS chua co du lieu: null va chuoi gio rong', () {
      final v = c3FlattenStatus({'t': null, 'h': null, 'sok': 0, 'tok': 0, 'time': '', 'mode': 'manual', 'out': 0});
      expect(v['t'], isNull);
      expect(v['time'], isNull);
      expect(v['sok'], isFalse);
      expect(v['out'], isFalse);
    });

    test('CONFIG: slots luon du 5, thieu thi dien mac dinh', () {
      final v = _flatCfg();
      expect(v['src'], 'both');
      expect(v['date_from'], isNull);
      expect(v['date_to'], isNull);
      expect([v['s1_en'], v['s1_days'], v['s1_on'], v['s1_off']], [true, 127, '08:00', '17:00']);
      for (var i = 2; i <= 5; i++) {
        expect([v['s${i}_en'], v['s${i}_days'], v['s${i}_on'], v['s${i}_off']], [false, 127, '00:00', '00:00']);
      }
      expect(v['sen_type'], 'hum');
      expect(v['sen_act'], 'low');
      expect(v['on_at'], 70.0);
      expect(v['off_at'], 80.0);
      expect(v['mb_addr'], 7);
      expect(v['mb_baud'], 9600);
      expect(v['mb_idx_t'], 1);
      expect(v['mb_period'], 5);
      expect(v['al_en'], isFalse);
      expect(v['al_t_hi'], 45.0);
      expect(v['al_h_hi'], 100.0);
    });

    test('CONFIG: khung gio dang object cung nhan', () {
      final v = c3FlattenConfig({
        'auto': {
          'slots': [
            {'en': 1, 'days': 31, 'on': '06:00', 'off': '07:30'},
          ],
        },
      });
      expect([v['s1_en'], v['s1_days'], v['s1_on'], v['s1_off']], [true, 31, '06:00', '07:30']);
    });
  });

  group('batch -> JSON CONFIG mot phan', () {
    test('doi mot khung gio: gui ca mang 5 khung', () {
      final b = c3BuildConfig({'s2_en': true, 's2_on': '19:00', 's2_off': '21:00'}, _flatCfg());
      expect(b.err, isNull);
      expect(b.json, {
        'auto': {
          'slots': [
            [1, 127, '08:00', '17:00'],
            [1, 127, '19:00', '21:00'],
            [0, 127, '00:00', '00:00'],
            [0, 127, '00:00', '00:00'],
            [0, 127, '00:00', '00:00'],
          ],
        },
      });
    });

    test('doi mot nguong: gui du 4 khoa cua sensor', () {
      final b = c3BuildConfig({'on_at': 60}, _flatCfg());
      expect(b.json, {
        'auto': {
          'sensor': {'type': 'hum', 'action': 'low', 'onAt': 60.0, 'offAt': 80.0},
        },
      });
    });

    test('src, ngay, modbus, alarm, ten trong cung mot JSON', () {
      final b = c3BuildConfig({
        'src': 'sensor',
        'date_from': '2026-10-01',
        'mb_addr': 1,
        'al_en': true,
        '_name': 'VUON-1',
      }, _flatCfg());
      expect(b.err, isNull);
      expect(b.json!['name'], 'VUON-1');
      expect(b.json!['auto'], {'src': 'sensor', 'dateFrom': '2026-10-01'});
      expect(b.json!['modbus'],
          {'addr': 1, 'baud': 9600, 'fc': 3, 'start': 0, 'count': 5, 'idxH': 0, 'idxT': 1, 'scale': 10.0, 'periodS': 5});
      expect(b.json!['alarm'], {'en': 1, 'tHi': 45.0, 'tLo': 0.0, 'hHi': 100.0, 'hLo': 0.0});
    });

    test('bo gioi han ngay: gui null', () {
      final cur = {..._flatCfg(), 'date_to': '2026-12-31'};
      final b = c3BuildConfig({'date_to': null}, cur);
      expect(b.json, {
        'auto': {'dateTo': null},
      });
    });

    test('kiem tra truoc khi gui giong app cu', () {
      String? err(Map<String, dynamic> set) => c3BuildConfig(set, _flatCfg()).err;
      expect(err({'on_at': 90}), contains('below'));
      expect(err({'sen_act': 'high'}), contains('above'));
      expect(err({'sen_act': 'high', 'on_at': 90, 'off_at': 80}), isNull);
      expect(err({'s1_on': '8h'}), contains('HH:MM'));
      expect(err({'date_from': '2026-12-01', 'date_to': '2026-01-01'}), contains('before'));
      expect(err({'mb_addr': 0}), contains('1 to 247'));
      expect(err({'mb_idx_h': 5}), contains('positions'));
      expect(err({'al_t_lo': 50}), contains('temperature'));
      expect(err({'_name': ''}), contains('1 to 20'));
      expect(err({'_name': 'Vườn'}), contains('unaccented'));
    });

    test('JSON lon nhat (doi het moi thu) van duoi 500 byte', () {
      final cur = _flatCfg();
      final set = {
        ...cur,
        '_name': 'TEN-THIET-BI-20-KYTU',
        'date_from': '2026-01-01',
        'date_to': '2026-12-31',
        for (var i = 1; i <= 5; i++) ...{'s${i}_en': true, 's${i}_on': '22:00', 's${i}_off': '06:00'},
      };
      final b = c3BuildConfig(set, cur);
      expect(b.err, isNull);
      expect(utf8.encode(jsonEncode(b.json)).length, lessThanOrEqualTo(C3RelayTransport.maxConfig));
    });
  });

  group('lenh CMD', () {
    test('anh xa', () {
      expect(c3Command('mode', 'auto'), {'cmd': 'mode', 'v': 'auto'});
      expect(c3Command('out', true), {'cmd': 'out', 'v': 1});
      expect(c3Command('out', false), {'cmd': 'out', 'v': 0});
      expect(c3Command('silence', 1), {'cmd': 'silence'});
      expect(c3Command('_reboot', 1), {'cmd': 'reboot'});
      expect(c3Command('_time', 1759300000), {'cmd': 'time', 'epoch': 1759300000});
      expect(c3Command('on_at', 1), isNull);
    });
  });

  group('schema luu san c3relay_v1.json', () {
    test('5 man hinh, dung dinh dang VPH, moi id deu co nguon du lieu', () async {
      final j = jsonDecode(await _schema()) as Map<String, dynamic>;
      final raw = j['screens'] as List;
      final screens = [for (var i = 0; i < raw.length; i++) VphScreen.tryFromMap(raw[i], index: i)];
      expect(screens.length, 5);
      expect(screens.every((s) => s.error == null), isTrue);
      expect(screens.map((s) => s.batch), [false, true, true, true, false]);
      // Standard thay Alarm settings; Sensor setup (Modbus) va nut Restart chi danh cho Technician
      expect(screens.map((s) => s.id), ['overview', 'auto', 'alarms', 'sensor', 'device']);
      expect(screens.map((s) => s.adv), [false, false, false, true, false]);
      expect(screens[4].field('_reboot')!.adv, isTrue);
      expect(screens[4].field('_name')!.adv, isFalse);
      expect(screens[1].repGroups.length, 5);
      final known = {
        ...c3FlattenStatus(jsonDecode(_status) as Map<String, dynamic>).keys,
        ..._flatCfg().keys,
      };
      for (final s in screens) {
        for (final f in s.allFields) {
          if (f.type == 'act') continue;
          expect(known.contains(f.id), isTrue, reason: 'truong ${f.id} khong co trong VALUES');
          expect(f.known, isTrue, reason: 'kieu la ${f.type}');
        }
      }
      // In kich thuoc tung man de Phan D biet truoc (gioi han 1920 byte / man)
      for (var i = 0; i < raw.length; i++) {
        final len = utf8.encode(jsonEncode(raw[i])).length;
        // ignore: avoid_print
        print('c3relay_v1 man $i (${screens[i].id}): $len byte, ${(len / 480).ceil()} trang');
        expect(len, lessThanOrEqualTo(1920));
      }
    });
  });

  group('C3RelayTransport', () {
    test('open/start: INFO gia lap, gui gio, gop STATUS + CONFIG', () async {
      final link = _device();
      final t = C3RelayTransport(link, loadSchema: _schema, epochNow: () => 1759300000);
      final info = await t.open();
      expect(info.model, 'c3relay');
      expect(info.name, 'C3-RELAY-A1B2');
      expect(info.fw, '1.0.0');
      expect(info.n, 5);
      expect(info.hdr, ['t', 'h', 'out', 'mode', 'alarm']);
      expect(info.hasTime, isTrue);
      expect((await t.loadScreens()).length, 5);
      final all = <String, dynamic>{};
      t.values.listen(all.addAll);
      await t.start();
      await Future<void>.delayed(Duration.zero);
      expect(link.written(kC3Cmd).first, '{"cmd":"time","epoch":1759300000}');
      expect(all['t'], 28.4);
      expect(all['s1_on'], '08:00');
      expect(all['s5_off'], '00:00');
      expect(all['mb_addr'], 7);
      // STATUS notify cap nhat tiep
      link.notify(kC3Status, _status.replaceFirst('"t":28.4', '"t":30.1'));
      await Future<void>.delayed(Duration.zero);
      expect(all['t'], 30.1);
    });

    test('ghi live di qua CMD, batch di qua CONFIG roi doc lai CONFIG', () async {
      final link = _device();
      final t = C3RelayTransport(link, loadSchema: _schema, epochNow: () => 1);
      await t.open();
      await t.start();
      link.writeLog.clear();
      link.readLog.clear();
      expect((await t.write('mode', 'manual')).ok, isTrue);
      expect((await t.write('out', true)).ok, isTrue);
      expect((await t.write('silence', 1)).ok, isTrue);
      expect(link.written(kC3Cmd),
          ['{"cmd":"mode","v":"manual"}', '{"cmd":"out","v":1}', '{"cmd":"silence"}']);
      expect((await t.writeBatch({'on_at': 60, 'off_at': 75})).ok, isTrue);
      expect(jsonDecode(link.written(kC3Config).single), {
        'auto': {
          'sensor': {'type': 'hum', 'action': 'low', 'onAt': 60.0, 'offAt': 75.0},
        },
      });
      expect(link.readLog, contains(kC3Config));
      // Doi ten di qua CONFIG
      expect((await t.write('_name', 'VUON-1')).ok, isTrue);
      expect(jsonDecode(link.written(kC3Config).last), {'name': 'VUON-1'});
    });

    test('batch sai bi chan o app, khong gui xuong thiet bi', () async {
      final link = _device();
      final t = C3RelayTransport(link, loadSchema: _schema, epochNow: () => 1);
      await t.open();
      await t.start();
      link.writeLog.clear();
      final r = await t.writeBatch({'on_at': 90});
      expect(r.ok, isFalse);
      expect(link.writeLog, isEmpty);
    });

    test('thiet bi tra loi thi hien nguyen van; khong tra loi thi het gio', () async {
      var link = _device(onWrite: (c, b) => 'Chỉ bật tắt được ở chế độ Tay');
      var t = C3RelayTransport(link, loadSchema: _schema, epochNow: () => 1);
      await t.open();
      await t.start();
      final r = await t.write('out', true);
      expect(r.ok, isFalse);
      expect(r.err, 'Chỉ bật tắt được ở chế độ Tay');

      link = FakeGattLink(services: [kC3Service]);
      link.readers[kC3Status] = () => utf8.encode(_status);
      link.readers[kC3Config] = () => utf8.encode(_config);
      t = C3RelayTransport(link,
          loadSchema: _schema, epochNow: () => 1, resultTimeout: const Duration(milliseconds: 40));
      await t.open();
      final r2 = await t.write('mode', 'auto');
      expect(r2.ok, isFalse);
      expect(r2.error!.kind, ErrorKind.noResponse);
    });
  });
}
