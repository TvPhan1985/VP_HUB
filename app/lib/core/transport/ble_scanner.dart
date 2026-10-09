import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:universal_ble/universal_ble.dart';

import 'gatt_link.dart';
import 'transport_registry.dart';
import 'ub_gatt_link.dart';
import 'uuids.dart';

/// Mot thiet bi thay duoc khi quet
class ScanHit {
  final String id;
  final String name;
  final int rssi;
  final TransportKind kind;
  const ScanHit({required this.id, required this.name, required this.rssi, required this.kind});
}

/// Lop quet thiet bi. Man Quet chi lam viec voi lop nay nen test duoc bang bo quet gia.
abstract class DeviceScanner extends ChangeNotifier {
  bool get scanning;

  /// Bluetooth cua may dang bat
  bool get adapterOn;

  /// Ket qua quet, song manh dung truoc
  List<ScanHit> get hits;

  /// Xin quyen Bluetooth (va vi tri tren Android 11 tro xuong). false = bi tu choi.
  Future<bool> ensurePermissions();

  /// Quet theo 3 UUID dich vu, tu dung sau [timeout]. Nem loi neu khong quet duoc.
  Future<void> start({Duration timeout = const Duration(seconds: 10)});

  Future<void> stop();

  Future<void> turnOnBluetooth();

  /// true khi may la Android 6-11 va cong tac Location dang tat: quet BLE se khong thay gi
  Future<bool> locationOff();

  Future<void> openLocationSettings();

  /// Duong truyen GATT toi mot thiet bi (chua ket noi)
  GattLink link(String id, String name);
}

/// Xin quyen Bluetooth (Android 12+: Nearby devices; Android 11 tro xuong: vi tri). false = bi tu choi.
Future<bool> requestBlePermissions() async {
  try {
    await UniversalBle.requestPermissions();
    return true;
  } catch (e) {
    logVph('Thieu quyen Bluetooth: $e');
    return false;
  }
}

/// Bo quet that, dung universal_ble
class UbScanner extends DeviceScanner {
  static const MethodChannel _sys = MethodChannel('vn.phan.vphub/sys');

  final Map<String, ScanHit> _hits = {};
  StreamSubscription? _scanSub, _availSub;
  Timer? _timer;
  bool _scanning = false;
  bool _adapterOn = true;

  UbScanner() {
    _scanSub = UniversalBle.scanStream.listen(_onDevice);
    _availSub = UniversalBle.availabilityStream.listen(_onAvailability);
    UniversalBle.getBluetoothAvailabilityState().then(_onAvailability, onError: (_) {});
  }

  @override
  bool get scanning => _scanning;

  @override
  bool get adapterOn => _adapterOn;

  @override
  List<ScanHit> get hits => _hits.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));

  void _onAvailability(AvailabilityState s) {
    final on = s != AvailabilityState.poweredOff && s != AvailabilityState.unsupported;
    if (on == _adapterOn) return;
    _adapterOn = on;
    if (!on) _setScanning(false);
    notifyListeners();
  }

  void _onDevice(BleDevice d) {
    if (!_scanning) return;
    final kind = kindForServices(d.services);
    if (kind == null) return;
    final name = d.name;
    _hits[d.deviceId] = ScanHit(
      id: d.deviceId,
      // Goi quang ba sau co the khong kem ten: giu ten da biet
      name: name != null && name.isNotEmpty ? name : (_hits[d.deviceId]?.name ?? d.deviceId),
      rssi: d.rssi ?? _hits[d.deviceId]?.rssi ?? -100,
      kind: kind,
    );
    notifyListeners();
  }

  void _setScanning(bool v) {
    if (!v) {
      _timer?.cancel();
      _timer = null;
    }
    _scanning = v;
  }

  @override
  Future<bool> ensurePermissions() => requestBlePermissions();

  @override
  Future<bool> locationOff() async {
    try {
      final sdk = await _sys.invokeMethod<int>('sdkInt') ?? 99;
      // Android 12+ khai neverForLocation nen khong can Location
      if (sdk >= 31) return false;
      return !(await _sys.invokeMethod<bool>('locationEnabled') ?? true);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openLocationSettings() async {
    try {
      await _sys.invokeMethod<void>('openLocationSettings');
    } catch (e) {
      logVph('Mo cai dat vi tri loi: $e');
    }
  }

  @override
  Future<void> start({Duration timeout = const Duration(seconds: 10)}) async {
    if (_scanning) await stop();
    _hits.clear();
    _setScanning(true);
    notifyListeners();
    try {
      await UniversalBle.startScan(scanFilter: ScanFilter(withServices: kScanServices));
      _timer = Timer(timeout, stop);
    } catch (e) {
      _setScanning(false);
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    if (!_scanning) return;
    _setScanning(false);
    notifyListeners();
    try {
      await UniversalBle.stopScan();
    } catch (_) {}
  }

  @override
  Future<void> turnOnBluetooth() async {
    try {
      await UniversalBle.enableBluetooth();
    } catch (e) {
      logVph('Bat Bluetooth loi: $e');
    }
  }

  @override
  GattLink link(String id, String name) => UbGattLink(id, name: name);

  @override
  void dispose() {
    _timer?.cancel();
    _scanSub?.cancel();
    _availSub?.cancel();
    super.dispose();
  }
}
