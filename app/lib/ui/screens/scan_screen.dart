import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_settings.dart';
import '../../core/device_session.dart';
import '../../core/known_devices.dart';
import '../../core/schema_cache.dart';
import '../../core/transport/ble_scanner.dart';
import '../../core/transport/gatt_link.dart';
import '../../core/transport/transport_registry.dart';
import '../../core/transport/ub_gatt_link.dart' show logVph;
import '../../core/consts.dart';
import '../../l10n/l10n.dart';
import '../app_drawer.dart';
import '../device_icon.dart';
import '../theme.dart';
import 'about_screen.dart';
import 'device_screen.dart';
import 'settings_screen.dart';

/// Man Quet (SPEC §3): thiet bi da dung + ket qua quet loc theo 3 UUID dich vu
class ScanScreen extends StatefulWidget {
  final KvStore store;

  /// Bo quet; null = bo quet BLE that (test truyen bo quet gia)
  final DeviceScanner? scanner;
  const ScanScreen({super.key, required this.store, this.scanner});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final KnownDevices _known = KnownDevices(widget.store);
  late final SchemaCache _cache = SchemaCache(widget.store);
  late final DeviceScanner _scanner = widget.scanner ?? UbScanner();
  bool _permDenied = false;
  bool _locationOff = false;
  bool _busy = false;
  String? _message;

  /// Thiet bi da nho dang cho thay trong luc quet luc mo app (tu ket noi)
  String? _autoId;
  Timer? _autoTimer;

  /// Mo app: chi tu ket noi neu thay thiet bi trong khoang nay
  static const Duration autoWindow = Duration(seconds: 4);

  bool get _scanning => _scanner.scanning;
  bool get _adapterOn => _scanner.adapterOn;

  @override
  void initState() {
    super.initState();
    _scanner.addListener(_onScanner);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startup());
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _scanner.removeListener(_onScanner);
    if (widget.scanner == null) _scanner.dispose();
    super.dispose();
  }

  void _onScanner() {
    if (!mounted) return;
    setState(() {});
    // Thay thiet bi da nho gan nhat trong 4 giay dau -> tu ket noi
    final id = _autoId;
    if (id != null && !_busy && _scanner.hits.any((h) => h.id == id)) {
      final d = _known.list().where((e) => e.id == id).firstOrNull;
      _cancelAuto();
      if (d != null) _openKnown(d);
    }
  }

  void _cancelAuto() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _autoId = null;
  }

  /// Mo app: quet 10 s. Trong 4 s dau, thay thiet bi da nho gan nhat (theo lastMs) thi tu ket noi;
  /// khong thay thi o lai man Quet va quet tiep cho het 10 s. Khong nhay thang vao thiet bi cu.
  Future<void> _startup() async {
    final list = _known.list();
    final auto = SettingsScope.maybeOf(context)?.autoConnect ?? true;
    if (auto && list.isNotEmpty) {
      final last = list.reduce((a, b) => b.lastMs > a.lastMs ? b : a);
      _autoId = last.id;
      _autoTimer = Timer(autoWindow, _cancelAuto);
    }
    await _scan();
    if (!_scanning) _cancelAuto();
  }

  Future<bool> _ensurePermissions() async {
    final ok = await _scanner.ensurePermissions();
    if (mounted) setState(() => _permDenied = !ok);
    return ok;
  }

  Future<void> _scan() async {
    if (_scanning || _busy) return;
    if (!await _ensurePermissions()) return;
    // Android 6-11: cong tac Location tat thi quet khong thay gi
    final locOff = await _scanner.locationOff();
    if (!mounted) return;
    setState(() {
      _message = null;
      _locationOff = locOff;
    });
    try {
      await _scanner.start();
    } catch (e) {
      logVph('Loi quet: $e');
      if (mounted) setState(() => _message = context.l.errScan);
    }
  }

  /// Keo xuong de quet lai
  Future<void> _refresh() async {
    await _stopScan();
    await _scan();
  }

  Future<void> _stopScan() => _scanner.stop();

  Future<void> _openKnown(KnownDevice d) => _open(d.id, d.name, legacyHint: d.legacy);

  Future<void> _open(String id, String name, {bool legacyHint = false}) async {
    if (_busy) return;
    _busy = true;
    _cancelAuto();
    try {
      await _stopScan();
      if (!mounted) return;
      await _session(id, name, legacyHint: legacyHint);
    } finally {
      // Du co loi giua chung, man Quet van bam duoc tiep
      _busy = false;
    }
    if (mounted) {
      setState(() {});
      _scan();
    }
  }

  /// Mo man Thiet bi cho mot phien ket noi; tra ve khi nguoi dung quay lai man Quet
  Future<void> _session(String id, String name, {bool legacyHint = false}) async {
    GattLink? link;
    // Chu cua schema luu san (relay C3, lo nung) lay theo ngon ngu luc ket noi
    final lang = context.l.localeName;
    final session = DeviceSession(
      connector: () => connectTransport(link = _scanner.link(id, name), _cache, lang: lang),
      title: name,
      deviceId: id,
      rssiReader: () async => link?.readRssi(),
    );
    Future<void> remember() async {
      final i = session.info;
      if (i == null) return;
      // Ten nguoi dung dat trong app (Rename) khong bi ghi de bang ten quang ba
      final old = _known.list().where((e) => e.id == id).firstOrNull;
      final alias = old?.alias ?? false;
      await _known.remember(
        KnownDevice(
          id: id,
          name: alias ? old!.name : session.displayName,
          alias: alias,
          model: i.model,
          icon: i.icon,
          legacy: session.transport?.legacy ?? legacyHint,
          lastMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
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
  }

  /// Menu cua the thiet bi da nho (nhan giu, hoac nut ba cham): Rename / Remove
  Future<void> _deviceMenu(KnownDevice d) async {
    final act = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(ctx.l.rename),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(ctx.l.remove),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (act == 'rename') await _rename(d);
    if (act == 'remove') await _remove(d);
  }

  /// Doi ten hien thi trong app (khong doi ten quang ba cua thiet bi)
  Future<void> _rename(KnownDevice d) async {
    final ctl = TextEditingController(text: d.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l.renameDevice),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(labelText: ctx.l.deviceNameLabel, helperText: ctx.l.renameDeviceHint),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctl.text), child: Text(ctx.l.save)),
        ],
      ),
    );
    final n = name?.trim() ?? '';
    if (n.isEmpty || n == d.name) return;
    await _known.rename(d.id, n);
    if (mounted) setState(() {});
  }

  /// Xoa thiet bi khoi danh sach, cho hoan tac trong SnackBar
  Future<void> _remove(KnownDevice d) async {
    final index = _known.list().indexWhere((e) => e.id == d.id);
    await _known.forget(d.id);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l.deviceRemoved),
          action: SnackBarAction(
            label: context.l.undo,
            onPressed: () async {
              await _known.insertAt(index, d);
              if (mounted) setState(() {});
            },
          ),
        ),
      );
  }

  Widget _tag(BuildContext context, bool legacy) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: legacy ? cs.surfaceContainerHighest : cs.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(legacy ? context.l.tagLegacy : kTagVph, style: Theme.of(context).textTheme.labelSmall),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
    ),
  );

  /// Menu he thong cua man Quet: chi con dieu huong (Devices, Settings, Help & about)
  Widget _drawer(BuildContext context) {
    Future<void> push(Widget page) async {
      await _stopScan();
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    return AppDrawer(
      avatar: const Icon(Icons.hub, size: 24),
      title: kAppName,
      subtitle: context.l.appTagline,
      status: !_adapterOn ? context.l.btOffShort : (_scanning ? context.l.scanning : context.l.btOn),
      statusColor: !_adapterOn ? Vp.barStop : (_scanning ? Vp.barCaution : Vp.barOk),
      sections: [
        DrawerSection('', [
          DrawerEntry(icon: Icons.devices_other, label: context.l.deviceList, selected: true, onTap: () {}),
          DrawerEntry(
            icon: Icons.settings_outlined,
            label: context.l.settings,
            onTap: () => push(const SettingsScreen()),
          ),
          DrawerEntry(
            icon: Icons.menu_book_outlined,
            label: context.l.helpAbout,
            onTap: () => push(const AboutScreen()),
          ),
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
    required bool tech,
    required VoidCallback onTap,
    required Widget trailing,
    VoidCallback? onLongPress,
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
                  message: context.l.inRange,
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
        // Standard: chi ten va model. Technician: them nhan giao thuc, dia chi, so dBm.
        subtitle: !tech
            ? (detail.isEmpty ? null : Text(detail, overflow: TextOverflow.ellipsis))
            : Row(
                children: [
                  _tag(context, legacy),
                  const SizedBox(width: 8),
                  Flexible(child: Text(detail, overflow: TextOverflow.ellipsis)),
                ],
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rssi != null && tech) Text(context.l.rssiDbm(rssi), style: Theme.of(context).textTheme.labelSmall),
            if (rssi != null) SignalBars(rssi: rssi),
            trailing,
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
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
          Text(_scanning ? context.l.scanning : context.l.scanEmptyTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(context.l.scanEmptyHint, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _scanning ? _stopScan : _scan,
            icon: Icon(_scanning ? Icons.stop : Icons.search),
            label: Text(_scanning ? context.l.stopScan : context.l.scanAgain),
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
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(onPressed: onTap, child: Text(button)),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final known = _known.list();
    final st = SettingsScope.maybeOf(context);
    final tech = st?.technician ?? false;
    final addr = tech && (st?.showAddresses ?? true);
    String detail(String model, String id) => [if (model.isNotEmpty) model, if (addr) id].join(' · ');
    // Thiet bi da dung ma dang thay quanh day: danh dau tai cho, khong lap lai o muc "gan day"
    final hits = _scanner.hits;
    final seen = {for (final r in hits) r.id: r};
    final knownIds = {for (final d in known) d.id};
    final fresh = [
      for (final r in hits)
        if (!knownIds.contains(r.id)) r,
    ];
    return Scaffold(
      drawer: _drawer(context),
      appBar: AppBar(
        leading: const MenuButton(),
        title: const Text(kAppName),
        actions: [
          // Top Action Item: quet tim thiet bi
          IconButton(
            tooltip: _scanning ? context.l.stopScan : context.l.scan,
            icon: Icon(_scanning ? Icons.stop_circle_outlined : Icons.search),
            onPressed: _scanning ? _stopScan : _scan,
          ),
          const SizedBox(width: 4),
        ],
        bottom: _scanning
            ? const PreferredSize(preferredSize: Size.fromHeight(3), child: LinearProgressIndicator(minHeight: 3))
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (!_adapterOn)
              _notice(Icons.bluetooth_disabled, context.l.btOff, context.l.btTurnOn, _scanner.turnOnBluetooth),
            if (_permDenied)
              _notice(Icons.lock_outline, context.l.permMissing, context.l.openSettings, openAppSettings),
            if (_locationOff)
              _notice(
                Icons.location_off_outlined,
                context.l.locationOff,
                context.l.openLocationSettings,
                _scanner.openLocationSettings,
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (known.isNotEmpty) ...[
              _section(context, context.l.myDevices),
              for (final d in known)
                _deviceCard(
                  context,
                  icon: deviceIcon(d.icon),
                  name: d.name,
                  detail: detail(d.model, d.id),
                  legacy: d.legacy,
                  tech: tech,
                  rssi: seen[d.id]?.rssi,
                  seen: seen.containsKey(d.id),
                  trailing: IconButton(
                    tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _deviceMenu(d),
                  ),
                  onLongPress: () => _deviceMenu(d),
                  onTap: () => _openKnown(d),
                ),
            ],
            if (fresh.isNotEmpty || known.isNotEmpty) _section(context, context.l.nearby),
            if (fresh.isEmpty)
              known.isEmpty
                  ? _empty(context)
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_scanning ? context.l.scanning : context.l.noNewDevices, textAlign: TextAlign.center),
                    ),
            for (final r in fresh)
              _deviceCard(
                context,
                icon: deviceIcon(iconForKind(r.kind)),
                name: r.name,
                detail: detail('', r.id),
                legacy: r.kind != TransportKind.vph,
                tech: tech,
                rssi: r.rssi,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(r.id, r.name, legacyHint: r.kind != TransportKind.vph),
              ),
          ],
        ),
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
      message: context.l.rssiDbm(rssi),
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
