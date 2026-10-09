import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/app_settings.dart';
import 'package:vphub/core/device_session.dart';
import 'package:vphub/core/model/vph_schema.dart';
import 'package:vphub/core/schema_cache.dart';
import 'package:vphub/core/transport/demo_transport.dart';
import 'package:vphub/ui/render/trend_chart.dart';
import 'package:vphub/ui/screens/device_screen.dart';

import 'helpers.dart';

final String _json = jsonEncode({
  'info': {'proto': 'vph', 'pv': 1, 'model': 'm', 'name': 'DEV-1', 'fw': '1.0.0'},
  'screens': [
    {
      'id': 'main',
      'l': 'Main',
      'f': [
        {'id': 't', 'l': 'Temperature', 't': 'num', 'u': '°C', 'dp': 1, 'ro': 1, 'w': 'tile,trend'},
      ],
    },
  ],
  'values': {'t': 25.4},
});

void main() {
  test('lastValuesAt, tuoi so lieu va co stale (nguong 15 s)', () async {
    var now = DateTime(2026, 10, 9, 8, 0, 0);
    late DemoTransport demo;
    final s = DeviceSession(
      connector: () async => demo = DemoTransport.fromJson(_json, tick: null, seed: 1),
      clock: () => now,
    );
    expect(s.dataAge, isNull);
    await s.connect();
    await Future<void>.delayed(Duration.zero);
    expect(s.lastValuesAt, now);
    expect(s.stale, isFalse);
    now = now.add(const Duration(seconds: 7));
    expect(s.dataAge, const Duration(seconds: 7));
    expect(s.stale, isFalse);
    now = now.add(const Duration(seconds: 13));
    expect(s.stale, isTrue);
    // Co goi moi: het cu
    demo.step();
    await Future<void>.delayed(Duration.zero);
    expect(s.lastValuesAt, now);
    expect(s.stale, isFalse);
    s.dispose();
  });

  test('lich su bieu do giu theo thiet bi: thoat man roi vao lai van con; thiet bi khac thi rieng', () async {
    final store = TrendStore();
    Future<DeviceSession> open(String? id) async {
      late DemoTransport demo;
      final s = DeviceSession(
        connector: () async => demo = DemoTransport.fromJson(_json, tick: null, seed: 1),
        deviceId: id,
        trendStore: store,
      );
      await s.connect();
      demo.step();
      demo.step();
      await Future<void>.delayed(Duration.zero);
      return s;
    }

    final a1 = await open('AA:01');
    final n = a1.trends['t']!.length;
    expect(n, greaterThanOrEqualTo(2));
    a1.dispose();
    final a2 = await open('AA:01');
    expect(a2.trends['t']!.length, greaterThan(n));
    a2.dispose();
    final b = await open('BB:02');
    expect(b.trends['t']!.length, lessThanOrEqualTo(n + 1));
    expect(identical(b.trends, store.of('BB:02')), isTrue);
    b.dispose();
    // Thiet bi mau (khong co dia chi): lich su rieng cua phien
    final d = await open(null);
    expect(identical(d.trends, store.of('AA:01')), isFalse);
    d.dispose();
  });

  test('chu khi cham bieu do: gia tri theo dp + don vi, va gio', () {
    final f = VphField.fromJson({'id': 't', 'l': 'T', 't': 'num', 'u': '°C', 'dp': 1});
    expect(trendTooltip(f, 25.44, DateTime(2026, 10, 9, 12, 5, 33)), '25.4 °C\n12:05:33');
    final g = VphField.fromJson({'id': 'n', 'l': 'N', 't': 'num', 'dp': 0});
    expect(trendTooltip(g, 120, DateTime(2026, 10, 9, 7, 0, 9)), '120\n07:00:09');
  });

  testWidgets('dong trang thai: Connected -> "updated N s ago" (> 5 s) -> "No new data" vang, so mo di (> 15 s)',
      (tester) async {
    late DemoTransport demo;
    final s = DeviceSession(connector: () async => demo = DemoTransport.fromJson(_json, tick: null, seed: 1));
    await tester.runAsync(s.connect);
    await tester.pumpWidget(wrapApp(
      settings: AppSettings(MemoryStore()),
      home: DeviceScreen(session: s),
    ));
    await tester.pump();
    expect(find.text(l10n.connected), findsOneWidget);
    double opacity() => tester
        .widgetList<Opacity>(find.ancestor(of: find.text('Temperature'), matching: find.byType(Opacity)))
        .map((o) => o.opacity)
        .reduce((a, b) => a < b ? a : b);
    expect(opacity(), 1);
    // Thoi gian that troi qua (DeviceSession dung dong ho that)
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5200)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('updated'), findsOneWidget);
    expect(find.text(l10n.connected), findsNothing);
    expect(opacity(), 1);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10200)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('No new data for'), findsOneWidget);
    expect(opacity(), 0.6);
    // Co du lieu moi: tro lai binh thuong
    await tester.runAsync(() async {
      demo.step();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.connected), findsOneWidget);
    expect(opacity(), 1);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));
}
