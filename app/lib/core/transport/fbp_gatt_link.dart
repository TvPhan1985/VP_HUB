import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'gatt_link.dart';

void logVph(String msg) => debugPrint('VPHUB $msg');

/// GattLink that, dung flutter_blue_plus
class FbpGattLink implements GattLink {
  final BluetoothDevice device;
  final String _advName;
  final Map<String, BluetoothCharacteristic> _chars = {};
  final List<String> _services = [];
  final List<StreamSubscription> _subs = [];
  final StreamController<void> _lost = StreamController<void>.broadcast();
  final OpQueue _queue = OpQueue();
  StreamSubscription<BluetoothConnectionState>? _connSub;
  bool _up = false;
  bool _closing = false;

  FbpGattLink(this.device, {String name = ''}) : _advName = name;

  @override
  String get deviceId => device.remoteId.str;

  @override
  String get name => _advName.isNotEmpty ? _advName : device.platformName;

  @override
  int get mtu => _up ? device.mtuNow : 0;

  @override
  List<String> get services => List.unmodifiable(_services);

  @override
  Stream<void> get lost => _lost.stream;

  @override
  Future<void> connect() async {
    _closing = false;
    if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
    await device.connect(license: License.nonprofit, timeout: const Duration(seconds: 15), mtu: null);
    _up = true;
    await _connSub?.cancel();
    _connSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected && _up) {
        _up = false;
        logVph('Mat ket noi $deviceId');
        if (!_closing && !_lost.isClosed) _lost.add(null);
      }
    });
    if (Platform.isAndroid) {
      try {
        final m = await device.requestMtu(512);
        logVph('MTU = $m');
      } catch (e) {
        logVph('Xin MTU loi: $e');
      }
    }
    final svcs = await device.discoverServices();
    _chars.clear();
    _services.clear();
    for (final s in svcs) {
      _services.add(s.uuid.str128.toLowerCase());
      for (final c in s.characteristics) {
        _chars[c.uuid.str128.toLowerCase()] = c;
      }
    }
  }

  BluetoothCharacteristic _chr(String uuid) {
    final c = _chars[uuid];
    if (c == null) throw StateError('Khong co characteristic $uuid');
    return c;
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
  Future<List<int>> read(String chr) => _queue.run(() => _retryBusy(() => _chr(chr).read()));

  @override
  Future<void> write(String chr, List<int> data) => _queue.run(() => _retryBusy(
      () => _chr(chr).write(data, withoutResponse: false, allowLongWrite: data.length > device.mtuNow - 3)));

  @override
  Future<void> subscribe(String chr, void Function(List<int> data) onData) {
    final c = _chr(chr);
    final sub = c.onValueReceived.listen(onData);
    _subs.add(sub);
    device.cancelWhenDisconnected(sub);
    return _queue.run(() => _retryBusy(() => c.setNotifyValue(true)));
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
      await device.disconnect();
    } catch (e) {
      logVph('Ngat ket noi loi: $e');
    }
  }
}
