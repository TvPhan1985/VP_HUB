import 'package:flutter/material.dart';

import 'core/schema_cache.dart';
import 'l10n/strings_vi.dart';
import 'ui/screens/scan_screen.dart';
import 'ui/theme.dart';

export 'ui/theme.dart' show vpHubTheme;

class VpHubApp extends StatelessWidget {
  final KvStore store;
  const VpHubApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: S.appName,
        debugShowCheckedModeBanner: false,
        theme: vpHubTheme(Brightness.light),
        darkTheme: vpHubTheme(Brightness.dark),
        home: ScanScreen(store: store),
      );
}
