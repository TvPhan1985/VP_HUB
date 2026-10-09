import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/diag_log.dart';
import 'core/schema_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Nhat ky chan doan: file trong thu muc rieng cua app; loi thi chi con ban trong bo nho
  try {
    final dir = await getApplicationSupportDirectory();
    await DiagLog.instance.attach(File('${dir.path}/${DiagLog.fileName}'));
  } catch (_) {}
  logVph('Mo app');
  runApp(VpHubApp(store: PrefsStore(prefs)));
}
