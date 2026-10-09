import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/app_settings.dart';
import 'package:vphub/core/known_devices.dart';
import 'package:vphub/core/schema_cache.dart';
import 'package:vphub/core/transport/ble_scanner.dart';
import 'package:vphub/core/transport/gatt_link.dart';
import 'package:vphub/core/transport/transport_registry.dart';
import 'package:vphub/ui/screens/device_screen.dart';
import 'package:vphub/ui/screens/onboarding_screen.dart';
import 'package:vphub/ui/screens/scan_screen.dart';

import 'fake_link.dart';
import 'helpers.dart';

/// Bo quet gia: test tu dua ket qua quet vao
class FakeScanner extends DeviceScanner {
  final List<ScanHit> _hits = [];
  bool _scanning = false;
  bool permission = true;
  bool locOff = false;
  int starts = 0;
  int openedLocation = 0;
  Duration? lastTimeout;

  /// Thiet bi VPH gia se duoc ket noi khi mo
  final FakeVphDevice device = FakeVphDevice(
    info: {'proto': 'vph', 'pv': 1, 'model': 'm', 'name': 'PUMP-A1B2', 'fw': '1.0.0', 'n': 1},
    schemas: [
      jsonEncode({
        'id': 'main',
        'l': 'Main',
        'f': [
          {'id': 't', 'l': 'Temperature', 't': 'num', 'ro': 1},
        ],
      }),
    ],
    values: [
      {'t': 25},
    ],
  );

  @override
  bool get scanning => _scanning;

  @override
  bool get adapterOn => true;

  @override
  List<ScanHit> get hits => List.of(_hits);

  @override
  Future<bool> ensurePermissions() async => permission;

  @override
  Future<void> start({Duration timeout = const Duration(seconds: 10)}) async {
    starts++;
    lastTimeout = timeout;
    _hits.clear();
    _scanning = true;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    if (!_scanning) return;
    _scanning = false;
    notifyListeners();
  }

  @override
  Future<void> turnOnBluetooth() async {}

  @override
  Future<bool> locationOff() async => locOff;

  @override
  Future<void> openLocationSettings() async => openedLocation++;

  @override
  GattLink link(String id, String name) => device.link;

  void see(String id, String name) {
    _hits.add(ScanHit(id: id, name: name, rssi: -55, kind: TransportKind.vph));
    notifyListeners();
  }
}

Future<MemoryStore> _storeWith(List<KnownDevice> devices, {bool tech = false}) async {
  final store = MemoryStore()
    ..data['onboarded'] = '1'
    ..data['user_mode'] = tech ? 'technician' : 'standard';
  final k = KnownDevices(store);
  for (final d in devices) {
    await k.remember(d);
  }
  return store;
}

Future<void> _pump(WidgetTester tester, MemoryStore store, FakeScanner scanner) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(900, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(wrapApp(settings: AppSettings(store), home: ScanScreen(store: store, scanner: scanner)));
  await tester.pump();
  await tester.pump();
}

const _old = KnownDevice(id: 'AA:01', name: 'Old relay', model: 'c3relay', lastMs: 1000);
const _recent = KnownDevice(id: 'AA:02', name: 'Farm pump', model: 'growhub', lastMs: 5000);

void main() {
  testWidgets('mo app, thiet bi da nho dang tat: o lai man Quet, khong nhay vao thiet bi, quet het 10 s',
      (tester) async {
    final scanner = FakeScanner();
    final store = await _storeWith([_old, _recent]);
    await _pump(tester, store, scanner);
    expect(scanner.starts, 1);
    expect(scanner.lastTimeout, const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(DeviceScreen), findsNothing);
    expect(find.text(l10n.myDevices), findsOneWidget);
    expect(find.text('Farm pump'), findsOneWidget);
    // Qua 4 s roi moi thay: khong con tu ket noi nua
    scanner.see('AA:02', 'GROW-A1B2');
    await tester.pump();
    expect(find.byType(DeviceScreen), findsNothing);
    expect(scanner.scanning, isTrue);
  });

  testWidgets('mo app, thay thiet bi da nho gan nhat trong 4 s dau: tu ket noi', (tester) async {
    final scanner = FakeScanner();
    final store = await _storeWith([_recent, _old]);
    await _pump(tester, store, scanner);
    // Thay thiet bi cu hon: khong ket noi
    scanner.see('AA:01', 'C3-RELAY');
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DeviceScreen), findsNothing);
    // Thay thiet bi dung gan nhat (lastMs lon nhat)
    scanner.see('AA:02', 'GROW-A1B2');
    await tester.pumpAndSettle();
    expect(find.byType(DeviceScreen), findsOneWidget);
    expect(scanner.scanning, isFalse);
    expect(find.text('Temperature'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // Ve man Quet: quet lai, bam tiep duoc (khong bi ket _busy)
    expect(find.byType(DeviceScreen), findsNothing);
    expect(scanner.starts, 2);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('tat Auto-connect: thay thiet bi da nho cung khong tu ket noi', (tester) async {
    final scanner = FakeScanner();
    final store = await _storeWith([_recent])
      ..data['auto_connect'] = '0';
    await _pump(tester, store, scanner);
    scanner.see('AA:02', 'GROW-A1B2');
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DeviceScreen), findsNothing);
  });

  testWidgets('man trong: cau huong dan va nut Scan again; keo xuong de quet lai', (tester) async {
    final scanner = FakeScanner();
    await _pump(tester, await _storeWith([]), scanner);
    await scanner.stop();
    await tester.pump();
    expect(find.text(l10n.scanEmptyTitle), findsOneWidget);
    expect(find.text(l10n.scanEmptyHint), findsOneWidget);
    await tester.tap(find.text(l10n.scanAgain));
    await tester.pump();
    await tester.pump();
    expect(scanner.starts, 2);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    await tester.fling(find.byType(ListView), const Offset(0, 1000), 1500);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(scanner.starts, 3);
  });

  testWidgets('Android 6-11, Location tat: the huong dan va nut mo cai dat vi tri', (tester) async {
    final scanner = FakeScanner()..locOff = true;
    await _pump(tester, await _storeWith([]), scanner);
    expect(find.text(l10n.locationOff), findsOneWidget);
    await tester.tap(find.text(l10n.openLocationSettings));
    await tester.pump();
    expect(scanner.openedLocation, 1);
  });

  testWidgets('quyen bi tu choi: the huong dan va nut Open settings, khong quet', (tester) async {
    final scanner = FakeScanner()..permission = false;
    await _pump(tester, await _storeWith([]), scanner);
    expect(find.text(l10n.permMissing), findsOneWidget);
    expect(find.text(l10n.openSettings), findsOneWidget);
    expect(scanner.starts, 0);
  });

  testWidgets('nhan giu the thiet bi: Rename chi doi ten trong app; Remove co Undo', (tester) async {
    final scanner = FakeScanner();
    final store = await _storeWith([_old, _recent])
      ..data['auto_connect'] = '0';
    await _pump(tester, store, scanner);
    // Dung quet de thanh tien trinh khong chay mai (pumpAndSettle)
    await scanner.stop();
    await tester.pump();
    final known = KnownDevices(store);
    await tester.longPress(find.text('Old relay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.rename));
    await tester.pumpAndSettle();
    expect(find.text(l10n.renameDevice), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Greenhouse 2');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(find.text('Greenhouse 2'), findsOneWidget);
    expect(known.list().firstWhere((d) => d.id == 'AA:01').alias, isTrue);

    await tester.longPress(find.text('Farm pump'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.remove));
    await tester.pumpAndSettle();
    expect(find.text('Farm pump'), findsNothing);
    expect(find.text(l10n.deviceRemoved), findsOneWidget);
    await tester.tap(find.text(l10n.undo));
    await tester.pumpAndSettle();
    expect(find.text('Farm pump'), findsOneWidget);
    expect(known.list().map((d) => d.id), ['AA:02', 'AA:01']);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('the thiet bi: Standard chi co ten va model; Technician them dia chi, nhan VPH, dBm', (tester) async {
    var scanner = FakeScanner();
    var store = await _storeWith([_recent])
      ..data['auto_connect'] = '0';
    await _pump(tester, store, scanner);
    scanner.see('AA:02', 'GROW-A1B2');
    await tester.pump();
    expect(find.text('growhub'), findsOneWidget);
    expect(find.textContaining('AA:02'), findsNothing);
    expect(find.text('VPH'), findsNothing);
    expect(find.text('-55 dBm'), findsNothing);
    await tester.pumpWidget(const SizedBox());

    scanner = FakeScanner();
    store = await _storeWith([_recent], tech: true)
      ..data['auto_connect'] = '0';
    await _pump(tester, store, scanner);
    scanner.see('AA:02', 'GROW-A1B2');
    await tester.pump();
    expect(find.text('growhub · AA:02'), findsOneWidget);
    expect(find.text('VPH'), findsOneWidget);
    expect(find.text('-55 dBm'), findsOneWidget);
  });

  testWidgets('lan dau mo app: man gioi thieu, bam Allow moi xin quyen, roi luu onboarded', (tester) async {
    final store = MemoryStore();
    final settings = AppSettings(store);
    expect(settings.onboarded, isFalse);
    var asked = 0;
    await tester.pumpWidget(wrapApp(
      settings: settings,
      home: OnboardingScreen(requestPermission: () async {
        asked++;
        return true;
      }),
    ));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardBody), findsOneWidget);
    expect(find.text(l10n.onboardWhy), findsOneWidget);
    expect(asked, 0);
    await tester.tap(find.text(l10n.onboardAllow));
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(settings.onboarded, isTrue);
    expect(AppSettings(store).onboarded, isTrue);
  });
}
