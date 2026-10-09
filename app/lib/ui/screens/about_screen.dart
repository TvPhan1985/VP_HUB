import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/app_settings.dart';
import '../../core/consts.dart';
import '../../l10n/l10n.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(titleSpacing: null, title: Text(context.l.helpAbout)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.hub, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(kAppName, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => Text(
              snap.hasData ? context.l.versionN('${snap.data!.version} (${snap.data!.buildNumber})') : '',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Text(context.l.aboutBody),
          if (SettingsScope.technician(context)) ...[const SizedBox(height: 4), Text(context.l.aboutProtocol)],
          const SizedBox(height: 16),
          Text(context.l.aboutSupported, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(context.l.aboutSupportedList),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.description_outlined),
            label: Text(context.l.licenses),
            onPressed: () => showLicensePage(context: context, applicationName: kAppName),
          ),
        ],
      ),
    );
  }
}
