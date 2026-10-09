import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/app_settings.dart';
import '../../core/device_session.dart';
import '../../core/model/vph_value.dart';
import '../../core/transport/vph_transport.dart';
import '../../core/consts.dart';
import '../../l10n/l10n.dart';
import '../app_drawer.dart';
import '../render/batch_bar.dart';
import '../render/flags_field.dart' show activeFlags;
import '../render/header_bar.dart';
import '../render/icons.dart';
import '../render/screen_view.dart';
import '../theme.dart';
import 'about_screen.dart';
import 'info_screen.dart';
import 'settings_screen.dart';

enum _Leave { stay, discard, save }

/// Hoi lai khi roi mot man batch con thay doi chua luu
Future<_Leave> _askLeaveDialog(BuildContext context, DeviceSession s, int screen) async {
  final r = await showDialog<_Leave>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l.unsavedTitle),
      content: Text(context.l.unsavedBody(s.draftCount(screen))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, _Leave.stay), child: Text(context.l.stay)),
        TextButton(onPressed: () => Navigator.pop(ctx, _Leave.discard), child: Text(context.l.discard)),
        FilledButton(onPressed: () => Navigator.pop(ctx, _Leave.save), child: Text(context.l.save)),
      ],
    ),
  );
  return r ?? _Leave.stay;
}

/// Hop hien loi goc (chi Technician)
Future<void> showErrorDetails(BuildContext context, String detail) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l.errorDetails),
        content: SingleChildScrollView(child: SelectableText(detail)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l.close))],
      ),
    );

/// Cac bao dong dang bat cua thiet bi (cho chuong thong bao tren Top App Bar):
/// moi bit cua truong flags, va cac bool co goi y alarm / den warn dang bat
List<String> activeAlarms(AppLocalizations l, DeviceSession s) {
  final out = <String>[];
  final seen = <String>{};
  for (final sc in s.screens) {
    for (final f in sc.fields) {
      if (!seen.add(f.id)) continue;
      final v = s.values[f.id];
      if (f.type == 'flags') {
        if (v != null) out.addAll(activeFlags(l, f, v));
      } else if (f.type == 'bool' && (f.hint('alarm') || (f.hint('warn') && !f.hint('hero'))) && asBool(v) == true) {
        out.add(f.label);
      }
    }
  }
  return out;
}

/// Thanh tab tren (Top Navigation Tabs): cuon ngang, chu in hoa, nam ngay duoi Top App Bar
class TopTabs extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> titles;
  const TopTabs({super.key, required this.controller, required this.titles});

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        width: double.infinity,
        color: VpBars.of(context).tabs,
        child: TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [for (final t in titles) Tab(height: 44, text: t.toUpperCase())],
        ),
      );
}

/// Man hinh Thiet bi: ve hoan toan tu schema, khong biet thiet bi la loai gi.
/// Bo giao dien (cong nghiep / nong nghiep) chon theo khoa `dom` thiet bi khai trong INFO.
class DeviceScreen extends StatelessWidget {
  final DeviceSession session;
  const DeviceScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: session,
        builder: (context, child) => Theme(
          data: vpHubTheme(Theme.of(context).brightness, session.info?.domain ?? 'ind'),
          child: child!,
        ),
        child: _DeviceView(session: session),
      );
}

class _DeviceView extends StatefulWidget {
  final DeviceSession session;
  const _DeviceView({required this.session});

  @override
  State<_DeviceView> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<_DeviceView> with TickerProviderStateMixin {
  TabController? _tabs;

  /// Chi so (trong session.screens) cua cac man lam tab; man nav:"menu" nam trong menu he thong
  List<int> _tabIdx = const [];

  /// Chi so man hinh cua tab dang mo
  int _shown = 0;
  bool _asking = false;

  /// Dang mo mot man cua menu he thong thanh trang rieng
  bool _inMenu = false;
  StreamSubscription<SessionMessage>? _msgSub;

  /// Dang o che do Technician (hien ca man / truong adv)
  bool _tech = false;
  AppSettings? _settings;
  bool _awake = false;

  DeviceSession get s => widget.session;

  @override
  void initState() {
    super.initState();
    _msgSub = s.messages.listen(_onMessage);
    s.addListener(_applyWake);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = SettingsScope.maybeOf(context);
    _tech = _settings?.technician ?? false;
    _applyWake();
  }

  @override
  void dispose() {
    s.removeListener(_applyWake);
    if (_awake) _setWake(false);
    _msgSub?.cancel();
    _tabs?.dispose();
    super.dispose();
  }

  /// Giu man hinh sang khi dang ket noi, neu nguoi dung bat tuy chon nay
  void _applyWake() {
    final want = (_settings?.keepScreenOn ?? false) && s.ready;
    if (want != _awake) _setWake(want);
  }

  void _setWake(bool on) {
    _awake = on;
    WakelockPlus.toggle(enable: on).catchError((_) {});
  }

  void _onMessage(SessionMessage m) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    final l = context.l;
    final err = m.error;
    final text = err != null
        ? errorText(l, err)
        : switch (m.kind!) {
            MsgKind.saved => l.saved,
            MsgKind.interfaceReloaded => l.interfaceReloaded,
            MsgKind.commandSent => l.commandSent(m.label),
            MsgKind.turnedOn => l.turnedOn(m.label),
            MsgKind.turnedOff => l.turnedOff(m.label),
            MsgKind.changedTo => l.changedTo(m.label, m.value),
          };
    // Technician: them nut Details hien loi goc
    final detail = _tech ? err?.shortDetail : null;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text, style: TextStyle(color: m.ok ? Colors.white : cs.onError)),
        backgroundColor: m.ok ? Vp.okSolid : cs.error,
        duration: Duration(seconds: m.ok ? 2 : 5),
        action: detail == null
            ? null
            : SnackBarAction(
                label: l.details, textColor: cs.onError, onPressed: () => showErrorDetails(context, detail)),
      ));
  }

  /// Tao lai TabController khi so man hinh doi (ket noi xong, doc lai schema)
  void _syncTabs() {
    // Man adv chi co o che do Technician
    final all = [for (var i = 0; i < s.screens.length; i++) if (_tech || !s.screens[i].adv) i];
    var idx = [for (final i in all) if (!s.screens[i].menu) i];
    // Moi man deu la menu thi coi tat ca la tab, khong de man Thiet bi trong
    if (idx.isEmpty) idx = all;
    if (_tabs != null && listEquals(idx, _tabIdx)) return;
    _tabs?.dispose();
    _tabs = null;
    _tabIdx = idx;
    if (idx.isEmpty) return;
    _shown = idx.contains(s.current) ? s.current : idx.first;
    _tabs = TabController(length: idx.length, vsync: this, initialIndex: idx.indexOf(_shown))..addListener(_onTab);
    // Man dang chon tren thiet bi khong phai tab (vd man dau la menu): chon lai tab dang hien
    if (_shown != s.current && !_inMenu) Future.microtask(() => s.selectScreen(_shown));
  }

  Future<_Leave> _askLeave(int screen) => _askLeaveDialog(context, s, screen);

  /// Mo mot man nav:"menu" thanh trang rieng; thoat ra thi chon lai tab dang mo
  Future<void> _openMenuScreen(int i) async {
    if (_inMenu || i >= s.screens.length) return;
    if (s.draftCount(_shown) > 0) {
      final r = await _askLeave(_shown);
      if (r == _Leave.stay) return;
      if (r == _Leave.discard) s.discardBatch(_shown);
      if (r == _Leave.save && !await s.saveBatch(_shown)) return;
    }
    if (!mounted) return;
    _inMenu = true;
    final nav = Navigator.of(context);
    // Trang con giu bo giao dien cua thiet bi
    final theme = Theme.of(context);
    unawaited(s.selectScreen(i));
    await nav.push(MaterialPageRoute(
      builder: (_) => Theme(data: theme, child: _MenuScreenPage(session: s, index: i)),
    ));
    _inMenu = false;
    s.discardBatch(i);
    await s.selectScreen(_shown);
  }

  /// Dang co thay doi chua luu ma roi tab thi hoi lai (SPEC §4)
  Future<void> _onTab() async {
    final tabs = _tabs;
    if (tabs == null || tabs.indexIsChanging || _asking || _inMenu) return;
    final to = _tabIdx[tabs.index], from = _shown;
    if (to == from) return;
    if (s.draftCount(from) > 0) {
      _asking = true;
      final r = await _askLeave(from);
      var leave = r == _Leave.discard;
      if (r == _Leave.discard) s.discardBatch(from);
      if (r == _Leave.save) leave = await s.saveBatch(from);
      _asking = false;
      if (!mounted || _tabs != tabs) return;
      if (!leave) {
        tabs.index = _tabIdx.indexOf(from);
        return;
      }
    }
    setState(() => _shown = to);
    await s.selectScreen(to);
  }

  Future<void> _leaveScreen() async {
    final nav = Navigator.of(context);
    if (s.draftCount(_shown) > 0) {
      final r = await _askLeave(_shown);
      if (r == _Leave.stay) return;
      if (r == _Leave.save && !await s.saveBatch(_shown)) return;
    }
    nav.pop();
  }

  /// Dong phu duoi ten thiet bi: chu va mau theo trang thai ket noi (mau tren nen thanh dam)
  (String, Color) _link() => switch (s.status) {
        LinkStatus.ready => (context.l.connected, VpBars.of(context).ok),
        LinkStatus.connecting || LinkStatus.loading => (context.l.connecting, Vp.barCaution),
        LinkStatus.reconnecting => (context.l.reconnecting, Vp.barCaution),
        _ => (context.l.disconnected, Vp.barStop),
      };

  /// Ngat ket noi: lam ngay; con thay doi chua luu thi hoi lai truoc
  Future<void> _disconnect() async {
    final nav = Navigator.of(context);
    if (s.drafts.values.any((d) => d.isNotEmpty)) {
      final ok = await askConfirm(context,
          title: context.l.disconnectTitle(s.displayName), body: context.l.disconnectBody, action: context.l.disconnect, danger: true);
      if (!ok) return;
    }
    s.drafts.clear();
    nav.pop();
  }

  void _showAlarms() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListenableBuilder(
        listenable: s,
        builder: (ctx, _) {
          final cs = Theme.of(ctx).colorScheme;
          final list = activeAlarms(ctx.l, s);
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(context.l.alarmsTitle, style: Theme.of(ctx).textTheme.titleMedium),
                ),
                if (list.isEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.check_circle, color: Vp.ok(cs)),
                    title: Text(context.l.alarmNone),
                  ),
                for (final a in list)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 20, color: cs.onErrorContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(a, style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Menu he thong: thong tin thiet bi + ket noi o tren, roi cac muc dieu huong
  Widget _drawer(BuildContext context, List<int> menuIdx) {
    final link = _link();
    final i = s.info;
    final sub = i == null ? kAppName : '${i.model} · ${context.l.infoFw} ${i.fw}';
    final pageTheme = Theme.of(context);
    final nav = Navigator.of(context);
    // Trang cua thiet bi giu bo giao dien cua thiet bi; trang cua app dung giao dien chung
    void push(Widget page) => nav.push(MaterialPageRoute(builder: (_) => Theme(data: pageTheme, child: page)));
    void pushApp(Widget page) => nav.push(MaterialPageRoute(builder: (_) => page));
    return AppDrawer(
      avatar: Text(AppDrawer.initials(s.displayName)),
      title: s.displayName,
      subtitle: sub,
      status: link.$1,
      statusColor: link.$2,
      sections: [
        DrawerSection('', [
          DrawerEntry(icon: Icons.devices_other, label: context.l.deviceList, onTap: _leaveScreen),
        ]),
        DrawerSection(context.l.secDevice, [
          // Cac man cai dat / thong tin cua thiet bi (nav:"menu")
          for (final m in menuIdx)
            DrawerEntry(
              icon: screenIcon(s.screens[m].icon, m),
              label: s.screens[m].title,
              enabled: s.hasEverConnected,
              onTap: () => _openMenuScreen(m),
            ),
          DrawerEntry(
            icon: Icons.info_outline,
            label: context.l.deviceInfo,
            enabled: s.info != null,
            onTap: () => push(InfoScreen(session: s)),
          ),
          if (_tech) DrawerEntry(icon: Icons.sync, label: context.l.reloadInterface, enabled: s.ready, onTap: s.reloadSchema),
        ]),
        DrawerSection(context.l.secApp, [
          DrawerEntry(icon: Icons.settings_outlined, label: context.l.settings, onTap: () => pushApp(const SettingsScreen())),
          DrawerEntry(icon: Icons.menu_book_outlined, label: context.l.helpAbout, onTap: () => pushApp(const AboutScreen())),
          DrawerEntry(icon: Icons.logout, label: context.l.disconnect, danger: true, onTap: _disconnect),
        ]),
      ],
    );
  }

  Widget _center(List<Widget> children) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      );

  Widget _body(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!s.hasEverConnected) {
      if (s.status == LinkStatus.failed) {
        return _center([
          Icon(Icons.bluetooth_disabled, size: 56, color: cs.error),
          const SizedBox(height: 12),
          Text(context.l.connectFailed, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(s.error == null ? '' : errorText(context.l, s.error!), textAlign: TextAlign.center),
          if (_tech && s.error?.shortDetail != null)
            TextButton(
              onPressed: () => showErrorDetails(context, s.error!.shortDetail!),
              child: Text(context.l.details),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: s.connect, icon: const Icon(Icons.refresh), label: Text(context.l.retry)),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l.back)),
        ]);
      }
      return _center([
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(s.status == LinkStatus.loading ? context.l.loadingDevice : context.l.connecting),
      ]);
    }
    final tabs = _tabs;
    if (tabs == null) return _center([Text(context.l.noScreens)]);
    final lost = s.status != LinkStatus.ready;
    final needUpdate = (s.info?.pv ?? 1) > VphTransport.supportedPv;
    return Column(
      children: [
        if (lost && s.status != LinkStatus.failed) const LinearProgressIndicator(minHeight: 2),
        if (lost)
          MaterialBanner(
            // Dang thu lai: mau canh bao (vang); bo cuoc: mau dung khan (do)
            backgroundColor: s.status == LinkStatus.failed ? cs.errorContainer : cs.tertiaryContainer,
            dividerColor: Colors.transparent,
            leading: s.status == LinkStatus.failed
                ? Icon(Icons.link_off, color: cs.onErrorContainer)
                : SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.onTertiaryContainer),
                  ),
            content: Text(
              s.status == LinkStatus.failed ? context.l.lostGiveUp : context.l.lostRetrying,
              style: TextStyle(
                color: s.status == LinkStatus.failed ? cs.onErrorContainer : cs.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              if (s.status == LinkStatus.failed)
                TextButton(onPressed: s.connect, child: Text(context.l.retry))
              else
                const SizedBox.shrink(),
            ],
          ),
        if (needUpdate)
          MaterialBanner(
            content: Text(context.l.needUpdate),
            leading: const Icon(Icons.system_update),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(
          // Mat ket noi: giu gia tri cu, lam mo va khong cho bam
          child: Opacity(
            opacity: lost ? 0.5 : 1,
            child: IgnorePointer(
              ignoring: lost,
              child: Column(
                children: [
                  HeaderBar(session: s),
                  Expanded(
                    child: TabBarView(
                      controller: tabs,
                      children: [for (final i in _tabIdx) ScreenView(session: s, index: i)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (s.draftCount(_shown) > 0)
          BatchBar(
            count: s.draftCount(_shown),
            saving: s.saving,
            enabled: s.ready,
            onCancel: () => s.discardBatch(_shown),
            onSave: () => s.saveBatch(_shown),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        _syncTabs();
        final tabs = _tabs;
        final link = _link();
        final n = _tabIdx.length;
        final menuIdx = [
          for (var i = 0; i < s.screens.length; i++)
            if (!_tabIdx.contains(i) && (_tech || !s.screens[i].adv)) i,
        ];
        final showTabs = tabs != null && s.hasEverConnected && n >= 2;
        final alarms = s.hasEverConnected ? activeAlarms(context.l, s).length : 0;
        return PopScope(
          canPop: s.draftCount(_shown) == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leaveScreen();
          },
          child: Scaffold(
            drawer: _drawer(context, menuIdx),
            appBar: AppBar(
              leading: const MenuButton(),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.displayName, overflow: TextOverflow.ellipsis),
                  Text(link.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: link.$2)),
                ],
              ),
              actions: [
                // Dang o che do Technician: nhac nguoi dung la co the doi tham so quan trong
                if (_tech)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Vp.barCaution),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(kTechChip,
                        style: TextStyle(color: Vp.barCaution, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                  ),
                // Top Action Item: chuong thong bao kem so bao dong dang bat
                IconButton(
                  tooltip: context.l.alarmsTooltip,
                  onPressed: s.hasEverConnected ? _showAlarms : null,
                  icon: Badge(
                    isLabelVisible: alarms > 0,
                    label: Text('$alarms'),
                    backgroundColor: const Color(0xFFDC2626),
                    textColor: Colors.white,
                    child: Icon(alarms > 0 ? Icons.notifications_active : Icons.notifications_none),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              bottom: !showTabs
                  ? null
                  : TopTabs(controller: tabs, titles: [for (final i in _tabIdx) s.screens[i].title]),
            ),
            // Chua cho cho thanh dieu huong cua Android (man hinh tran vien)
            body: SafeArea(top: false, child: _body(context)),
          ),
        );
      },
    );
  }
}

/// Trang rieng cua mot man nav:"menu" (cai dat, thong tin thiet bi), mo tu menu he thong
class _MenuScreenPage extends StatelessWidget {
  final DeviceSession session;
  final int index;
  const _MenuScreenPage({required this.session, required this.index});

  Future<void> _leave(BuildContext context) async {
    final nav = Navigator.of(context);
    if (session.draftCount(index) > 0) {
      final r = await _askLeaveDialog(context, session, index);
      if (r == _Leave.stay) return;
      if (r == _Leave.discard) session.discardBatch(index);
      if (r == _Leave.save && !await session.saveBatch(index)) return;
    }
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final s = session;
        // Schema vua doc lai va khong con man nay
        if (index >= s.screens.length) return Scaffold(appBar: AppBar());
        final cs = Theme.of(context).colorScheme;
        final lost = !s.ready;
        final failed = s.status == LinkStatus.failed;
        final drafts = s.draftCount(index);
        return PopScope(
          canPop: drafts == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leave(context);
          },
          child: Scaffold(
            appBar: AppBar(titleSpacing: null, title: Text(s.screens[index].title)),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (lost && !failed) const LinearProgressIndicator(minHeight: 2),
                  if (lost)
                    MaterialBanner(
                      backgroundColor: failed ? cs.errorContainer : cs.tertiaryContainer,
                      dividerColor: Colors.transparent,
                      content: Text(
                        failed ? context.l.lostGiveUp : context.l.lostRetrying,
                        style: TextStyle(color: failed ? cs.onErrorContainer : cs.onTertiaryContainer),
                      ),
                      actions: [
                        if (failed) TextButton(onPressed: s.connect, child: Text(context.l.retry)) else const SizedBox.shrink(),
                      ],
                    ),
                  Expanded(
                    child: Opacity(
                      opacity: lost ? 0.5 : 1,
                      child: IgnorePointer(ignoring: lost, child: ScreenView(session: s, index: index)),
                    ),
                  ),
                  if (drafts > 0)
                    BatchBar(
                      count: drafts,
                      saving: s.saving,
                      enabled: s.ready,
                      onCancel: () => s.discardBatch(index),
                      onSave: () => s.saveBatch(index),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
