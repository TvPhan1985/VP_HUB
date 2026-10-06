import 'package:flutter/material.dart';

import 'core/schema_cache.dart';
import 'l10n/strings_vi.dart';
import 'ui/screens/scan_screen.dart';

ThemeData vpHubTheme(Brightness b) => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00796B), brightness: b),
      cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(horizontal: 4, vertical: 5)),
    );

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
