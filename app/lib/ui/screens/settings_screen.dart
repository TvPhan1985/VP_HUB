import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_settings.dart';
import '../../core/diag_log.dart';
import '../../core/schema_cache.dart';
import '../../core/consts.dart';
import '../../l10n/l10n.dart';
import '../theme.dart';
import 'demo_screen.dart';

String themeModeLabel(AppLocalizations l, ThemeMode m) => switch (m) {
      ThemeMode.light => l.themeLight,
      ThemeMode.dark => l.themeDark,
      ThemeMode.system => l.themeSystem,
    };

/// Hop chon mot gia tri trong danh sach (Theme, Language)
Future<T?> _pickOne<T>(BuildContext context, String title, List<T> items, T current, String Function(T) label) =>
    showDialog<T>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          for (final it in items)
            ListTile(
              leading: Icon(
                it == current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: it == current ? Theme.of(ctx).colorScheme.primary : null,
              ),
              title: Text(label(it)),
              onTap: () => Navigator.of(ctx).pop(it),
            ),
        ],
      ),
    );

/// Hop hoi lai truoc mot hanh dong co hau qua: tieu de la cau hoi, nut xac nhan lap lai dong tu.
/// [danger]: nut xac nhan mau do (dung / khoi dong lai / xoa).
Future<bool> askConfirm(
  BuildContext context, {
  required String title,
  String? body,
  required String action,
  bool danger = false,
}) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: body == null ? null : Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l.cancel)),
          FilledButton(
            style: danger ? FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      );
    },
  );
  return yes == true;
}

/// Hop nhap PIN 4 so. [confirm]: bat nhap hai lan (dat PIN moi). [check]: tra chuoi loi neu PIN sai.
Future<String?> askPin(
  BuildContext context, {
  required String title,
  bool confirm = false,
  String? Function(String pin)? check,
  String? action,
}) {
  final a = TextEditingController(), b = TextEditingController();
  String? err;
  InputDecoration deco(String label, String? e) => InputDecoration(labelText: label, errorText: e, counterText: '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        void submit() {
          final pin = a.text;
          String? e;
          if (!AppSettings.validPin(pin)) {
            e = context.l.pinFormat;
          } else if (confirm && b.text != pin) {
            e = context.l.pinMismatch;
          } else {
            e = check?.call(pin);
          }
          if (e != null) {
            setState(() => err = e);
          } else {
            Navigator.pop(ctx, pin);
          }
        }

        TextField field(TextEditingController c, String label, String? e, {bool last = false, bool focus = false}) =>
            TextField(
              controller: c,
              autofocus: focus,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: deco(label, e),
              textInputAction: last ? TextInputAction.done : TextInputAction.next,
              onSubmitted: last ? (_) => submit() : null,
            );

        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(a, confirm ? context.l.newPin : context.l.enterPin, confirm ? null : err, last: !confirm, focus: true),
              if (confirm) ...[const SizedBox(height: 8), field(b, context.l.confirmPin, err, last: true)],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l.cancel)),
            FilledButton(onPressed: submit, child: Text(action ?? context.l.save)),
          ],
        );
      },
    ),
  );
}

/// Man Settings (SPEC §11.51): General / Advanced / Developer tools (chi Technician) / About
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _toast(BuildContext context, String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _toggleTech(BuildContext context, AppSettings st, bool on) async {
    if (!on || !st.hasPin) {
      await st.setTechnician(on);
      return;
    }
    final pin = await askPin(
      context,
      title: context.l.enterPin,
      action: context.l.turnOn,
      check: (p) => p == st.pin ? null : context.l.pinWrong,
    );
    if (pin != null) await st.setTechnician(true, pin: pin);
  }

  Future<void> _setPin(BuildContext context, AppSettings st) async {
    final pin = await askPin(context, title: context.l.setPin, confirm: true);
    if (pin == null) return;
    await st.setPin(pin);
    if (context.mounted) _toast(context, context.l.pinSet);
  }

  Future<void> _removePin(BuildContext context, AppSettings st) async {
    final ok = await askConfirm(context,
        title: context.l.removePinTitle, body: context.l.removePinBody, action: context.l.remove, danger: true);
    if (!ok) return;
    await st.setPin(null);
    if (context.mounted) _toast(context, context.l.pinRemoved);
  }

  /// Chia se file nhat ky chan doan qua hop Share cua Android
  Future<void> _exportLog(BuildContext context) async {
    final log = DiagLog.instance;
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    await log.flush();
    final f = log.file;
    if (log.lines.isEmpty || f == null || !await f.exists()) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.exportLogEmpty)));
      return;
    }
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'text/plain')], subject: DiagLog.fileName));
    } catch (e) {
      logVph('Xuat nhat ky loi: $e');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.errUnknown)));
    }
  }

  Future<void> _clearCache(BuildContext context, KvStore store) async {
    final ok = await askConfirm(context,
        title: context.l.clearCacheTitle, body: context.l.clearCacheBody, action: context.l.clear, danger: true);
    if (!ok) return;
    await SchemaCache(store).clearAll();
    if (context.mounted) _toast(context, context.l.cacheCleared);
  }

  Widget _section(BuildContext context, String title, List<Widget> tiles) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
          child: Text(
            title,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[if (i > 0) const Divider(height: 1), tiles[i]],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.maybeOf(context);
    if (st == null) return Scaffold(appBar: AppBar(title: Text(context.l.settings)));
    final sub = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    Widget value(String s) => Text(s, style: sub);
    void push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(titleSpacing: null, title: Text(context.l.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Vp.pad, 0, Vp.pad, 24),
        children: [
          _section(context, context.l.secGeneral, [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(context.l.theme),
              trailing: value(themeModeLabel(context.l, st.mode)),
              onTap: () async {
                final m = await _pickOne(context, context.l.theme,
                    const [ThemeMode.system, ThemeMode.light, ThemeMode.dark], st.mode, (m) => themeModeLabel(context.l, m));
                if (m != null) await st.setMode(m);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(context.l.language),
              trailing: value(languageName(st.lang)),
              onTap: () async {
                final c = await _pickOne(context, context.l.language, const ['en', 'vi'], st.lang, languageName);
                if (c != null) await st.setLang(c);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.bluetooth_connected),
              title: Text(context.l.autoConnect),
              value: st.autoConnect,
              onChanged: st.setAutoConnect,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.light_mode_outlined),
              title: Text(context.l.keepAwake),
              value: st.keepScreenOn,
              onChanged: st.setKeepScreenOn,
            ),
          ]),
          _section(context, context.l.secAdvanced, [
            SwitchListTile(
              secondary: const Icon(Icons.engineering_outlined),
              title: Text(context.l.techMode),
              subtitle: Text(context.l.techModeSub),
              value: st.technician,
              onChanged: (on) => _toggleTech(context, st, on),
            ),
            if (st.technician)
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: Text(st.hasPin ? context.l.removePin : context.l.setPin),
                subtitle: st.hasPin ? null : Text(context.l.pinSub),
                onTap: () => st.hasPin ? _removePin(context, st) : _setPin(context, st),
              ),
          ]),
          if (st.technician)
            _section(context, context.l.secDeveloper, [
              ListTile(
                leading: const Icon(Icons.science_outlined),
                title: Text(context.l.demoTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => push(const DemoScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(context.l.openJson),
                onTap: () => DemoScreen.pickAndOpen(context),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.tag),
                title: Text(context.l.showAddr),
                value: st.showAddresses,
                onChanged: st.setShowAddresses,
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: Text(context.l.exportLog),
                onTap: () => _exportLog(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: Text(context.l.clearCache),
                onTap: () => _clearCache(context, st.store),
              ),
            ]),
          _section(context, context.l.secAbout, [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.l.versionLabel),
              trailing: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) =>
                    value(snap.hasData ? '${snap.data!.version} (${snap.data!.buildNumber})' : ''),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(context.l.licenses),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(context: context, applicationName: kAppName),
            ),
          ]),
        ],
      ),
    );
  }
}
