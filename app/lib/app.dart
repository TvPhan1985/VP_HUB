import 'package:flutter/material.dart';

import 'core/app_settings.dart';
import 'core/schema_cache.dart';
import 'core/consts.dart';
import 'l10n/l10n.dart';
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
  late final AppSettings _settings = AppSettings(widget.store);

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsScope(
        settings: _settings,
        // ThemeMode.system: MaterialApp tu doi theo he dieu hanh, khong can mo lai app
        child: ListenableBuilder(
          listenable: _settings,
          builder: (context, _) => MaterialApp(
            title: kAppName,
            // Mac dinh English (khong theo ngon ngu may); nguoi dung chon Tieng Viet trong Settings
            locale: _settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            debugShowCheckedModeBanner: false,
            theme: vpHubTheme(Brightness.light),
            darkTheme: vpHubTheme(Brightness.dark),
            themeMode: _settings.mode,
            home: ScanScreen(store: widget.store),
          ),
        ),
      );
}
