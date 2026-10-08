import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/model/vph_info.dart';
import 'package:vphub/core/model/vph_schema.dart';
import 'package:vphub/core/model/vph_value.dart';

import 'kiln_schemas.dart';

void main() {
  v11Tests();
  group('INFO', () {
    test('doc du cac khoa', () {
      final i = VphInfo.fromJson({
        'proto': 'vph', 'pv': 1, 'model': 'c3relay', 'name': 'C3-RELAY-A1B2', 'fw': '1.1.0', 'hw': 'esp32c3',
        'n': 3, 'sch': '9f3a', 'hdr': ['t', 'h', 'out', 'alarm'], 'caps': ['time'], 'icon': 'relay', 'la': 1,
      });
      expect(i.model, 'c3relay');
      expect(i.n, 3);
      expect(i.sch, '9f3a');
      expect(i.hdr, ['t', 'h', 'out', 'alarm']);
      expect(i.hasTime, isTrue);
      expect(i.icon, 'relay');
    });

    test('khong phai vph thi nem loi', () {
      expect(() => VphInfo.fromJson({'proto': 'abc', 'model': 'x'}), throwsFormatException);
      expect(() => VphInfo.fromJson({'proto': 'vph'}), throwsFormatException);
    });
  });

  group('Schema khoa ngan (PROTOCOL §11)', () {
    const src = '{"id":"overview","l":"Tổng quan","save":"live","f":['
        '{"id":"t","l":"Nhiệt độ","t":"num","u":"°C","dp":1,"ro":1,"w":"trend"},'
        '{"id":"h","l":"Độ ẩm","t":"num","u":"%","dp":1,"ro":1},'
        '{"id":"mode","l":"Chế độ","t":"enum","opt":[["manual","Tay"],["auto","Tự động"]]},'
        '{"id":"out","l":"Relay","t":"bool","en":"mode==manual"},'
        '{"id":"alarm","l":"Báo động","t":"flags","opt":["Mất cảm biến","Chưa có giờ","Nhiệt độ ngoài ngưỡng","Độ ẩm ngoài ngưỡng"]},'
        '{"id":"silence","l":"Tắt còi","t":"act","if":"alarm!=0"}]}';

    test('parse dung', () {
      final s = VphScreen.tryParse(src);
      expect(s.error, isNull);
      expect(s.id, 'overview');
      expect(s.title, 'Tổng quan');
      expect(s.batch, isFalse);
      expect(s.fields.length, 6);
      final t = s.field('t')!;
      expect(t.type, 'num');
      expect(t.unit, '°C');
      expect(t.dp, 1);
      expect(t.readOnly, isTrue);
      expect(t.hint('trend'), isTrue);
      final mode = s.field('mode')!;
      expect(mode.options.map((o) => o.value), ['manual', 'auto']);
      expect(mode.optionLabel('auto'), 'Tự động');
      expect(s.field('out')!.enCond, 'mode==manual');
      expect(s.field('alarm')!.flagLabels.length, 4);
      expect(s.field('silence')!.ifCond, 'alarm!=0');
    });

    test('nhieu goi y w cach nhau dau phay', () {
      final f = VphField.fromJson({'id': 'pv', 't': 'num', 'w': 'big, trend'});
      expect(f.hints, {'big', 'trend'});
    });

    test('batch, nul, c, g, min/max/st', () {
      final s = VphScreen.fromJson({
        'id': 'a', 'l': 'A', 'save': 'batch',
        'f': [
          {'id': 'x', 'l': 'X', 't': 'num', 'min': 0, 'max': 1200, 'st': 0.5, 'nul': 1, 'c': 'Chắc chưa?', 'g': 'Nhóm'},
        ],
      });
      expect(s.batch, isTrue);
      final x = s.fields.single;
      expect(x.min, 0);
      expect(x.max, 1200);
      expect(x.step, 0.5);
      expect(x.nullable, isTrue);
      expect(x.confirm, 'Chắc chưa?');
      expect(x.group, 'Nhóm');
      expect(x.decimals, 1);
    });
  });

  group('Schema khoa dai cua lo nung (chuoi that tu main/ble_ui.c)', () {
    test('ca 7 man hinh parse duoc, float -> num', () {
      final screens = [for (var i = 0; i < kKilnSchemas.length; i++) VphScreen.tryParse(kKilnSchemas[i], index: i)];
      expect(screens.every((s) => s.error == null), isTrue);
      expect(screens.map((s) => s.id),
          ['operation', 'pid', 'alarm', 'calibration', 'autotune', 'program', 'program_steps']);
      final op = screens[0];
      expect(op.title, 'Operation');
      final pv = op.field('pv')!;
      expect(pv.type, 'num');
      expect(pv.label, 'Temperature');
      expect(pv.unit, '°C');
      expect(pv.readOnly, isTrue);
      final sv = op.field('sv')!;
      expect(sv.readOnly, isFalse);
      expect(sv.min, 0);
      expect(sv.max, 280);
      expect(sv.step, 1);
      expect(op.field('running')!.type, 'bool');
      // Buoc kieu float cua firmware (0.05f) van ra dung 2 chu so thap phan
      expect(screens[1].field('kp')!.decimals, 2);
      expect(screens[1].field('ki')!.decimals, 4);
      expect(screens[4].field('autotune_info')!.type, 'text');
    });

    test('repeat khoa dai sinh step1_t .. step5_s', () {
      final steps = VphScreen.tryParse(kKilnSchemas[6]);
      expect(steps.fields, isEmpty);
      expect(steps.rep!.n, 5);
      expect(steps.rep!.pfx, 'step');
      expect(steps.repGroups.length, 5);
      expect(steps.repGroups.first.fields.map((f) => f.id), ['step1_t', 'step1_r', 'step1_s']);
      expect(steps.repGroups.last.fields.map((f) => f.id), ['step5_t', 'step5_r', 'step5_s']);
      expect(steps.allFields.length, 15);
      expect(steps.field('step3_r')!.unit, 'min');
    });
  });

  group('Khoi lap khoa ngan', () {
    final s = VphScreen.fromJson({
      'id': 'sch', 'l': 'Lịch', 'save': 'batch', 'f': [],
      'rep': {
        'n': 5, 'pfx': 's', 'l': 'Khung', 'cnt': 'count',
        'f': [
          {'id': 'en', 'l': 'Bật', 't': 'bool'},
          {'id': 'days', 'l': 'Thứ', 't': 'days', 'en': 'en==true'},
          {'id': 'on', 'l': 'Giờ bật', 't': 'time', 'if': 'en==true&&mode!=off'},
          {'id': 'off', 'l': 'Giờ tắt', 't': 'time'},
        ],
      },
    });

    test('sinh s1_en .. s5_off', () {
      expect(s.rep!.label, 'Khung');
      expect(s.rep!.cnt, 'count');
      expect(s.repGroups.length, 5);
      expect(s.repGroups[0].fields.map((f) => f.id), ['s1_en', 's1_days', 's1_on', 's1_off']);
      expect(s.repGroups[4].index, 5);
      expect(s.field('s5_off')!.type, 'time');
    });

    test('dieu kien trong mau duoc doi sang id cua lan lap, id ngoai giu nguyen', () {
      expect(s.field('s2_days')!.enCond, 's2_en==true');
      expect(s.field('s3_on')!.ifCond, 's3_en==true&&mode!=off');
    });
  });

  group('Schema la / hong', () {
    test('kieu la giu nguyen de hien chu chi doc', () {
      final f = VphField.fromJson({'id': 'a', 'l': 'A', 't': 'xyz', 'w': 'hologram', 'zzz': 5});
      expect(f.type, 'xyz');
      expect(f.known, isFalse);
    });

    test('schema hong khong nem loi, tra man hinh co error', () {
      for (final bad in ['', '{', '[]', '{"l":"x"}', '{"id":"a","f":[{"l":"thieu id"}]}', 'null']) {
        final s = VphScreen.tryParse(bad, index: 2);
        expect(s.error, isNotNull, reason: bad);
        expect(s.fields, isEmpty);
      }
    });

    test('truong sai kieu JSON duoc bo qua', () {
      final s = VphScreen.tryParse('{"id":"a","f":[1,"x",{"id":"ok","t":"num"}],"rep":7}');
      expect(s.error, isNull);
      expect(s.fields.single.id, 'ok');
      expect(s.rep, isNull);
    });
  });

  group('Gia tri', () {
    test('fmtNum', () {
      expect(fmtNum(28.44, dp: 1), '28.4');
      expect(fmtNum(150), '150');
      expect(fmtNum(150.0), '150');
      expect(fmtNum(3.14159), '3.14');
      expect(fmtNum(2.5), '2.5');
    });

    test('sameValue', () {
      expect(sameValue(1, true), isTrue);
      expect(sameValue(0, true), isFalse);
      expect(sameValue(70, 70.0), isTrue);
      expect(sameValue(null, null), isTrue);
      expect(sameValue(null, 0), isFalse);
      expect(sameValue('08:00', '08:00'), isTrue);
      expect(sameValue(150.04, 150, tol: 0.06), isTrue);
    });

    test('decimalsOf', () {
      expect(decimalsOf(1), 0);
      expect(decimalsOf(0.5), 1);
      expect(decimalsOf(0.01), 2);
      expect(decimalsOf(0.05000000074505806), 2);
    });
  });
}

// ----- v1.1: khoa va goi y moi -----
void v11Tests() {
  group('Schema v1.1', () {
    test('ic, d, sub, opt 3 phan tu, opt cua bool', () {
      final s = VphScreen.tryParse('{"id":"o","l":"Tổng quan","ic":"dashboard","f":['
          '{"id":"t","l":"Nhiệt độ","t":"num","w":"tile,trend","ic":"temp"},'
          '{"id":"out","l":"Relay","t":"bool","w":"hero,btns","ic":"power","sub":"mode","d":"Chỉ ở chế độ Tay"},'
          '{"id":"mode","l":"Chế độ","t":"enum","w":"seg","opt":[["manual","Tay","hand"],["auto","Tự động"]]},'
          '{"id":"run","l":"Đốt lò","t":"bool","opt":["Dừng","Đang đốt"]}]}');
      expect(s.error, isNull);
      expect(s.icon, 'dashboard');
      final t = s.field('t')!;
      expect(t.icon, 'temp');
      expect(t.hints, {'tile', 'trend'});
      final out = s.field('out')!;
      expect(out.sub, 'mode');
      expect(out.desc, 'Chỉ ở chế độ Tay');
      expect(out.boolLabels, isNull);
      final mode = s.field('mode')!;
      expect(mode.options[0].icon, 'hand');
      expect(mode.options[1].icon, isNull);
      expect(mode.optionLabel('auto'), 'Tự động');
      expect(s.field('run')!.boolLabels, ['Dừng', 'Đang đốt']);
      expect(s.field('run')!.options, isEmpty);
    });

    test('schema 1.0 khong co khoa moi van doc nhu cu', () {
      final s = VphScreen.tryParse('{"id":"o","l":"A","f":[{"id":"t","l":"T","t":"num"}]}');
      expect(s.icon, isNull);
      final t = s.field('t')!;
      expect(t.icon, isNull);
      expect(t.desc, isNull);
      expect(t.sub, isNull);
      expect(t.hints, isEmpty);
    });

    test('khoa moi sai kieu thi bo qua, khong loi', () {
      final s = VphScreen.tryParse('{"id":"o","l":"A","ic":5,"f":['
          '{"id":"b","t":"bool","opt":[1,2],"ic":["x"],"d":7,"sub":{}},'
          '{"id":"e","t":"enum","opt":[["a","A",9]]}]}');
      expect(s.error, isNull);
      expect(s.icon, isNull);
      expect(s.field('b')!.boolLabels, isNull);
      expect(s.field('b')!.icon, isNull);
      expect(s.field('e')!.options.single.icon, isNull);
    });

    test('khoi lap giu ic/d va doi id cua sub', () {
      final s = VphScreen.tryParse('{"id":"o","l":"A","f":[],"rep":{"n":2,"pfx":"s","f":['
          '{"id":"en","t":"bool","w":"hero","sub":"on"},'
          '{"id":"on","t":"time","ic":"clock","d":"Giờ bật"}]}}');
      expect(s.field('s2_en')!.sub, 's2_on');
      expect(s.field('s2_on')!.icon, 'clock');
      expect(s.field('s2_on')!.desc, 'Giờ bật');
    });
  });

  test('INFO: khoa dom cho biet linh vuc, mac dinh la cong nghiep', () {
    VphInfo info(Map<String, dynamic> extra) => VphInfo.fromJson({'proto': 'vph', 'model': 'm', 'n': 1, ...extra});
    expect(info({}).domain, 'ind');
    expect(info({'dom': 'ind'}).agri, isFalse);
    expect(info({'dom': 'agri'}).agri, isTrue);
    expect(info({'dom': 'la'}).domain, 'ind');
    expect(info({'dom': 'agri'}).toJson()['dom'], 'agri');
    expect(info({}).toJson().containsKey('dom'), isFalse);
  });
}
