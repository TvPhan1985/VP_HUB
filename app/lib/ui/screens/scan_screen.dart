import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/device_session.dart';
import '../../core/known_devices.dart';
import '../../core/schema_cache.dart';
import '../../core/transport/fbp_gatt_link.dart';
import '../../core/transport/transport_registry.dart';
import '../../core/transport/uuids.dart';
import '../../l10n/strings_vi.dart';
import '../device_icon.dart';
import 'about_screen.dart';
import 'demo_screen.dart';
import 'device_screen.dart';

/// Man Quet (SPEC §3): thiet bi da dung + ket qua quet loc theo 3 UUID dich vu
class ScanScreen extends StatefulWidget {
  final KvStore store;
  const ScanScreen({super.key, required this.store});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final KnownDevices _known = KnownDevices(widget.store);
  late final SchemaCache _cache = SchemaCache(widget.store);
  List<ScanResult> _results = [];
  bool _scanning = false;
  bool _adapterOn = true;
  bool _permDenied = false;
  bool _busy = false;
  String? _message;
  StreamSubscription? _adapterSub, _scanSub, _scanningSub;

  @override
  void initState() {
    super.initState();
    _adapterSub = FlutterBluePlus.adapterState.listen((s) {
      if (!mounted) return;
      setState(() => _adapterOn = s != BluetoothAdapterState.off && s != BluetoothAdapterState.unavailable);
    });
    _scanSub = FlutterBluePlus.scanResults.listen((list) {
      if (!mounted) return;
      setState(() {
        _results = list.where((r) => _kindOf(r) != null).toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
      });
    });
    _scanningSub = FlutterBluePlus.isScanning.listen((v) {
      if (mounted) setState(() => _scanning = v);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startup());
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _scanSub?.cancel();
    _scanningSub?.cancel();
    super.dispose();
  }

  static TransportKind? _kindOf(ScanResult r) =>
      kindForServices(r.advertisementData.serviceUuids.map((g) => g.str128));

  static String _nameOf(ScanResult r) {
    final n = r.advertisementData.advName;
    if (n.isNotEmpty) return n;
    return r.device.platformName.isNotEmpty ? r.device.platformName : r.device.remoteId.str;
  }

  Future<void> _startup() async {
    final list = _known.list();
    if (_known.autoConnect && list.isNotEmpty && await _ensurePermissions()) {
      await _openKnown(list.first);
    } else {
      await _scan();
    }
  }

  /// Android 12+: quyen "Thiet bi o gan". Android cu hon: thu vien BLE tu xin quyen vi tri khi quet.
  Future<bool> _ensurePermissions() async {
    final st = await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
    final ok = st.values.every((s) => s.isGranted || s.isLimited);
    if (mounted) setState(() => _permDenied = !ok);
    return ok;
  }

  Future<void> _scan() async {
    if (_scanning || _busy) return;
    if (!await _ensurePermissions()) return;
    setState(() {
      _results = [];
      _message = null;
    });
    try {
      await FlutterBluePlus.startScan(
        withServices: [for (final u in kScanServices) Guid(u)],
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      logVph('Loi quet: $e');
      if (mounted) setState(() => _message = S.scanFailed(e));
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  Future<void> _openKnown(KnownDevice d) =>
      _open(BluetoothDevice.fromId(d.id), d.name, legacyHint: d.legacy, iconHint: d.icon);

  Future<void> _open(BluetoothDevice dev, String name, {bool legacyHint = false, String iconHint = 'generic'}) async {
    if (_busy) return;
    _busy = true;
    await _stopScan();
    if (!mounted) return;
    final session = DeviceSession(
      connector: () => connectTransport(FbpGattLink(dev, name: name), _cache),
      title: name,
    );
    Future<void> remember() async {
      final i = session.info;
      if (i == null) return;
      await _known.remember(KnownDevice(
        id: dev.remoteId.str,
        name: session.displayName,
        model: i.model,
        icon: i.icon,
        legacy: session.transport?.legacy ?? legacyHint,
        lastMs: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    var saved = false;
    void onChange() {
      if (session.ready && !saved) {
        saved = true;
        remember();
      }
    }

    session.addListener(onChange);
    session.connect();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeviceScreen(session: session)));
    session.removeListener(onChange);
    // Luu lai lan nua vi nguoi dung co the da doi ten thiet bi
    if (session.hasEverConnected && session.ready) await remember();
    session.dispose();
    _busy = false;
    if (mounted) {
      setState(() {});
      _scan();
    }
  }

  Widget _tag(BuildContext context, bool legacy) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: legacy ? cs.surfaceContainerHighest : cs.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(legacy ? S.tagLegacy : S.tagVph, style: Theme.of(context).textTheme.labelSmall),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );

  Widget _notice(IconData icon, String text, String button, VoidCallback onTap) => Card(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [Icon(icon), const SizedBox(width: 12), Expanded(child: Text(text))]),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: FilledButton.tonal(onPressed: onTap, child: Text(button))),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final known = _known.list();
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.appName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'demo':
                  await _stopScan();
                  if (!context.mounted) return;
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DemoScreen()));
                case 'auto':
                  await _known.setAutoConnect(!_known.autoConnect);
                  if (mounted) setState(() {});
                case 'about':
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'demo', child: Text(S.menuDemo)),
              CheckedPopupMenuItem(value: 'auto', checked: _known.autoConnect, child: const Text(S.menuAuto)),
              const PopupMenuItem(value: 'about', child: Text(S.menuAbout)),
            ],
          ),
        ],
        bottom: _scanning
            ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator())
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (!_adapterOn)
            _notice(Icons.bluetooth_disabled, S.btOff, S.btTurnOn, () async {
              try {
                await FlutterBluePlus.turnOn();
              } catch (e) {
                logVph('Bat Bluetooth loi: $e');
              }
            }),
          if (_permDenied) _notice(Icons.lock_outline, S.permMissing, S.openSettings, openAppSettings),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (known.isNotEmpty) ...[
            _section(context, S.knownDevices),
            for (final d in known)
              ListTile(
                leading: Icon(deviceIcon(d.icon)),
                title: Text(d.name),
                subtitle: Row(children: [
                  _tag(context, d.legacy),
                  const SizedBox(width: 8),
                  Flexible(child: Text(d.model, overflow: TextOverflow.ellipsis)),
                ]),
                trailing: IconButton(
                  tooltip: S.forget,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _known.forget(d.id);
                    if (mounted) setState(() {});
                  },
                ),
                onTap: () => _openKnown(d),
              ),
          ],
          _section(context, S.nearby),
          if (_results.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_scanning ? S.scanning : S.noDevices, textAlign: TextAlign.center),
            ),
          for (final r in _results)
            ListTile(
              leading: Icon(deviceIcon(iconForKind(_kindOf(r)))),
              title: Text(_nameOf(r)),
              subtitle: Row(children: [
                _tag(context, _kindOf(r) != TransportKind.vph),
                const SizedBox(width: 8),
                Flexible(child: Text('${r.device.remoteId.str}  ${S.rssi(r.rssi)}', overflow: TextOverflow.ellipsis)),
              ]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(r.device, _nameOf(r), legacyHint: _kindOf(r) != TransportKind.vph),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanning ? _stopScan : _scan,
        icon: Icon(_scanning ? Icons.stop : Icons.search),
        label: Text(_scanning ? S.stopScan : S.scan),
      ),
    );
  }
}
