import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/app_settings.dart';
import 'package:vphub/core/device_session.dart';
import 'package:vphub/core/transport/demo_transport.dart';
import 'package:vphub/l10n/strings.dart';
import 'package:vphub/core/schema_cache.dart';
import 'package:vphub/ui/render/header_bar.dart';
import 'package:vphub/ui/screens/device_screen.dart';
import 'package:vphub/ui/theme.dart';
import 'package:vphub/ui/vp_widgets.dart';

String _demo(String name) => File('assets/demo/$name').readAsStringSync();

class _Rig {
  late DemoTransport demo;
  late DeviceSession session;
}

/// Cai dat cua app cho test. Mac dinh Technician de moi man / truong (ke ca adv) deu hien.
AppSettings _settings({bool tech = true, String? pin}) => AppSettings(MemoryStore()
  ..data['user_mode'] = tech ? 'technician' : 'standard'
  ..data.addAll({'tech_pin': ?pin}));

/// Mo man Thiet bi voi mot chuoi JSON demo, man hinh rat cao de moi truong deu duoc ve
Future<_Rig> _openJson(WidgetTester tester, String json, {AppSettings? settings}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(900, 5000);
  addTearDown(tester.view.reset);
  final rig = _Rig();
  rig.session = DeviceSession(
    connector: () async => rig.demo = DemoTransport.fromJson(json, tick: null, seed: 7),
  );
  await rig.session.connect();
  await tester.pumpWidget(SettingsScope(
    settings: settings ?? _settings(),
    child: MaterialApp(
      theme: vpHubTheme(Brightness.light),
      home: DeviceScreen(session: rig.session),
    ),
  ));
  await tester.pumpAndSettle();
  return rig;
}

Future<_Rig> _open(WidgetTester tester, String file, {AppSettings? settings}) =>
    _openJson(tester, _demo(file), settings: settings);

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
  await tester.tap(find.widgetWithText(Tab, title.toUpperCase()));
  await tester.pumpAndSettle();
}

/// Mo mot man nav:"menu" tu menu he thong (bam [≡] roi chon muc trong Drawer)
Future<void> _openFromMenu(WidgetTester tester, String title) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text(title)));
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
        final inMenu = s.screens[i].menu;
        if (inMenu) {
          await _openFromMenu(tester, s.screens[i].title);
        } else {
          await _goto(tester, s.screens[i].title);
        }
        expect(tester.takeException(), isNull, reason: 'tab ${s.screens[i].id}');
        expect(s.current, i);
        // Moi truong dang hien (khong bi `if` an) deu co nhan tren man hinh
        final sc = s.screens[i];
        for (final f in sc.fields) {
          if (f.ifCond != null || !f.known) continue;
          expect(find.textContaining(f.label), findsWidgets, reason: 'truong ${f.id}');
        }
        if (inMenu) {
          await tester.pageBack();
          await tester.pumpAndSettle();
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
    expect(find.text(S.screenError), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _close(tester, rig);
  });

  testWidgets('the bao dong do; thanh dau trang chi hien truong khong co trong tab', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    // alarm = 2 -> bit1 "Clock not set" thanh gach dau dong trong the bao dong
    expect(find.text('• Clock not set'), findsOneWidget);
    expect(find.text('Silence buzzer'), findsOneWidget);
    // Tab Tong quan da co du cac truong hdr nen thanh dau trang trong
    expect(find.descendant(of: find.byType(HeaderBar), matching: find.byType(Text)), findsNothing);
    await _goto(tester, 'Schedule');
    expect(find.descendant(of: find.byType(HeaderBar), matching: find.text('Clock not set')), findsOneWidget);
    await _close(tester, rig);
  });

  testWidgets('man live: nut BAT/TAT gui ngay; en khoa khi dieu kien sai', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    expect(rig.session.values['out'], true);
    expect(find.widgetWithText(StatusChip, S.onCaps), findsOneWidget);
    expect(find.text('Mode: Manual'), findsOneWidget);
    expect(tester.widget<FilledButton>(_button(S.onCaps)).onPressed, isNull, reason: 'dang bat thi nut BAT mo');
    await tester.tap(_button(S.offCaps));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.last, {'id': 'out', 'v': false});
    expect(find.widgetWithText(StatusChip, S.offCaps), findsOneWidget);
    expect(find.text(S.turnedOff('Relay')), findsOneWidget);
    // Doi che do sang Tu dong -> ca hai nut bi khoa (en: mode==manual), hien dong giai thich
    expect(find.text('Manual switching is available in Manual mode only.'), findsNothing);
    await tester.tap(find.text('Auto'));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.last, {'id': 'mode', 'v': 'auto'});
    expect(tester.widget<FilledButton>(_button(S.onCaps)).onPressed, isNull);
    expect(tester.widget<FilledButton>(_button(S.offCaps)).onPressed, isNull);
    expect(find.text('Manual switching is available in Manual mode only.'), findsOneWidget);
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
    final t = tester.getCenter(find.text('Temperature'));
    final h = tester.getCenter(find.text('Humidity'));
    expect(t.dy, h.dy);
    expect(t.dx, lessThan(h.dx));
    final ys = {for (final l in ['EC', 'Salinity', 'TDS']) tester.getCenter(find.text(l)).dy};
    expect(ys.length, 1);
    expect(find.text('28.4 °C'), findsOneWidget);
    // dur: 7512 giay
    expect(find.text('2 h 05 min'), findsOneWidget);
    await _close(tester, rig);
  });

  testWidgets('tile co trend: cham de mo va dong bieu do', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    expect(find.text(S.trendEmpty), findsNothing);
    await tester.tap(find.text('Temperature'));
    await tester.pumpAndSettle();
    expect(find.text(S.trendEmpty), findsOneWidget);
    await tester.tap(find.text('Temperature'));
    await tester.pumpAndSettle();
    expect(find.text(S.trendEmpty), findsNothing);
    await _close(tester, rig);
  });

  testWidgets('goi y moi: hero co chu rieng, alarm cua bool, nut trong the bao dong', (tester) async {
    final rig = await _open(tester, 'demo_all_types.json');
    await _goto(tester, 'New Hints');
    expect(find.widgetWithText(StatusChip, 'Firing'), findsOneWidget);
    expect(find.widgetWithText(StatusChip, S.offCaps), findsOneWidget);
    expect(find.text('Pump mode: Auto'), findsOneWidget);
    expect(find.text('Sensor disconnected'), findsOneWidget);
    // n_al = 3 -> 2 gach dau dong; n_lock = true -> ly do thanh gach dau dong
    expect(find.text('• Dry run'), findsOneWidget);
    expect(find.text('• Overcurrent'), findsOneWidget);
    expect(find.text('• Overtemperature 1250 °C'), findsOneWidget);
    await tester.tap(find.text('Silence buzzer'));
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
    // Thanh tab nam o tren (duoi Top App Bar), chu in hoa, cuon ngang; khong co thanh duoi
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.widgetWithText(Tab, 'MÀN 0'), findsOneWidget);
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);
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

  testWidgets('man nav:"menu" khong lam tab, mo tu menu thanh trang rieng, thoat thi ve tab cu', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    final s = rig.session;
    // Chi 2 man thuong lam tab
    expect(tester.widget<TabBar>(find.byType(TabBar)).tabs.length, 2);
    expect(find.widgetWithText(Tab, 'ALARM SETTINGS'), findsNothing);
    await _goto(tester, 'Schedule');
    expect(s.current, 1);
    await _openFromMenu(tester, 'Alarm settings');
    expect(s.current, 2);
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Alarm thresholds'), findsOneWidget);
    // Man batch trong trang rieng: sua -> hien thanh Luu -> gui 1 lenh set
    final n = rig.demo.writes.length;
    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();
    expect(find.text(S.batchChanges(1)), findsOneWidget);
    // Con thay doi ma quay lai thi hoi
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(S.unsavedTitle), findsOneWidget);
    await tester.tap(find.text(S.stay));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.save));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.length, n + 1);
    expect(rig.demo.writes.last, {
      'set': {'al_lo': 11},
    });
    await tester.pageBack();
    await tester.pumpAndSettle();
    // Ve lai dung tab dang mo truoc do
    expect(find.byType(TabBar), findsOneWidget);
    expect(s.current, 1);
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
    await _close(tester, rig);
  });

  testWidgets('moi man deu la menu thi van hien thanh tab', (tester) async {
    final j = jsonDecode(_v10(2)) as Map<String, dynamic>;
    for (final sc in j['screens'] as List) {
      (sc as Map)['nav'] = 'menu';
    }
    final rig = await _openJson(tester, jsonEncode(j));
    expect(tester.widget<TabBar>(find.byType(TabBar)).tabs.length, 2);
    expect(tester.takeException(), isNull);
    await _close(tester, rig);
  });

  testWidgets('nut lenh co c: hoi xac nhan roi moi gui', (tester) async {
    final rig = await _open(tester, 'demo_all_types.json');
    final n = rig.demo.writes.length;
    await tester.tap(find.text('Clear warnings'));
    await tester.pumpAndSettle();
    expect(find.text('Clear all warnings?'), findsOneWidget);
    await tester.tap(find.text(S.cancel));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.length, n);
    await tester.tap(find.text('Clear warnings'));
    await tester.pumpAndSettle();
    // Nut xac nhan lap lai ten hanh dong, khong dung "OK"
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Clear warnings')));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.last, {'id': 'reset', 'v': 1});
    await _close(tester, rig);
  });

  testWidgets('man batch: sua -> Luu -> gui dung 1 lenh set', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    await _goto(tester, 'Schedule');
    final n = rig.demo.writes.length;
    // Bam + hai lan o "On when humidity below" (70 -> 72) va bat Khung 2
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
    await _goto(tester, 'Schedule');
    final n = rig.demo.writes.length;
    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();
    expect(find.text(S.batchChanges(1)), findsOneWidget);
    await _goto(tester, 'Overview');
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
    await _goto(tester, 'Groups & Repeat');
    // steps = 2 -> chi hien Buoc 1, Buoc 2
    expect(find.text('Step 1'), findsOneWidget);
    expect(find.text('Step 2'), findsOneWidget);
    expect(find.text('Step 3'), findsNothing);
    // p1_hold = true nen co "Hold time", p2_hold = false nen an
    expect(find.text('Hold time'), findsOneWidget);
    await _close(tester, rig);
  });

  testWidgets('Top App Bar: nut [≡] ben trai mo menu he thong, rong toi da 320dp, du cac nhom', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    expect(tester.getSize(find.byType(AppBar)).height, greaterThanOrEqualTo(Vp.barHeight));
    expect(tester.getCenter(find.byIcon(Icons.menu)).dx, lessThan(56));
    expect(find.byType(Drawer), findsNothing);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Drawer)).width, 320);
    Finder inDrawer(String t) => find.descendant(of: find.byType(Drawer), matching: find.text(t));
    // Khoi thong tin: ten thiet bi + trang thai ket noi
    expect(inDrawer('DEMO-RELAY'), findsOneWidget);
    expect(inDrawer(S.connected), findsOneWidget);
    for (final t in [S.secDevice, S.secApp, S.deviceList, 'Alarm settings', 'Sensor setup', 'Device', S.deviceInfo, S.reloadInterface, S.settings, S.helpAbout, S.disconnect]) {
      expect(inDrawer(t), findsOneWidget, reason: t);
    }
    // Cham vung mo ben phai de dong menu
    await tester.tapAt(const Offset(800, 400));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
    await _close(tester, rig);
  });

  testWidgets('chuong thong bao hien so bao dong dang bat va danh sach bao dong', (tester) async {
    final rig = await _open(tester, 'demo_relay.json');
    // alarm = 2 -> 1 bao dong
    expect(activeAlarms(rig.session), ['Clock not set']);
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('1')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.notifications_active));
    await tester.pumpAndSettle();
    expect(find.text(S.alarmsTitle), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await _close(tester, rig);
  });

  testWidgets('Settings > Theme: doi sang/toi ap dung ngay va luu lai', (tester) async {
    final store = MemoryStore();
    final ctl = AppSettings(store);
    expect(ctl.mode, ThemeMode.system);
    final rig = _Rig();
    rig.session = DeviceSession(
      connector: () async => rig.demo = DemoTransport.fromJson(_demo('demo_relay.json'), tick: null, seed: 7),
    );
    await rig.session.connect();
    await tester.pumpWidget(SettingsScope(
      settings: ctl,
      child: ListenableBuilder(
        listenable: ctl,
        builder: (context, _) => MaterialApp(
          theme: vpHubTheme(Brightness.light),
          darkTheme: vpHubTheme(Brightness.dark),
          themeMode: ctl.mode,
          home: DeviceScreen(session: rig.session),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.theme));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.themeDark));
    await tester.pumpAndSettle();
    expect(ctl.mode, ThemeMode.dark);
    expect(store.getString('theme'), 'dark');
    expect(AppSettings(store).mode, ThemeMode.dark);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(DeviceScreen)));
    expect(theme.scaffoldBackgroundColor, Vp.darkBg);
    expect(theme.colorScheme.surface, Vp.darkCard);
    await _close(tester, rig);
  });

  test('bang mau theo quy chuan: khong den thuan / trang thuan o che do toi, mau canh bao dung ma', () {
    final l = vpHubTheme(Brightness.light), d = vpHubTheme(Brightness.dark);
    expect(l.scaffoldBackgroundColor, const Color(0xFFF8F9FA));
    expect(l.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(l.colorScheme.onSurface, const Color(0xFF1E293B));
    expect(l.colorScheme.onSurfaceVariant, const Color(0xFF64748B));
    expect(l.colorScheme.primary, const Color(0xFF0284C7));
    expect(Vp.ok(l.colorScheme), const Color(0xFF15803D));
    expect(l.colorScheme.tertiaryContainer, const Color(0xFFFEF3C7));
    expect(l.colorScheme.onTertiaryContainer, const Color(0xFF92400E));
    expect(l.colorScheme.errorContainer, const Color(0xFFFEE2E2));
    expect(l.colorScheme.onErrorContainer, const Color(0xFF991B1B));
    expect(d.scaffoldBackgroundColor, const Color(0xFF0F172A));
    expect(d.colorScheme.surface, const Color(0xFF1E293B));
    expect(d.colorScheme.onSurface, const Color(0xFFF1F5F9));
    expect(d.colorScheme.onSurfaceVariant, const Color(0xFF94A3B8));
    expect(d.colorScheme.primary, const Color(0xFF38BDF8));
    expect(Vp.ok(d.colorScheme), const Color(0xFF22C55E));
    expect(d.colorScheme.tertiaryContainer, const Color(0xFF451A03));
    expect(d.colorScheme.onTertiaryContainer, const Color(0xFFFDE047));
    expect(d.colorScheme.errorContainer, const Color(0xFF450A0A));
    expect(d.colorScheme.onErrorContainer, const Color(0xFFFCA5A5));
    expect(d.scaffoldBackgroundColor, isNot(const Color(0xFF000000)));
    expect(d.colorScheme.onSurface, isNot(const Color(0xFFFFFFFF)));
  });

  testWidgets('Settings > Language: doi Anh -> Viet ap dung ngay ca man dang mo va luu lai', (tester) async {
    addTearDown(() => Lang.code = Lang.en);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(900, 5000);
    addTearDown(tester.view.reset);
    final store = MemoryStore();
    final ctl = AppSettings(store);
    expect(ctl.lang, Lang.en);
    final rig = _Rig();
    rig.session = DeviceSession(
      connector: () async => rig.demo = DemoTransport.fromJson(_demo('demo_relay.json'), tick: null, seed: 7),
    );
    await rig.session.connect();
    await tester.pumpWidget(SettingsScope(
      settings: ctl,
      child: MaterialApp(theme: vpHubTheme(Brightness.light), home: DeviceScreen(session: rig.session)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Connected'), findsOneWidget);
    expect(_button('ON'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(ctl.lang, Lang.vi);
    expect(store.getString('lang'), 'vi');
    // Chu cua app tren man dang mo doi ngay
    expect(find.text('Đã kết nối'), findsOneWidget);
    expect(find.text('Connected'), findsNothing);
    expect(_button('BẬT'), findsOneWidget);
    expect(_button('TẮT'), findsOneWidget);
    // Mo lai app: van la tieng Viet
    Lang.code = Lang.en;
    expect(AppSettings(store).lang, Lang.vi);
    expect(Lang.isVi, isTrue);
    await _close(tester, rig);
  });

  test('schema luu san ban tieng Viet va tieng Anh co cung cau truc', () {
    // Bo het chu hien thi, chi giu id / kieu / goi y / dieu kien
    dynamic strip(dynamic j, [String? key]) {
      if (j is Map) {
        return {
          for (final e in j.entries)
            if (!const {'l', 'd', 'c', 'g', 'title', 'label', 'state', 'note', 'n_st', 'n_why'}.contains(e.key))
              e.key: strip(e.value, e.key as String),
        };
      }
      if (j is List) {
        // opt: giu gia tri va icon, bo nhan
        if (key == 'opt') return [for (final o in j) o is List ? [o[0], if (o.length > 2) o[2]] : null];
        return [for (final e in j) strip(e, key)];
      }
      if (key == 'u' && j == 'phút') return 'min';
      return j;
    }

    for (final f in ['assets/legacy/c3relay_v1', 'assets/demo/demo_relay', 'assets/demo/demo_all_types']) {
      final en = jsonDecode(File('$f.json').readAsStringSync());
      final vi = jsonDecode(File('$f.vi.json').readAsStringSync());
      expect(jsonEncode(strip(vi)), jsonEncode(strip(en)), reason: f);
    }
  });

  testWidgets('dom:"agri" -> bo giao dien nong nghiep (xanh la); khong co dom -> cong nghiep', (tester) async {
    // Thiet bi mau relay khai dom:"agri"
    var rig = await _open(tester, 'demo_relay.json');
    expect(rig.session.info!.domain, 'agri');
    var theme = Theme.of(tester.element(find.byType(TabBar)));
    expect(theme.appBarTheme.backgroundColor, const Color(0xFF14532D));
    expect(theme.colorScheme.primary, const Color(0xFF15803D));
    expect(VpBars.of(tester.element(find.byType(TabBar))).tabs, const Color(0xFF166534));
    // Trang con mo tu menu he thong giu bo nong nghiep
    await _openFromMenu(tester, 'Alarm settings');
    expect(Theme.of(tester.element(find.text('Alarm thresholds'))).colorScheme.primary, const Color(0xFF15803D));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _close(tester, rig);

    // Thiet bi khong khai dom: cong nghiep (xam dam + xanh duong)
    rig = await _openJson(tester, _v10(2));
    expect(rig.session.info!.domain, 'ind');
    theme = Theme.of(tester.element(find.byType(TabBar)));
    expect(theme.appBarTheme.backgroundColor, const Color(0xFF0F172A));
    expect(theme.colorScheme.primary, const Color(0xFF0284C7));
    await _close(tester, rig);
  });

  // Hai file mau cua bo quy chuan (docs/mau): mo duoc, moi man ve du, dung linh vuc
  for (final (file, dom, bar) in [
    ('mau_nong_nghiep.json', 'agri', const Color(0xFF14532D)),
    ('mau_cong_nghiep.json', 'ind', const Color(0xFF0F172A)),
  ]) {
    testWidgets('file mau $file: ve du moi man, linh vuc $dom', (tester) async {
      final src = File('../docs/mau/$file').readAsStringSync();
      final rig = await _openJson(tester, src);
      final s = rig.session;
      expect(s.info!.domain, dom);
      expect(Theme.of(tester.element(find.byType(AppBar).first)).appBarTheme.backgroundColor, bar);
      // Mau phai dung quy chuan: moi man co icon, khong co kieu / man loi
      for (final sc in s.screens) {
        expect(sc.error, isNull, reason: sc.id);
        expect(sc.icon, isNotNull, reason: sc.id);
        expect(sc.fields.every((f) => f.known), isTrue, reason: sc.id);
      }
      expect(s.screens.any((sc) => sc.menu), isTrue);
      for (var i = 0; i < s.screens.length; i++) {
        final sc = s.screens[i];
        if (sc.menu) {
          await _openFromMenu(tester, sc.title);
        } else {
          await _goto(tester, sc.title);
        }
        expect(tester.takeException(), isNull, reason: sc.id);
        expect(s.current, i);
        for (final f in sc.fields) {
          // The bao dong khi khong co bao dong hien "No active alarms" thay cho nhan
          if (f.ifCond != null || f.hint('alarm')) continue;
          expect(find.textContaining(f.label), findsWidgets, reason: 'truong ${f.id}');
        }
        if (sc.menu) {
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
      }
      // Gia tri mau phai vua goi VALUES 240 byte cua tung man (kem hdr)
      final j = jsonDecode(src) as Map<String, dynamic>;
      final values = j['values'] as Map<String, dynamic>;
      final hdr = (j['info']['hdr'] as List).cast<String>();
      for (final sc in s.screens) {
        final ids = {...hdr, for (final f in sc.fields) f.id, for (final g in sc.repGroups) for (final f in g.fields) f.id};
        final pkt = jsonEncode({for (final id in ids) if (values.containsKey(id)) id: values[id]});
        expect(utf8.encode(pkt).length, lessThanOrEqualTo(240), reason: 'VALUES man ${sc.id}');
      }
      await _close(tester, rig);
    });
  }
}
