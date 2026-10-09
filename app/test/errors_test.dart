import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/app_settings.dart';
import 'package:vphub/core/device_session.dart';
import 'package:vphub/core/diag_log.dart';
import 'package:vphub/core/errors.dart';
import 'package:vphub/core/schema_cache.dart';
import 'package:vphub/core/transport/transport_registry.dart';
import 'package:vphub/core/transport/vph_transport.dart';
import 'package:vphub/l10n/l10n.dart';
import 'package:vphub/ui/screens/device_screen.dart';

import 'fake_link.dart';
import 'helpers.dart';

AppSettings _settings(bool tech) => AppSettings(MemoryStore()..data['user_mode'] = tech ? 'technician' : 'standard');

FakeVphDevice _device() => FakeVphDevice(
      info: {'proto': 'vph', 'pv': 1, 'model': 'm', 'name': 'DEV', 'fw': '1.0.0', 'n': 1},
      schemas: [
        jsonEncode({
          'id': 'main',
          'l': 'Main',
          'f': [
            {'id': 'sv', 'l': 'Setpoint', 't': 'num', 'st': 1},
            {'id': '_name', 'l': 'Device name', 't': 'str', 'max': 20},
          ],
        }),
      ],
      values: [
        {'sv': 100, '_name': 'DEV'},
      ],
    );

void main() {
  group('bang loi (PLAN_HOAN_THIEN §H6)', () {
    test('moi loai loi deu co cau tieng Anh dung bang', () {
      String t(ErrorKind k) => errorText(l10n, AppError(k));
      expect(t(ErrorKind.bluetoothOff), 'Bluetooth is off. Turn it on to connect.');
      expect(t(ErrorKind.permission), 'VP Hub needs Bluetooth access to connect.');
      expect(t(ErrorKind.unreachable), "Can't reach the device. Move closer and make sure it's powered on.");
      expect(t(ErrorKind.unsupported), "This device isn't supported by VP Hub.");
      expect(t(ErrorKind.badData), 'The device sent invalid data. Restart the device and try again.');
      expect(t(ErrorKind.noResponse), "The device didn't respond. Try again.");
      expect(t(ErrorKind.tooLong), 'Too many changes at once. Save fewer changes and try again.');
      expect(t(ErrorKind.unknown), 'Something went wrong. Try again.');
      // Thiet bi tu choi co `err`: hien nguyen van
      expect(errorText(l10n, const AppError.device('Set the low threshold below the high threshold.')),
          'Set the low threshold below the high threshold.');
      for (final k in ErrorKind.values) {
        expect(t(k), isNotEmpty, reason: k.name);
      }
    });

    test('doi exception thanh AppError', () {
      expect(AppError.from(TimeoutException('x'), fallback: ErrorKind.unreachable).kind, ErrorKind.unreachable);
      expect(AppError.from(TimeoutException('x')).kind, ErrorKind.noResponse);
      expect(AppError.from(Exception('Bluetooth not enabled')).kind, ErrorKind.bluetoothOff);
      expect(AppError.from(Exception('Missing permission BLUETOOTH_CONNECT')).kind, ErrorKind.permission);
      expect(AppError.from(const FormatException('bad json')).kind, ErrorKind.badData);
      expect(AppError.from(StateError('boom')).kind, ErrorKind.unknown);
      const e = AppError(ErrorKind.tooLong, 'x');
      expect(identical(AppError.from(e), e), isTrue);
      // Loi goc rut gon con 300 ky tu
      expect(AppError(ErrorKind.unknown, 'a' * 500).shortDetail!.length, 303);
    });

    test('thiet bi khong co dich vu ho tro -> unsupported; INFO sai -> badData; lenh qua dai -> tooLong', () async {
      final cache = SchemaCache(MemoryStore());
      await expectLater(
          connectTransport(FakeGattLink(services: ['0000180f-0000-1000-8000-00805f9b34fb']), cache),
          throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.unsupported)));

      final bad = _device()..info = {'proto': 'khac'};
      await expectLater(VphTransport(bad.link, cache).open(),
          throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.badData)));

      final dev = _device();
      final t = VphTransport(dev.link, cache);
      await t.open();
      final r = await t.writeBatch({for (var i = 0; i < 60; i++) 'field_$i': 12345});
      expect(r.ok, isFalse);
      expect(r.error!.kind, ErrorKind.tooLong);
      expect(dev.commands, isEmpty);
    });
  });

  group('nhat ky chan doan', () {
    test('vong dem giu 500 dong gan nhat', () {
      final log = DiagLog(now: () => DateTime(2026, 10, 9, 8, 5, 3));
      for (var i = 0; i < 620; i++) {
        log.add('dong $i');
      }
      expect(log.lines.length, DiagLog.maxLines);
      expect(log.lines.first, '2026-10-09 08:05:03 dong 120');
      expect(log.lines.last, endsWith('dong 619'));
    });

    test('ghi ra file; file day 256 KB thi xoay vong, khong vuot gioi han', () async {
      final dir = await Directory.systemTemp.createTemp('vphub_log_test');
      addTearDown(() => dir.delete(recursive: true));
      final f = File('${dir.path}/${DiagLog.fileName}');
      final log = DiagLog();
      await log.attach(f);
      log.add('Ket noi AA:BB');
      log.add('MTU = 247');
      await log.flush();
      expect(await f.readAsLines(), hasLength(2));
      final big = 'x' * 900;
      for (var i = 0; i < 400; i++) {
        log.add('$i $big');
        if (i % 50 == 0) await log.flush();
      }
      await log.flush();
      expect(await f.length(), lessThanOrEqualTo(DiagLog.maxBytes));
      final lines = await f.readAsLines();
      expect(lines.length, lessThanOrEqualTo(DiagLog.maxLines));
      expect(lines.last, contains('399 '));
      await log.clear();
      expect(log.lines, isEmpty);
      expect(await f.length(), 0);
    });

    test('lenh ghi: ghi id va so, khong ghi noi dung chuoi nguoi dung nhap', () async {
      final before = DiagLog.instance.lines.length;
      final dev = _device();
      final s = DeviceSession(connector: () async => VphTransport(dev.link, SchemaCache(MemoryStore())), deviceId: 'AA:BB');
      await s.connect();
      await s.edit(0, s.fieldById('sv')!, 150);
      await s.edit(0, s.fieldById('_name')!, 'Vuon-Bi-Mat');
      final lines = DiagLog.instance.lines.sublist(before).join('\n');
      expect(lines, contains('Ket noi AA:BB'));
      expect(lines, contains('Da ket noi DEV model=m fw=1.0.0'));
      expect(lines, contains('GHI sv=150 -> ok'));
      expect(lines, contains('GHI _name=<text> -> ok'));
      expect(lines.contains('Vuon-Bi-Mat'), isFalse);
      expect(logValue('enum', 'auto'), 'auto');
      expect(logValue('time', '08:30'), '08:30');
      s.dispose();
    });
  });

  group('nut Details', () {
    Future<DeviceSession> open(WidgetTester tester, bool tech, {required bool fail}) async {
      final dev = _device()..onWrite = (_) => null;
      dev.silent = true;
      final s = DeviceSession(
        connector: () async {
          if (fail) throw Exception('GATT status 133');
          return VphTransport(dev.link, SchemaCache(MemoryStore()), resultTimeout: const Duration(milliseconds: 50));
        },
      );
      // ignore: unawaited_futures
      s.connect();
      await tester.pumpWidget(wrapApp(settings: _settings(tech), home: DeviceScreen(session: s)));
      await tester.pumpAndSettle();
      return s;
    }

    testWidgets('ket noi that bai: Standard chi thay cau chuan; Technician co Details hien loi goc', (tester) async {
      var s = await open(tester, false, fail: true);
      expect(find.text(l10n.connectFailed), findsOneWidget);
      expect(find.text(l10n.errUnreachable), findsOneWidget);
      expect(find.textContaining('GATT status 133'), findsNothing);
      expect(find.text(l10n.details), findsNothing);
      expect(find.text(l10n.retry), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      s.dispose();

      s = await open(tester, true, fail: true);
      expect(find.text(l10n.errUnreachable), findsOneWidget);
      await tester.tap(find.text(l10n.details));
      await tester.pumpAndSettle();
      expect(find.text(l10n.errorDetails), findsOneWidget);
      expect(find.textContaining('GATT status 133'), findsOneWidget);
      await tester.tap(find.text(l10n.close));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    });

    testWidgets('thiet bi khong tra RESULT: SnackBar "The device didn\'t respond. Try again."', (tester) async {
      final s = await open(tester, false, fail: false);
      await tester.runAsync(() async {
        await s.edit(0, s.fieldById('sv')!, 150);
      });
      await tester.pump();
      expect(find.text(l10n.errNoResponse), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    });
  });
}
