import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../core/device_session.dart';
import '../../core/transport/vph_transport.dart';
import '../../l10n/strings_vi.dart';
import '../render/batch_bar.dart';
import '../render/header_bar.dart';
import '../render/icons.dart';
import '../render/screen_view.dart';
import '../theme.dart';
import 'info_screen.dart';

enum _Leave { stay, discard, save }

/// Hoi lai khi roi mot man batch con thay doi chua luu
Future<_Leave> _askLeaveDialog(BuildContext context, DeviceSession s, int screen) async {
  final r = await showDialog<_Leave>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(S.unsavedTitle),
      content: Text(S.unsavedBody(s.draftCount(screen))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, _Leave.stay), child: const Text(S.stay)),
        TextButton(onPressed: () => Navigator.pop(ctx, _Leave.discard), child: const Text(S.discard)),
        FilledButton(onPressed: () => Navigator.pop(ctx, _Leave.save), child: const Text(S.save)),
      ],
    ),
  );
  return r ?? _Leave.stay;
}

/// Man hinh Thiet bi: ve hoan toan tu schema, khong biet thiet bi la loai gi
class DeviceScreen extends StatefulWidget {
  final DeviceSession session;
  const DeviceScreen({super.key, required this.session});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> with TickerProviderStateMixin {
  TabController? _tabs;

  /// Chi so (trong session.screens) cua cac man lam tab; man nav:"menu" nam trong menu ⋮
  List<int> _tabIdx = const [];

  /// Chi so man hinh cua tab dang mo
  int _shown = 0;
  bool _asking = false;

  /// Dang mo mot man cua menu ⋮ thanh trang rieng
  bool _inMenu = false;
  StreamSubscription<SessionMessage>? _msgSub;

  DeviceSession get s => widget.session;

  @override
  void initState() {
    super.initState();
    _msgSub = s.messages.listen(_onMessage);
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _tabs?.dispose();
    super.dispose();
  }

  void _onMessage(SessionMessage m) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(m.text, style: TextStyle(color: m.ok ? Colors.white : cs.onError)),
        backgroundColor: m.ok ? Vp.okSolid : cs.error,
        duration: Duration(seconds: m.ok ? 2 : 5),
      ));
  }

  /// Tao lai TabController khi so man hinh doi (ket noi xong, doc lai schema)
  void _syncTabs() {
    final all = [for (var i = 0; i < s.screens.length; i++) i];
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
    unawaited(s.selectScreen(i));
    await nav.push(MaterialPageRoute(builder: (_) => _MenuScreenPage(session: s, index: i)));
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

  /// Dong phu duoi ten thiet bi: chu va mau theo trang thai ket noi
  (String, Color) _link(ColorScheme cs) => switch (s.status) {
        LinkStatus.ready => (S.linkOk, Vp.ok(cs)),
        LinkStatus.connecting || LinkStatus.loading => (S.connecting, Vp.busy(cs)),
        LinkStatus.reconnecting => (S.linkRetry, Vp.busy(cs)),
        _ => (S.linkLost, Vp.warn(cs)),
      };

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
          Text(S.connectFailed, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(s.error ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: s.connect, icon: const Icon(Icons.refresh), label: const Text(S.retry)),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(S.back)),
        ]);
      }
      return _center([
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(s.status == LinkStatus.loading ? S.loadingSchema : S.connecting),
      ]);
    }
    final tabs = _tabs;
    if (tabs == null) return _center([const Text(S.noScreens)]);
    final lost = s.status != LinkStatus.ready;
    final needUpdate = (s.info?.pv ?? 1) > VphTransport.supportedPv;
    return Column(
      children: [
        if (lost && s.status != LinkStatus.failed) const LinearProgressIndicator(minHeight: 2),
        if (lost)
          MaterialBanner(
            backgroundColor: cs.errorContainer,
            leading: s.status == LinkStatus.failed
                ? Icon(Icons.link_off, color: cs.onErrorContainer)
                : const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            content: Text(
              s.status == LinkStatus.failed ? S.lostGiveUp : S.lostRetrying,
              style: TextStyle(color: cs.onErrorContainer),
            ),
            actions: [
              if (s.status == LinkStatus.failed)
                TextButton(onPressed: s.connect, child: const Text(S.retry))
              else
                const SizedBox.shrink(),
            ],
          ),
        if (needUpdate)
          MaterialBanner(
            content: const Text(S.needUpdate),
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
        final cs = Theme.of(context).colorScheme;
        final tabs = _tabs;
        final link = _link(cs);
        final n = _tabIdx.length;
        final menuIdx = [for (var i = 0; i < s.screens.length; i++) if (!_tabIdx.contains(i)) i];
        // Thanh tab nam o tren, moi tab co icon + chu; tu 4 man tro len thi cuon ngang
        final showTabs = tabs != null && s.hasEverConnected && n >= 2;
        return PopScope(
          canPop: s.draftCount(_shown) == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leaveScreen();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.displayName, overflow: TextOverflow.ellipsis),
                  Text(link.$1, style: TextStyle(fontSize: 12, color: link.$2)),
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v.startsWith('scr:')) {
                      _openMenuScreen(int.parse(v.substring(4)));
                      return;
                    }
                    switch (v) {
                      case 'info':
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => InfoScreen(session: s)));
                      case 'reload':
                        s.reloadSchema();
                      case 'disconnect':
                        s.drafts.clear();
                        Navigator.of(context).pop();
                    }
                  },
                  itemBuilder: (_) => [
                    // Cac man cai dat / thong tin cua thiet bi (nav:"menu")
                    for (final i in menuIdx)
                      PopupMenuItem(
                        value: 'scr:$i',
                        enabled: s.hasEverConnected,
                        child: Row(children: [
                          Icon(screenIcon(s.screens[i].icon, i), size: 20),
                          const SizedBox(width: 12),
                          Flexible(child: Text(s.screens[i].title)),
                        ]),
                      ),
                    if (menuIdx.isNotEmpty) const PopupMenuDivider(),
                    PopupMenuItem(value: 'info', enabled: s.info != null, child: const Text(S.menuInfo)),
                    PopupMenuItem(value: 'reload', enabled: s.ready, child: const Text(S.menuReload)),
                    const PopupMenuItem(value: 'disconnect', child: Text(S.menuDisconnect)),
                  ],
                ),
              ],
              bottom: !showTabs
                  ? null
                  : TabBar(
                      controller: tabs,
                      isScrollable: n > 3,
                      tabAlignment: n > 3 ? TabAlignment.start : TabAlignment.fill,
                      tabs: [
                        for (final i in _tabIdx)
                          Tab(
                            icon: Icon(screenIcon(s.screens[i].icon, i)),
                            text: s.screens[i].title,
                            iconMargin: const EdgeInsets.only(bottom: 4),
                          ),
                      ],
                    ),
            ),
            // Chua cho cho thanh dieu huong cua Android (man hinh tran vien)
            body: SafeArea(top: false, child: _body(context)),
          ),
        );
      },
    );
  }
}

/// Trang rieng cua mot man nav:"menu" (cai dat, thong tin thiet bi), mo tu menu ⋮
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
            appBar: AppBar(title: Text(s.screens[index].title)),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (lost && !failed) const LinearProgressIndicator(minHeight: 2),
                  if (lost)
                    MaterialBanner(
                      backgroundColor: cs.errorContainer,
                      content: Text(
                        failed ? S.lostGiveUp : S.lostRetrying,
                        style: TextStyle(color: cs.onErrorContainer),
                      ),
                      actions: [
                        if (failed) TextButton(onPressed: s.connect, child: const Text(S.retry)) else const SizedBox.shrink(),
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
