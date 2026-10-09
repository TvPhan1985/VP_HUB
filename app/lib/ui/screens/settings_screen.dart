import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/app_settings.dart';
import '../../core/schema_cache.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import 'demo_screen.dart';

String themeModeLabel(ThemeMode m) => switch (m) {
      ThemeMode.light => S.themeLight,
      ThemeMode.dark => S.themeDark,
      ThemeMode.system => S.themeSystem,
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
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
            e = S.pinFormat;
          } else if (confirm && b.text != pin) {
            e = S.pinMismatch;
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
              field(a, confirm ? S.newPin : S.enterPin, confirm ? null : err, last: !confirm, focus: true),
              if (confirm) ...[const SizedBox(height: 8), field(b, S.confirmPin, err, last: true)],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.cancel)),
            FilledButton(onPressed: submit, child: Text(action ?? S.save)),
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
      title: S.enterPin,
      action: S.turnOn,
      check: (p) => p == st.pin ? null : S.pinWrong,
    );
    if (pin != null) await st.setTechnician(true, pin: pin);
  }

  Future<void> _setPin(BuildContext context, AppSettings st) async {
    final pin = await askPin(context, title: S.setPin, confirm: true);
    if (pin == null) return;
    await st.setPin(pin);
    if (context.mounted) _toast(context, S.pinSet);
  }

  Future<void> _removePin(BuildContext context, AppSettings st) async {
    final ok = await askConfirm(context,
        title: S.removePinTitle, body: S.removePinBody, action: S.remove, danger: true);
    if (!ok) return;
    await st.setPin(null);
    if (context.mounted) _toast(context, S.pinRemoved);
  }

  Future<void> _clearCache(BuildContext context, KvStore store) async {
    final ok = await askConfirm(context,
        title: S.clearCacheTitle, body: S.clearCacheBody, action: S.clear, danger: true);
    if (!ok) return;
    await SchemaCache(store).clearAll();
    if (context.mounted) _toast(context, S.cacheCleared);
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
    if (st == null) return Scaffold(appBar: AppBar(title: Text(S.settings)));
    final sub = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    Widget value(String s) => Text(s, style: sub);
    void push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(titleSpacing: null, title: Text(S.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Vp.pad, 0, Vp.pad, 24),
        children: [
          _section(context, S.secGeneral, [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(S.theme),
              trailing: value(themeModeLabel(st.mode)),
              onTap: () async {
                final m = await _pickOne(context, S.theme,
                    const [ThemeMode.system, ThemeMode.light, ThemeMode.dark], st.mode, themeModeLabel);
                if (m != null) await st.setMode(m);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(S.language),
              trailing: value(Lang.nameOf(st.lang)),
              onTap: () async {
                final c = await _pickOne(context, S.language, const [Lang.en, Lang.vi], st.lang, Lang.nameOf);
                if (c != null) await st.setLang(c);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.bluetooth_connected),
              title: Text(S.autoConnect),
              value: st.autoConnect,
              onChanged: st.setAutoConnect,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.light_mode_outlined),
              title: Text(S.keepAwake),
              value: st.keepScreenOn,
              onChanged: st.setKeepScreenOn,
            ),
          ]),
          _section(context, S.secAdvanced, [
            SwitchListTile(
              secondary: const Icon(Icons.engineering_outlined),
              title: Text(S.techMode),
              subtitle: Text(S.techModeSub),
              value: st.technician,
              onChanged: (on) => _toggleTech(context, st, on),
            ),
            if (st.technician)
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: Text(st.hasPin ? S.removePin : S.setPin),
                subtitle: st.hasPin ? null : Text(S.pinSub),
                onTap: () => st.hasPin ? _removePin(context, st) : _setPin(context, st),
              ),
          ]),
          if (st.technician)
            _section(context, S.secDeveloper, [
              ListTile(
                leading: const Icon(Icons.science_outlined),
                title: Text(S.demoTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => push(const DemoScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(S.openJson),
                onTap: () => DemoScreen.pickAndOpen(context),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.tag),
                title: Text(S.showAddr),
                value: st.showAddresses,
                onChanged: st.setShowAddresses,
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: Text(S.clearCache),
                onTap: () => _clearCache(context, st.store),
              ),
            ]),
          _section(context, S.secAbout, [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(S.versionLabel),
              trailing: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) =>
                    value(snap.hasData ? '${snap.data!.version} (${snap.data!.buildNumber})' : ''),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(S.licenses),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(context: context, applicationName: S.appName),
            ),
          ]),
        ],
      ),
    );
  }
}
