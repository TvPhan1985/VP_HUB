import 'package:flutter/material.dart';

import 'core/schema_cache.dart';
import 'l10n/strings.dart';
import 'ui/screens/scan_screen.dart';
import 'ui/theme.dart';

export 'ui/theme.dart' show vpHubTheme;

class VpHubApp extends StatefulWidget {
  final KvStore store;
  const VpHubApp({super.key, required this.store});

  @override
  State<VpHubApp> createState() => _VpHubAppState();
}

class _VpHubAppState extends State<VpHubApp> {
  late final ThemeController _theme = ThemeController(widget.store);

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ThemeScope(
        controller: _theme,
        // ThemeMode.system: MaterialApp tu doi theo he dieu hanh, khong can mo lai app
        child: ListenableBuilder(
          listenable: _theme,
          builder: (context, _) => MaterialApp(
            title: S.appName,
            debugShowCheckedModeBanner: false,
            theme: vpHubTheme(Brightness.light),
            darkTheme: vpHubTheme(Brightness.dark),
            themeMode: _theme.mode,
            home: ScanScreen(store: widget.store),
          ),
        ),
      );
}
