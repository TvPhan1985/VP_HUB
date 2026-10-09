import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/app_settings.dart';
import 'package:vphub/core/device_session.dart';
import 'package:vphub/core/model/vph_info.dart';
import 'package:vphub/core/model/vph_schema.dart';
import 'package:vphub/core/model/vph_value.dart';
import 'package:vphub/core/schema_cache.dart';
import 'package:vphub/core/transport/demo_transport.dart';
import 'package:vphub/core/transport/transport.dart';
import 'package:vphub/ui/render/field_widget.dart';
import 'package:vphub/ui/screens/device_screen.dart';

import 'helpers.dart';

final String _json = jsonEncode({
  'info': {'proto': 'vph', 'pv': 1, 'model': 'm', 'name': 'DEV-1', 'fw': '1.0.0'},
  'screens': [
    {
      'id': 'main',
      'l': 'Main',
      'f': [
        {'id': 'out', 'l': 'Pump', 't': 'bool', 'w': 'hero,btns'},
        {'id': 'beep', 'l': 'Test buzzer', 't': 'act', 'c': 'Sound the buzzer?'},
        {'id': '_reboot', 'l': 'Restart device', 't': 'act', 'ic': 'reset', 'c': 'Restart device?'},
      ],
    },
    {
      'id': 'lim',
      'l': 'Limits',
      'save': 'batch',
      'f': [
        {'id': 'hi', 'l': 'High limit', 't': 'num', 'st': 1},
      ],
    },
  ],
  'values': {'out': false, 'hi': 50},
});

/// Thiet bi mau nhung lenh ghi chi xong khi test cho phep (de thay trang thai dang cho RESULT)
class _SlowDemo implements DeviceTransport {
  final DemoTransport inner;
  final Completer<void> gate = Completer<void>();
  _SlowDemo(this.inner);

  @override
  Future<VphResult> write(String id, dynamic v) async {
    await gate.future;
    return inner.write(id, v);
  }

  @override
  String get protoId => inner.protoId;
  @override
  bool get legacy => inner.legacy;
  @override
  TransportStats get stats => inner.stats;
  @override
  Future<VphInfo> open() => inner.open();
  @override
  Future<List<VphScreen>> loadScreens({bool refresh = false}) => inner.loadScreens(refresh: refresh);
  @override
  Future<void> start() => inner.start();
  @override
  Stream<Map<String, dynamic>> get values => inner.values;
  @override
  Stream<void> get lost => inner.lost;
  @override
  Future<void> select(int screen) => inner.select(screen);
  @override
  Future<VphResult> writeBatch(Map<String, dynamic> set) => inner.writeBatch(set);
  @override
  Future<void> close() => inner.close();
}

void main() {
  late List<String> haptics;

  setUp(() {
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
        (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
      return null;
    });
  });

  Future<(DeviceSession, _SlowDemo)> open(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.reset);
    late _SlowDemo slow;
    final s = DeviceSession(
      connector: () async => slow = _SlowDemo(DemoTransport.fromJson(_json, tick: null, seed: 1)),
    );
    await s.connect();
    await tester.pumpWidget(wrapApp(settings: AppSettings(MemoryStore()), home: DeviceScreen(session: s)));
    await tester.pumpAndSettle();
    return (s, slow);
  }

  Future<void> close(WidgetTester tester, DeviceSession s) async {
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  }

  Finder button(String text) =>
      find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((w) => w is FilledButton));

  testWidgets('bam ON: rung nhe, vong cho hien ngay tren nut ON cho toi khi co RESULT', (tester) async {
    final (s, slow) = await open(tester);
    expect(find.byType(ButtonSpinner), findsNothing);
    await tester.tap(button(l10n.onCaps));
    await tester.pump();
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    expect(find.descendant(of: button(l10n.onCaps), matching: find.byType(ButtonSpinner)), findsOneWidget);
    expect(find.descendant(of: button(l10n.offCaps), matching: find.byType(ButtonSpinner)), findsNothing);
    slow.gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ButtonSpinner), findsNothing);
    expect(s.values['out'], true);
    await close(tester, s);
  });

  testWidgets('hop xac nhan: tieu de la cau hoi, nut lap lai hanh dong; Restart mau do, lenh thuong thi khong',
      (tester) async {
    final (s, slow) = await open(tester);
    slow.gate.complete();
    FilledButton confirmButton(String label) =>
        tester.widget<FilledButton>(find.descendant(of: find.byType(AlertDialog), matching: button(label)));

    await tester.tap(find.text('Test buzzer'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Sound the buzzer?')), findsOneWidget);
    expect(find.text('OK'), findsNothing);
    expect(confirmButton('Test buzzer').style, isNull);
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(haptics, isEmpty);

    await tester.tap(find.text('Restart device'));
    await tester.pumpAndSettle();
    final cs = Theme.of(tester.element(find.byType(AlertDialog))).colorScheme;
    expect(confirmButton('Restart device').style!.backgroundColor!.resolve({}), cs.error);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Restart device')));
    await tester.pumpAndSettle();
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    expect(dangerousAction(VphField.fromJson({'id': 'x', 't': 'act', 'ic': 'stop'})), isTrue);
    expect(dangerousAction(VphField.fromJson({'id': 'x', 't': 'act', 'ic': 'mute'})), isFalse);
    await close(tester, s);
  });

  testWidgets('bam Save: rung nhe; nut quay lai o goc trai ve danh sach', (tester) async {
    final (s, slow) = await open(tester);
    slow.gate.complete();
    await tester.tap(find.widgetWithText(Tab, 'LIMITS'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(haptics, isEmpty);
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    expect(s.values['hi'], 51);
    await tester.pump(const Duration(seconds: 3));
    // Khong con thay doi chua luu: bam quay lai la roi man Thiet bi ngay
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(find.byType(DeviceScreen), findsNothing);
    s.dispose();
  });
}
