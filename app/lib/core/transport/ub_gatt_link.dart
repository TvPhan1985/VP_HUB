import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

import 'gatt_link.dart';

void logVph(String msg) => debugPrint('VPHUB $msg');

/// GattLink that, dung universal_ble (BSD-3-Clause)
class UbGattLink implements GattLink {
  static const Duration connectTimeout = Duration(seconds: 10);

  @override
  final String deviceId;
  final String _advName;

  /// UUID characteristic -> UUID dich vu chua no
  final Map<String, String> _svcOf = {};
  final Map<String, List<CharacteristicProperty>> _props = {};
  final List<String> _services = [];
  final List<StreamSubscription> _subs = [];
  final StreamController<void> _lost = StreamController<void>.broadcast();
  final OpQueue _queue = OpQueue();
  StreamSubscription<bool>? _connSub;
  bool _up = false;
  bool _closing = false;
  int _mtu = 0;

  UbGattLink(this.deviceId, {String name = ''}) : _advName = name;

  @override
  String get name => _advName;

  @override
  int get mtu => _up ? _mtu : 0;

  @override
  List<String> get services => List.unmodifiable(_services);

  @override
  Stream<void> get lost => _lost.stream;

  @override
  Future<void> connect() async {
    _closing = false;
    try {
      if (await UniversalBle.isScanning()) await UniversalBle.stopScan();
    } catch (_) {}
    await UniversalBle.connect(deviceId, timeout: connectTimeout);
    _up = true;
    await _connSub?.cancel();
    _connSub = UniversalBle.connectionStream(deviceId).listen((connected) {
      if (!connected && _up) {
        _up = false;
        logVph('Mat ket noi $deviceId');
        if (!_closing && !_lost.isClosed) _lost.add(null);
      }
    });
    if (Platform.isAndroid) {
      try {
        _mtu = await UniversalBle.requestMtu(deviceId, 512);
        logVph('MTU = $_mtu');
      } catch (e) {
        logVph('Xin MTU loi: $e');
      }
    }
    final svcs = await UniversalBle.discoverServices(deviceId);
    _svcOf.clear();
    _props.clear();
    _services.clear();
    for (final s in svcs) {
      final su = s.uuid.toLowerCase();
      _services.add(su);
      for (final c in s.characteristics) {
        final cu = c.uuid.toLowerCase();
        _svcOf[cu] = su;
        _props[cu] = c.properties;
      }
    }
  }

  String _svc(String chr) {
    final s = _svcOf[chr];
    if (s == null) throw StateError('Khong co characteristic $chr');
    return s;
  }

  /// Android chi cho mot yeu cau GATT tai mot thoi diem: thu lai khi bao ban
  Future<T> _retryBusy<T>(Future<T> Function() action) async {
    for (var attempt = 0;; attempt++) {
      try {
        return await action();
      } catch (e) {
        final busy = e.toString().toLowerCase().contains('busy');
        if (!busy || attempt >= 3) rethrow;
        await Future.delayed(Duration(milliseconds: 150 * (attempt + 1)));
      }
    }
  }

  @override
  Future<List<int>> read(String chr) =>
      _queue.run(() => _retryBusy(() => UniversalBle.read(deviceId, _svc(chr), chr)));

  /// Ghi co phan hoi. Goi dai hon MTU-3 thi Android tu gui bang long write
  /// (prepared write) khi kieu ghi la WRITE_TYPE_DEFAULT; plugin khong chan do dai.
  @override
  Future<void> write(String chr, List<int> data) => _queue.run(() => _retryBusy(
      () => UniversalBle.write(deviceId, _svc(chr), chr, Uint8List.fromList(data), withoutResponse: false)));

  @override
  Future<void> subscribe(String chr, void Function(List<int> data) onData) {
    final svc = _svc(chr);
    // Gan noi nhan truoc khi bat notify de khong sot goi dau
    _subs.add(UniversalBle.characteristicValueStream(deviceId, chr).listen(onData));
    final indicateOnly = !(_props[chr]?.contains(CharacteristicProperty.notify) ?? true);
    return _queue.run(() => _retryBusy(() => indicateOnly
        ? UniversalBle.subscribeIndications(deviceId, svc, chr)
        : UniversalBle.subscribeNotifications(deviceId, svc, chr)));
  }

  @override
  Future<void> disconnect() async {
    _closing = true;
    _up = false;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _connSub?.cancel();
    _connSub = null;
    try {
      await UniversalBle.disconnect(deviceId, timeout: const Duration(seconds: 5));
    } catch (e) {
      logVph('Ngat ket noi loi: $e');
    }
  }
}
