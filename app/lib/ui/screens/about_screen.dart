import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(S.menuAbout)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.hub, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(S.appName, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => Text(
              snap.hasData ? S.version('${snap.data!.version} (${snap.data!.buildNumber})') : '',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Text(S.aboutBody),
          const SizedBox(height: 16),
          Text(S.aboutSupported, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(S.aboutSupportedList),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.description_outlined),
            label: Text(S.licenses),
            onPressed: () => showLicensePage(context: context, applicationName: S.appName),
          ),
        ],
      ),
    );
  }
}
