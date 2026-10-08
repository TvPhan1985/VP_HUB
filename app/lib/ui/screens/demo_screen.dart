import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/device_session.dart';
import '../../core/transport/demo_transport.dart';
import '../../l10n/strings.dart';
import 'device_screen.dart';

const String kDemoRelayAsset = 'assets/demo/demo_relay.json';
const String kDemoAllTypesAsset = 'assets/demo/demo_all_types.json';

/// Che do thu (SPEC §6): thiet bi gia tu assets/demo hoac tu file JSON tren dien thoai
class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  Future<void> _open(BuildContext context, String title, Future<String> Function() load) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final String src;
    try {
      src = await load();
      // Thu parse truoc de bao loi file ngay tai day
      await DemoTransport.fromJson(src, tick: null).close();
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(S.demoOpenFailed(e))));
      return;
    }
    final session = DeviceSession(connector: () async => DemoTransport.fromJson(src), title: title);
    session.connect();
    await nav.push(MaterialPageRoute(builder: (_) => DeviceScreen(session: session)));
    session.dispose();
  }

  Future<void> _pick(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final files = await FilePicker.pickFiles(type: FileType.any);
      if (files.isEmpty || !context.mounted) return;
      final f = files.first;
      final path = f.path;
      if (path == null) throw Exception('khong co duong dan file');
      await _open(context, f.name, () => File(path).readAsString());
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(S.demoOpenFailed(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.demoTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(4, 4, 4, 12), child: Text(S.demoHint)),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.power_settings_new),
                  title: const Text(S.demoRelay),
                  subtitle: const Text(S.demoRelaySub),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, S.demoRelay, () => rootBundle.loadString(kDemoRelayAsset)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.widgets_outlined),
                  title: const Text(S.demoAll),
                  subtitle: const Text(S.demoAllSub),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, S.demoAll, () => rootBundle.loadString(kDemoAllTypesAsset)),
                ),
              ],
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text(S.openJson),
              subtitle: const Text(S.openJsonSub),
              onTap: () => _pick(context),
            ),
          ),
        ],
      ),
    );
  }
}
