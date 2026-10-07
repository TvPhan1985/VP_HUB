import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/app.dart';
import 'package:vphub/core/device_session.dart';
import 'package:vphub/core/transport/demo_transport.dart';
import 'package:vphub/l10n/strings_vi.dart';
import 'package:vphub/ui/render/header_bar.dart';
import 'package:vphub/ui/screens/device_screen.dart';

String _demo(String name) => File('assets/demo/$name').readAsStringSync();

class _Rig {
  late DemoTransport demo;
  late DeviceSession session;
}

/// Mo man Thiet bi voi mot chuoi JSON demo, man hinh rat cao de moi truong deu duoc ve
Future<_Rig> _openJson(WidgetTester tester, String json) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(900, 5000);
  addTearDown(tester.view.reset);
  final rig = _Rig();
  rig.session = DeviceSession(
    connector: () async => rig.demo = DemoTransport.fromJson(json, tick: null, seed: 7),
  );
  await rig.session.connect();
  await tester.pumpWidget(MaterialApp(
    theme: vpHubTheme(Brightness.light),
    home: DeviceScreen(session: rig.session),
  ));
  await tester.pumpAndSettle();
  return rig;
}

Future<_Rig> _open(WidgetTester tester, String file) => _openJson(tester, _demo(file));

Future<void> _close(WidgetTester tester, _Rig rig) async {
  // Cho SnackBar tu dong (2-5 s) de khong con Timer treo
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
  await tester.pumpWidget(const SizedBox());
  rig.session.dispose();
  await tester.pump();
}

/// Bam mot tab tren thanh tab o tren
Future<void> _goto(WidgetTester tester, String title) async {
  await tester.tap(find.widgetWithText(Tab, title));
  await tester.pumpAndSettle();
}

/// Nut (moi bien the cua FilledButton) chua dong chu [text]
Finder _button(String text) =>
    find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((w) => w is FilledButton));

/// Thiet bi VPH 1.0: khong co khoa hay goi y moi nao
String _v10(int screens) => jsonEncode({
      'info': {'proto': 'vph', 'pv': 1, 'model': 'old', 'name': 'OLD-1', 'fw': '1.0.0', 'hdr': ['t']},
      'screens': [
        for (var i = 0; i < screens; i++)
          {
            'id': 's$i',
            'l': 'Màn $i',
            'f': [
              {'id': i == 0 ? 't' : 't$i', 'l': 'Nhiệt độ $i', 't': 'num', 'u': '°C', 'ro': 1},
              {'id': 'h$i', 'l': 'Độ ẩm $i', 't': 'num', 'u': '%', 'ro': 1},
              {'id': 'p$i', 'l': 'Áp suất $i', 't': 'num', 'ro': 1},
              {'id': 'on$i', 'l': 'Bật $i', 't': 'bool'},
            ],
          },
      ],
      'values': {'t': 25.5, 'h0': 60, 'p0': 3, 'on0': true},
    });

void main() {
  for (final file in ['demo_relay.json', 'demo_all_types.json']) {
    testWidgets('ve duoc toan bo $file khong loi', (tester) async {
      final rig = await _open(tester, file);
      final s = rig.session;
      expect(s.status, LinkStatus.ready);
      // Co vai mau de bieu do trend ve duong that
      for (var i = 0; i < 4; i++) {
        rig.demo.step();
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var i = 0; i < s.screens.length; i++) {
        await _goto(tester, s.screens[i].title);
        expect(tester.takeException(), isNull, reason: 'tab ${s.screens[i].id}');
        expect(s.current, i);
        // Moi truong dang hien (khong bi `if` an) deu co nhan tren man hinh
        final sc = s.screens[i];
        for (final f in sc.fields) {
          if (f.ifCond != null || !f.known) continue;
          expect(find.textContaining(f.label), findsWidgets, reason: 'truong ${f.id}');
        }
      }
      await _close(tester, rig);
    });
  }

  testWidgets('kieu la hien chu chi doc, man hong hien the canh bao', (tester) async {
    final rig = await _open(tester, 'demo_all_types.json');
    expect(find.text('alien: abc'), findsOneWidget);
    // Goi y la: van ve theo kieu num
    expect(find.text('3.3 V'), findsOneWidget);
    await _goto(tester, rig.session.screens.last.title);
    expect(find.text(S.schemaError), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _close(tester, rig);
  });

  testWidgets('the bao dong do; thanh dau trang chi hien truong khong co trong tab', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    // alarm = 2 -> bit1 "Chưa có giờ" thanh gach dau dong trong the bao dong
    expect(find.text('• Chưa có giờ'), findsOneWidget);
    expect(find.text('Tắt còi'), findsOneWidget);
    // Tab Tong quan da co du cac truong hdr nen thanh dau trang trong
    expect(find.descendant(of: find.byType(HeaderBar), matching: find.byType(Text)), findsNothing);
    await _goto(tester, 'Lịch');
    expect(find.descendant(of: find.byType(HeaderBar), matching: find.text('Chưa có giờ')), findsOneWidget);
    await _close(tester, rig);
  });

  testWidgets('man live: nut BAT/TAT gui ngay; en khoa khi dieu kien sai', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    expect(rig.session.values['out'], true);
    expect(find.text('Relay: BẬT'), findsOneWidget);
    expect(find.text('Chế độ: Tay'), findsOneWidget);
    expect(tester.widget<FilledButton>(_button(S.onCaps)).onPressed, isNull, reason: 'dang bat thi nut BAT mo');
    await tester.tap(_button(S.offCaps));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.last, {'id': 'out', 'v': false});
    expect(find.text('Relay: TẮT'), findsOneWidget);
    expect(find.text(S.turnedOff('Relay')), findsOneWidget);
    // Doi che do sang Tu dong -> ca hai nut bi khoa (en: mode==manual), hien dong giai thich
    expect(find.text('Bật/tắt tay chỉ dùng được ở chế độ Tay'), findsNothing);
    await tester.tap(find.text('Tự động'));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.last, {'id': 'mode', 'v': 'auto'});
    expect(tester.widget<FilledButton>(_button(S.onCaps)).onPressed, isNull);
    expect(tester.widget<FilledButton>(_button(S.offCaps)).onPressed, isNull);
    expect(find.text('Bật/tắt tay chỉ dùng được ở chế độ Tay'), findsOneWidget);
    await _close(tester, rig);
  });

  testWidgets('cong tac thuong (khong co goi y) van gui ngay', (tester) async {
    final rig = await _openJson(tester, _v10(2));
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(rig.demo.writes.last, {'id': 'on0', 'v': false});
    await _close(tester, rig);
  });

  testWidgets('hai tile lien nhau nam cung mot hang, mini gom mot the', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    final t = tester.getCenter(find.text('Nhiệt độ'));
    final h = tester.getCenter(find.text('Độ ẩm'));
    expect(t.dy, h.dy);
    expect(t.dx, lessThan(h.dx));
    final ys = {for (final l in ['EC', 'Độ mặn', 'TDS']) tester.getCenter(find.text(l)).dy};
    expect(ys.length, 1);
    expect(find.text('28.4 °C'), findsOneWidget);
    // dur: 7512 giay
    expect(find.text('2 giờ 5 phút'), findsOneWidget);
    await _close(tester, rig);
  });

  testWidgets('tile co trend: cham de mo va dong bieu do', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    expect(find.text(S.trendEmpty), findsNothing);
    await tester.tap(find.text('Nhiệt độ'));
    await tester.pumpAndSettle();
    expect(find.text(S.trendEmpty), findsOneWidget);
    await tester.tap(find.text('Nhiệt độ'));
    await tester.pumpAndSettle();
    expect(find.text(S.trendEmpty), findsNothing);
    await _close(tester, rig);
  });

  testWidgets('goi y moi: hero co chu rieng, alarm cua bool, nut trong the bao dong', (tester) async {
    final rig = await _open(tester, 'demo_all_types.json');
    await _goto(tester, 'Gợi ý mới');
    expect(find.text('Đốt lò: Đang đốt'), findsOneWidget);
    expect(find.text('Bơm: TẮT'), findsOneWidget);
    expect(find.text('Chế độ bơm: Tự động'), findsOneWidget);
    expect(find.text('Cảm biến mất kết nối'), findsOneWidget);
    // n_al = 3 -> 2 gach dau dong; n_lock = true -> ly do thanh gach dau dong
    expect(find.text('• Cạn nước'), findsOneWidget);
    expect(find.text('• Quá dòng'), findsOneWidget);
    expect(find.text('• Quá nhiệt 1250 °C'), findsOneWidget);
    await tester.tap(find.text('Tắt chuông'));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.last, {'id': 'n_sil', 'v': 1});
    expect(tester.takeException(), isNull);
    await _close(tester, rig);
  });

  testWidgets('app 1.1 mo thiet bi VPH 1.0: van ve du, 2 so dau tu thanh tile', (tester) async {
    final rig = await _openJson(tester, _v10(2));
    expect(tester.takeException(), isNull);
    // Hai so chi doc dau tien cua man dau nam cung hang; so thu ba la hang thuong
    final a = tester.getCenter(find.text('Nhiệt độ 0'));
    final b = tester.getCenter(find.text('Độ ẩm 0'));
    final c = tester.getCenter(find.text('Áp suất 0'));
    expect(a.dy, b.dy);
    expect(c.dy, greaterThan(a.dy));
    expect(find.text('25.5 °C'), findsOneWidget);
    // Khong co `ic`: tab van co icon theo vi tri; thanh tab nam o tren, khong co thanh duoi
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.descendant(of: find.byType(TabBar), matching: find.byIcon(Icons.dashboard_outlined)), findsOneWidget);
    expect(tester.getCenter(find.byType(TabBar)).dy, lessThan(a.dy));
    await _goto(tester, 'Màn 1');
    expect(rig.session.current, 1);
    await _close(tester, rig);
  });

  testWidgets('nhieu man: TabBar cuon ngang', (tester) async {
    final rig = await _openJson(tester, _v10(6));
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);
    await _goto(tester, 'Màn 5');
    expect(rig.session.current, 5);
    await _close(tester, rig);
  });

  testWidgets('nut lenh co c: hoi xac nhan roi moi gui', (tester) async {
    final rig = await _open(tester, 'demo_all_types.json');
    final n = rig.demo.writes.length;
    await tester.tap(find.text('Xóa cảnh báo'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa toàn bộ cảnh báo?'), findsOneWidget);
    await tester.tap(find.text(S.cancel));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.length, n);
    await tester.tap(find.text('Xóa cảnh báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.ok));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.last, {'id': 'reset', 'v': 1});
    await _close(tester, rig);
  });

  testWidgets('man batch: sua -> Luu -> gui dung 1 lenh set', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    await _goto(tester, 'Lịch');
    final n = rig.demo.writes.length;
    // Bam + hai lan o "Bật khi độ ẩm dưới" (70 -> 72) va bat Khung 2
    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.length, n, reason: 'chua bam Luu thi chua gui gi');
    expect(find.text(S.batchChanges(2)), findsOneWidget);
    expect(find.text('72 %'), findsOneWidget);
    await tester.tap(find.text(S.save));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.length, n + 1);
    expect(rig.demo.writes.last, {
      'set': {'on_at': 72, 's2_en': true},
    });
    expect(find.text(S.batchChanges(2)), findsNothing);
    await _close(tester, rig);
  });

  testWidgets('man batch: roi tab khi chua luu thi hoi lai; Huy bo thay doi', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    await _goto(tester, 'Lịch');
    final n = rig.demo.writes.length;
    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();
    expect(find.text(S.batchChanges(1)), findsOneWidget);
    await _goto(tester, 'Tổng quan');
    expect(find.text(S.unsavedTitle), findsOneWidget);
    await tester.tap(find.text(S.stay));
    await tester.pumpAndSettle();
    expect(rig.session.draftCount(1), 1);
    expect(find.text(S.batchChanges(1)), findsOneWidget);
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
    // Nut Huy tren thanh duoi
    await tester.tap(find.text(S.cancel));
    await tester.pumpAndSettle();
    expect(rig.session.draftCount(1), 0);
    expect(rig.demo.writes.length, n);
    await _close(tester, rig);
  });

  testWidgets('cnt gioi han so the lap', (tester) async {
    final rig = await _open(tester, 'demo_all_types.json');
    await _goto(tester, 'Nhóm & lặp');
    // steps = 2 -> chi hien Buoc 1, Buoc 2
    expect(find.text('Bước 1'), findsOneWidget);
    expect(find.text('Bước 2'), findsOneWidget);
    expect(find.text('Bước 3'), findsNothing);
    // p1_hold = true nen co "Thời gian giữ", p2_hold = false nen an
    expect(find.text('Thời gian giữ'), findsOneWidget);
    await _close(tester, rig);
  });
}
