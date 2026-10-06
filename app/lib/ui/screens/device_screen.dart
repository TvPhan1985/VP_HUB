import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/device_session.dart';
import '../../core/transport/vph_transport.dart';
import '../../l10n/strings_vi.dart';
import '../render/batch_bar.dart';
import '../render/header_bar.dart';
import '../render/screen_view.dart';
import 'info_screen.dart';

enum _Leave { stay, discard, save }

/// Man hinh Thiet bi: ve hoan toan tu schema, khong biet thiet bi la loai gi
class DeviceScreen extends StatefulWidget {
  final DeviceSession session;
  const DeviceScreen({super.key, required this.session});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> with TickerProviderStateMixin {
  TabController? _tabs;
  int _shown = 0;
  bool _asking = false;
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
        content: Text(m.text, style: TextStyle(color: m.ok ? null : cs.onError)),
        backgroundColor: m.ok ? null : cs.error,
        duration: Duration(seconds: m.ok ? 2 : 5),
      ));
  }

  /// Tao lai TabController khi so man hinh doi (ket noi xong, doc lai schema)
  void _syncTabs() {
    final n = s.screens.length;
    if (_tabs?.length == n) return;
    _tabs?.dispose();
    _tabs = null;
    if (n == 0) return;
    _shown = s.current.clamp(0, n - 1);
    _tabs = TabController(length: n, vsync: this, initialIndex: _shown)..addListener(_onTab);
  }

  Future<_Leave> _askLeave(int screen) async {
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

  /// Dang co thay doi chua luu ma roi tab thi hoi lai (SPEC §4)
  Future<void> _onTab() async {
    final tabs = _tabs;
    if (tabs == null || tabs.indexIsChanging || _asking) return;
    final to = tabs.index, from = _shown;
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
        tabs.index = from;
        return;
      }
    }
    _shown = to;
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

  Color _dotColor(ColorScheme cs) => switch (s.status) {
        LinkStatus.ready => Colors.green,
        LinkStatus.connecting || LinkStatus.loading || LinkStatus.reconnecting => Colors.amber,
        _ => cs.error,
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
                      children: [for (var i = 0; i < s.screens.length; i++) ScreenView(session: s, index: i)],
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
        return PopScope(
          canPop: s.draftCount(_shown) == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leaveScreen();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: _dotColor(cs), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.displayName, overflow: TextOverflow.ellipsis)),
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (v) {
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
                    PopupMenuItem(value: 'info', enabled: s.info != null, child: const Text(S.menuInfo)),
                    PopupMenuItem(value: 'reload', enabled: s.ready, child: const Text(S.menuReload)),
                    const PopupMenuItem(value: 'disconnect', child: Text(S.menuDisconnect)),
                  ],
                ),
              ],
              bottom: tabs == null || !s.hasEverConnected
                  ? null
                  : TabBar(
                      controller: tabs,
                      isScrollable: s.screens.length > 3,
                      tabAlignment: s.screens.length > 3 ? TabAlignment.start : TabAlignment.fill,
                      tabs: [for (final sc in s.screens) Tab(text: sc.title)],
                    ),
            ),
            body: _body(context),
          ),
        );
      },
    );
  }
}
