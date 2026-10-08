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
import '../../l10n/strings.dart';
import '../app_drawer.dart';
import '../device_icon.dart';
import '../theme.dart';
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
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
      );

  /// Menu he thong cua man Quet: trang thai Bluetooth o tren, roi Thiet bi / Cai dat app / Ho tro
  Widget _drawer(BuildContext context) {
    final theme = themeEntry(context), language = languageEntry(context);
    Future<void> push(Widget page) async {
      await _stopScan();
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    return AppDrawer(
      avatar: const Icon(Icons.hub, size: 24),
      title: S.appName,
      subtitle: S.appTagline,
      status: !_adapterOn ? S.btOffShort : (_scanning ? S.scanning : S.btReady),
      statusColor: !_adapterOn ? Vp.barStop : (_scanning ? Vp.barCaution : Vp.barOk),
      sections: [
        DrawerSection(S.secDevices, [
          DrawerEntry(icon: Icons.devices_other, label: S.menuDeviceList, selected: true, onTap: () {}),
          DrawerEntry(icon: Icons.science_outlined, label: S.menuDemo, onTap: () => push(const DemoScreen())),
        ]),
        DrawerSection(S.secApp, [
          ?theme,
          ?language,
          DrawerEntry(
            icon: Icons.bluetooth_connected,
            label: S.menuAuto,
            value: _known.autoConnect ? S.on : S.off,
            keepOpen: true,
            onTap: () async {
              await _known.setAutoConnect(!_known.autoConnect);
              if (mounted) setState(() {});
            },
          ),
        ]),
        DrawerSection(S.secSupport, [
          DrawerEntry(icon: Icons.menu_book_outlined, label: S.menuAbout, onTap: () => push(const AboutScreen())),
        ]),
      ],
    );
  }

  /// Mot thiet bi la mot the: icon, ten, nhan giao thuc, cot song
  Widget _deviceCard(
    BuildContext context, {
    required IconData icon,
    required String name,
    required String detail,
    required bool legacy,
    required VoidCallback onTap,
    required Widget trailing,
    int? rssi,
    bool seen = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(Vp.pad, Vp.gap / 2, Vp.pad, Vp.gap / 2),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              child: Icon(icon),
            ),
            if (seen)
              Positioned(
                right: -1,
                bottom: -1,
                child: Tooltip(
                  message: S.seenNow,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: Vp.ok(cs),
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(children: [
          _tag(context, legacy),
          const SizedBox(width: 8),
          Flexible(child: Text(detail, overflow: TextOverflow.ellipsis)),
        ]),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rssi != null) SignalBars(rssi: rssi),
            trailing,
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 72, 32, 24),
      child: Column(
        children: [
          Icon(Icons.bluetooth_searching, size: 88, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(_scanning ? S.scanning : S.scanEmptyTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(S.scanEmptyHint, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _scanning ? _stopScan : _scan,
            icon: Icon(_scanning ? Icons.stop : Icons.search),
            label: Text(_scanning ? S.stopScan : S.scan),
          ),
        ],
      ),
    );
  }

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
    // Thiet bi da dung ma dang thay quanh day: danh dau tai cho, khong lap lai o muc "gan day"
    final seen = {for (final r in _results) r.device.remoteId.str: r};
    final knownIds = {for (final d in known) d.id};
    final fresh = [for (final r in _results) if (!knownIds.contains(r.device.remoteId.str)) r];
    return Scaffold(
      drawer: _drawer(context),
      appBar: AppBar(
        leading: const MenuButton(),
        title: const Text(S.appName),
        actions: [
          // Top Action Item: quet tim thiet bi
          IconButton(
            tooltip: _scanning ? S.stopScan : S.scan,
            icon: Icon(_scanning ? Icons.stop_circle_outlined : Icons.search),
            onPressed: _scanning ? _stopScan : _scan,
          ),
          const SizedBox(width: 4),
        ],
        bottom: _scanning
            ? const PreferredSize(preferredSize: Size.fromHeight(3), child: LinearProgressIndicator(minHeight: 3))
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
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
              _deviceCard(
                context,
                icon: deviceIcon(d.icon),
                name: d.name,
                detail: d.model,
                legacy: d.legacy,
                rssi: seen[d.id]?.rssi,
                seen: seen.containsKey(d.id),
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
          if (fresh.isNotEmpty || known.isNotEmpty) _section(context, S.nearby),
          if (fresh.isEmpty)
            known.isEmpty
                ? _empty(context)
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_scanning ? S.scanning : S.noDevices, textAlign: TextAlign.center),
                  ),
          for (final r in fresh)
            _deviceCard(
              context,
              icon: deviceIcon(iconForKind(_kindOf(r))),
              name: _nameOf(r),
              detail: r.device.remoteId.str,
              legacy: _kindOf(r) != TransportKind.vph,
              rssi: r.rssi,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(r.device, _nameOf(r), legacyHint: _kindOf(r) != TransportKind.vph),
            ),
        ],
      ),
    );
  }
}

/// Cot song 4 vach theo RSSI (>= -60: 4 vach, >= -70: 3, >= -80: 2, con lai 1)
class SignalBars extends StatelessWidget {
  final int rssi;
  const SignalBars({super.key, required this.rssi});

  static int level(int rssi) => rssi >= -60 ? 4 : (rssi >= -70 ? 3 : (rssi >= -80 ? 2 : 1));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = level(rssi);
    return Tooltip(
      message: S.rssi(rssi),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 4,
                height: 6.0 + i * 4,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: i < n ? cs.primary : cs.outlineVariant,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
