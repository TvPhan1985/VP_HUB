import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/app_settings.dart';
import 'package:vphub/core/consts.dart';
import 'package:vphub/core/device_session.dart';
import 'package:vphub/core/schema_cache.dart';
import 'package:vphub/core/transport/demo_transport.dart';
import 'package:vphub/core/transport/legacy_kiln.dart';
import 'package:vphub/ui/screens/device_screen.dart';
import 'package:vphub/ui/screens/settings_screen.dart';

import 'helpers.dart';
import 'kiln_schemas.dart';

AppSettings _settings({bool tech = false, String? pin}) => AppSettings(MemoryStore()
  ..data['user_mode'] = tech ? 'technician' : 'standard'
  ..data.addAll({'tech_pin': ?pin}));

/// 3 tab (tab thu 3 la adv), man batch co truong adv, the hero co dong phu tro toi truong adv
final String _json = jsonEncode({
  'info': {'proto': 'vph', 'pv': 1, 'model': 'm', 'name': 'DEV-1', 'fw': '1.0.0'},
  'screens': [
    {
      'id': 'main',
      'l': 'Main',
      'f': [
        {'id': 'out', 'l': 'Pump', 't': 'bool', 'w': 'hero', 'sub': 'gain'},
        {'id': 'gain', 'l': 'Loop gain', 't': 'num', 'adv': 1},
        {'id': 'note', 'l': 'Gain is high', 't': 'bool', 'ro': 1, 'w': 'note', 'if': 'gain==7'},
      ],
    },
    {
      'id': 'lim',
      'l': 'Limits',
      'save': 'batch',
      'f': [
        {'id': 'hi', 'l': 'High limit', 't': 'num', 'st': 1},
        {'id': 'off', 'l': 'Sensor offset', 't': 'num', 'st': 1, 'adv': 1},
      ],
    },
    {
      'id': 'pid',
      'l': 'Tuning',
      'adv': 1,
      'f': [
        {'id': 'kp', 'l': 'Kp', 't': 'num'},
      ],
    },
  ],
  'values': {'out': true, 'gain': 7, 'note': true, 'hi': 50, 'off': 2, 'kp': 1.5},
});

class _Rig {
  late DemoTransport demo;
  late DeviceSession session;
}

Future<_Rig> _open(WidgetTester tester, String json, AppSettings st) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(900, 3000);
  addTearDown(tester.view.reset);
  final rig = _Rig();
  rig.session = DeviceSession(connector: () async => rig.demo = DemoTransport.fromJson(json, tick: null, seed: 7));
  await rig.session.connect();
  await tester.pumpWidget(wrapApp(settings: st, home: DeviceScreen(session: rig.session)));
  await tester.pumpAndSettle();
  return rig;
}

Future<void> _close(WidgetTester tester, _Rig rig) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
  await tester.pumpWidget(const SizedBox());
  rig.session.dispose();
  await tester.pump();
}

Finder _tab(String title) => find.widgetWithText(Tab, title.toUpperCase());

void main() {
  group('AppSettings', () {
    test('mac dinh Standard; bat Technician khong PIN; luu lai', () async {
      final store = MemoryStore();
      final st = AppSettings(store);
      expect(st.userMode, UserMode.standard);
      expect(st.hasPin, isFalse);
      expect(await st.setTechnician(true), isTrue);
      expect(st.technician, isTrue);
      expect(store.getString('user_mode'), 'technician');
      expect(AppSettings(store).technician, isTrue);
      expect(await st.setTechnician(false), isTrue);
      expect(AppSettings(store).technician, isFalse);
    });

    test('co PIN: sai thi khong bat, dung thi bat; tat khong hoi PIN', () async {
      final st = AppSettings(MemoryStore());
      await st.setPin('4821');
      expect(st.hasPin, isTrue);
      expect(await st.setTechnician(true), isFalse);
      expect(await st.setTechnician(true, pin: '0000'), isFalse);
      expect(st.technician, isFalse);
      expect(await st.setTechnician(true, pin: '4821'), isTrue);
      expect(st.technician, isTrue);
      expect(await st.setTechnician(false), isTrue);
      await st.setPin(null);
      expect(st.hasPin, isFalse);
      expect(() => st.setPin('12a'), throwsArgumentError);
    });

    test('tuy chon mac dinh: tu ket noi bat, giu man hinh sang tat', () async {
      final st = AppSettings(MemoryStore());
      expect(st.autoConnect, isTrue);
      expect(st.keepScreenOn, isFalse);
      await st.setAutoConnect(false);
      expect(AppSettings(st.store).autoConnect, isFalse);
    });

    test('Clear saved interfaces chi xoa cache schema', () async {
      final store = MemoryStore();
      final cache = SchemaCache(store);
      await cache.put('vph/a/1', ['{}']);
      await cache.put('vph/b/2', ['{}']);
      await store.setString('theme', 'dark');
      expect(await cache.clearAll(), 2);
      expect(cache.get('vph/a/1'), isNull);
      expect(store.getString('theme'), 'dark');
    });
  });

  testWidgets('Standard: an man adv va truong adv; if / sub van dung truong adv', (tester) async {
    final rig = await _open(tester, _json, _settings());
    expect(_tab('Main'), findsOneWidget);
    expect(_tab('Limits'), findsOneWidget);
    expect(_tab('Tuning'), findsNothing);
    expect(find.text(kTechChip), findsNothing);
    // Truong adv khong co hang rieng, nhung dong phu cua the hero va dieu kien if van dung gia tri cua no
    expect(find.text('Loop gain'), findsNothing);
    expect(find.text('Loop gain: 7'), findsOneWidget);
    expect(find.text('Gain is high'), findsOneWidget);
    await _close(tester, rig);
  });

  testWidgets('Technician: thay du, co chip TECH', (tester) async {
    final rig = await _open(tester, _json, _settings(tech: true));
    expect(_tab('Tuning'), findsOneWidget);
    expect(find.text(kTechChip), findsOneWidget);
    expect(find.text('Loop gain'), findsOneWidget);
    await _close(tester, rig);
  });

  testWidgets('doi che do: man dang mo cap nhat ngay; tab dang mo bi an thi ve tab dau', (tester) async {
    final st = _settings(tech: true);
    final rig = await _open(tester, _json, st);
    await tester.tap(_tab('Tuning'));
    await tester.pumpAndSettle();
    expect(rig.session.current, 2);
    expect(find.text('Kp'), findsOneWidget);
    await st.setTechnician(false);
    await tester.pumpAndSettle();
    expect(_tab('Tuning'), findsNothing);
    expect(find.text('Kp'), findsNothing);
    expect(find.text(kTechChip), findsNothing);
    expect(rig.session.current, 0);
    expect(find.text('Pump'), findsOneWidget);
    // Bat lai: tab adv hien lai ngay
    await st.setTechnician(true);
    await tester.pumpAndSettle();
    expect(_tab('Tuning'), findsOneWidget);
    expect(find.text('Loop gain'), findsOneWidget);
    await _close(tester, rig);
  });

  testWidgets('man batch o Standard: lenh set chi gui truong da sua, khong dung truong an', (tester) async {
    final rig = await _open(tester, _json, _settings());
    await tester.tap(_tab('Limits'));
    await tester.pumpAndSettle();
    expect(find.text('High limit'), findsOneWidget);
    expect(find.text('Sensor offset'), findsNothing);
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(rig.demo.writes.last, {
      'set': {'hi': 51},
    });
    await _close(tester, rig);
  });

  testWidgets('thiet bi mau relay: Standard khong thay Sensor setup va nut Restart, Technician thay', (tester) async {
    final src = File('assets/demo/demo_relay.json').readAsStringSync();
    Finder inDrawer(String t) => find.descendant(of: find.byType(Drawer), matching: find.text(t));
    Future<void> openDrawer() async {
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
    }

    var rig = await _open(tester, src, _settings());
    await openDrawer();
    expect(inDrawer('Alarm settings'), findsOneWidget);
    expect(inDrawer('Sensor setup'), findsNothing);
    expect(inDrawer(l10n.reloadInterface), findsNothing);
    expect(inDrawer(l10n.deviceInfo), findsOneWidget);
    expect(inDrawer(l10n.settings), findsOneWidget);
    await tester.tap(inDrawer('Device'));
    await tester.pumpAndSettle();
    expect(find.text('Device name'), findsOneWidget);
    expect(find.text('Restart device'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _close(tester, rig);

    rig = await _open(tester, src, _settings(tech: true));
    await openDrawer();
    expect(inDrawer('Sensor setup'), findsOneWidget);
    expect(inDrawer(l10n.reloadInterface), findsOneWidget);
    await tester.tap(inDrawer('Device'));
    await tester.pumpAndSettle();
    expect(find.text('Restart device'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _close(tester, rig);
  });

  testWidgets('Settings: bat Technician co PIN - sai bao loi, dung thi bat; nhom Developer tools chi o Technician',
      (tester) async {
    final st = _settings(pin: '4821');
    await tester.pumpWidget(wrapApp(settings: st, home: const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text(l10n.secDeveloper), findsNothing);
    expect(find.text(l10n.demoTitle), findsNothing);
    await tester.tap(find.text(l10n.techMode));
    await tester.pumpAndSettle();
    expect(find.text(l10n.enterPin), findsWidgets);
    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.text(l10n.turnOn));
    await tester.pumpAndSettle();
    expect(find.text(l10n.pinWrong), findsOneWidget);
    expect(st.technician, isFalse);
    await tester.enterText(find.byType(TextField), '4821');
    await tester.tap(find.text(l10n.turnOn));
    await tester.pumpAndSettle();
    expect(st.technician, isTrue);
    expect(find.text(l10n.secDeveloper), findsOneWidget);
    expect(find.text(l10n.demoTitle), findsOneWidget);
    expect(find.text(l10n.clearCache), findsOneWidget);
    expect(find.text(l10n.removePin), findsOneWidget);
    // Tat thi khong hoi PIN
    await tester.tap(find.text(l10n.techMode));
    await tester.pumpAndSettle();
    expect(st.technician, isFalse);
    expect(find.text(l10n.secDeveloper), findsNothing);
  });

  test('lo nung: PID, canh bao lech, hieu chuan, tu do la man adv; van hanh va chuong trinh thi khong', () {
    final adv = {
      for (final raw in kKilnSchemas)
        (jsonDecode(raw) as Map)['id']: patchKilnSchema(jsonDecode(raw) as Map<String, dynamic>)['adv'] == 1,
    };
    expect(adv, {
      'operation': false,
      'pid': true,
      'alarm': true,
      'calibration': true,
      'autotune': true,
      'program': false,
      'program_steps': false,
    });
  });
}
