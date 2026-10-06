import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/app.dart';
import 'package:vphub/core/device_session.dart';
import 'package:vphub/core/transport/demo_transport.dart';
import 'package:vphub/l10n/strings_vi.dart';
import 'package:vphub/ui/screens/device_screen.dart';

String _demo(String name) => File('assets/demo/$name').readAsStringSync();

class _Rig {
  late DemoTransport demo;
  late DeviceSession session;
}

/// Mo man Thiet bi voi mot file demo, man hinh rat cao de moi truong deu duoc ve
Future<_Rig> _open(WidgetTester tester, String file) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(900, 5000);
  addTearDown(tester.view.reset);
  final rig = _Rig();
  rig.session = DeviceSession(
    connector: () async => rig.demo = DemoTransport.fromJson(_demo(file), tick: null, seed: 7),
  );
  await rig.session.connect();
  await tester.pumpWidget(MaterialApp(
    theme: vpHubTheme(Brightness.light),
    home: DeviceScreen(session: rig.session),
  ));
  await tester.pumpAndSettle();
  return rig;
}

Future<void> _close(WidgetTester tester, _Rig rig) async {
  // Cho SnackBar tu dong (2-5 s) de khong con Timer treo
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
  await tester.pumpWidget(const SizedBox());
  rig.session.dispose();
  await tester.pump();
}

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
        await tester.tap(find.widgetWithText(Tab, s.screens[i].title));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'tab ${s.screens[i].id}');
        expect(s.current, i);
        // Moi truong dang hien (khong bi `if` an) deu co nhan tren man hinh
        final sc = s.screens[i];
        for (final f in sc.fields) {
          if (f.ifCond != null || !f.known) continue;
          expect(find.text(f.label), findsWidgets, reason: 'truong ${f.id}');
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
    await tester.tap(find.widgetWithText(Tab, rig.session.screens.last.title));
    await tester.pumpAndSettle();
    expect(find.text(S.schemaError), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _close(tester, rig);
  });

  testWidgets('thanh dau trang hien hdr, co bao dong do', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    // alarm = 2 -> bit1 "Chưa có giờ" (mot o thanh dau trang, mot o truong flags)
    expect(find.text('Chưa có giờ'), findsNWidgets(2));
    expect(find.text('Tắt còi'), findsOneWidget);
    await _close(tester, rig);
  });

  testWidgets('man live: gat cong tac gui ngay; en khoa khi dieu kien sai', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    expect(rig.session.values['out'], true);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(rig.demo.writes.last, {'id': 'out', 'v': false});
    // Doi che do sang Tu dong -> cong tac Relay bi khoa (en: mode==manual)
    await tester.tap(find.text('Tự động'));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.last, {'id': 'mode', 'v': 'auto'});
    expect(tester.widget<Switch>(find.byType(Switch).first).onChanged, isNull);
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
    await tester.tap(find.widgetWithText(Tab, 'Lịch'));
    await tester.pumpAndSettle();
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
    await tester.tap(find.widgetWithText(Tab, 'Lịch'));
    await tester.pumpAndSettle();
    final n = rig.demo.writes.length;
    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();
    expect(find.text(S.batchChanges(1)), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'Tổng quan'));
    await tester.pumpAndSettle();
    expect(find.text(S.unsavedTitle), findsOneWidget);
    await tester.tap(find.text(S.stay));
    await tester.pumpAndSettle();
    expect(rig.session.draftCount(1), 1);
    expect(find.text(S.batchChanges(1)), findsOneWidget);
    // Nut Huy tren thanh duoi
    await tester.tap(find.text(S.cancel));
    await tester.pumpAndSettle();
    expect(rig.session.draftCount(1), 0);
    expect(rig.demo.writes.length, n);
    await _close(tester, rig);
  });

  testWidgets('cnt gioi han so the lap', (tester) async {
    final rig = await _open(tester, 'demo_all_types.json');
    await tester.tap(find.widgetWithText(Tab, 'Nhóm & lặp'));
    await tester.pumpAndSettle();
    // steps = 2 -> chi hien Buoc 1, Buoc 2
    expect(find.text('Bước 1'), findsOneWidget);
    expect(find.text('Bước 2'), findsOneWidget);
    expect(find.text('Bước 3'), findsNothing);
    // p1_hold = true nen co "Thời gian giữ", p2_hold = false nen an
    expect(find.text('Thời gian giữ'), findsOneWidget);
    await _close(tester, rig);
  });
}
