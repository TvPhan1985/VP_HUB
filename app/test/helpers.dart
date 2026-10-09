import 'package:flutter/material.dart';
import 'package:vphub/core/app_settings.dart';
import 'package:vphub/l10n/l10n.dart';
import 'package:vphub/ui/theme.dart';

/// Chu tieng Anh cua app (ban goc) de test so sanh
final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

/// Boc mot man hinh nhu app that: SettingsScope + MaterialApp co da ngon ngu, doi theo cai dat
Widget wrapApp({required AppSettings settings, required Widget home}) => SettingsScope(
      settings: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: vpHubTheme(Brightness.light),
          darkTheme: vpHubTheme(Brightness.dark),
          themeMode: settings.mode,
          home: home,
        ),
      ),
    );
