import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/device_session.dart';
import '../../core/errors.dart';
import '../../core/transport/demo_transport.dart';
import '../../l10n/l10n.dart';
import 'device_screen.dart';

/// File thiet bi mau theo ngon ngu ('en' | 'vi')
String demoRelayAsset(String lang) =>
    lang == 'vi' ? 'assets/demo/demo_relay.vi.json' : 'assets/demo/demo_relay.json';
String demoAllTypesAsset(String lang) =>
    lang == 'vi' ? 'assets/demo/demo_all_types.vi.json' : 'assets/demo/demo_all_types.json';

/// Che do thu (SPEC §6): thiet bi gia tu assets/demo hoac tu file JSON tren dien thoai
class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  static Future<void> _open(BuildContext context, String title, Future<String> Function() load) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l;
    final String src;
    try {
      src = await load();
      // Thu parse truoc de bao loi file ngay tai day
      await DemoTransport.fromJson(src, tick: null).close();
    } catch (e) {
      // File hong dinh dang -> fileFormat; khong doc duoc file -> file
      messenger.showSnackBar(SnackBar(content: Text(errorText(l, AppError.from(e, fallback: ErrorKind.file)))));
      return;
    }
    final session = DeviceSession(connector: () async => DemoTransport.fromJson(src), title: title);
    session.connect();
    await nav.push(MaterialPageRoute(builder: (_) => DeviceScreen(session: session)));
    session.dispose();
  }

  /// Chon file JSON tren dien thoai roi mo thanh thiet bi mau
  static Future<void> pickAndOpen(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l;
    try {
      final files = await FilePicker.pickFiles(type: FileType.any);
      if (files.isEmpty || !context.mounted) return;
      final f = files.first;
      final path = f.path;
      if (path == null) throw Exception('khong co duong dan file');
      await _open(context, f.name, () => File(path).readAsString());
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.errFile)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l.demoTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(padding: EdgeInsets.fromLTRB(4, 4, 4, 12), child: Text(context.l.demoHint)),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.power_settings_new),
                  title: Text(context.l.demoRelay),
                  subtitle: Text(context.l.demoRelaySub),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, context.l.demoRelay, () => rootBundle.loadString(demoRelayAsset(context.l.localeName))),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.widgets_outlined),
                  title: Text(context.l.demoAll),
                  subtitle: Text(context.l.demoAllSub),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, context.l.demoAll, () => rootBundle.loadString(demoAllTypesAsset(context.l.localeName))),
                ),
              ],
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(context.l.openJson),
              subtitle: Text(context.l.openJsonSub),
              onTap: () => pickAndOpen(context),
            ),
          ),
        ],
      ),
    );
  }
}
