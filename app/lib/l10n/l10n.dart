import 'package:flutter/widgets.dart';

import '../core/errors.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// Chu cua app theo ngon ngu dang chon: `context.l.save`
extension L10nContext on BuildContext {
  AppLocalizations get l =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? lookupAppLocalizations(const Locale('en'));
}

/// Ten ngon ngu, viet bang chinh ngon ngu do
String languageName(String code) => code == 'vi' ? 'Tiếng Việt' : 'English';

/// Cau hien cho nguoi dung cua mot loi (bang trong PLAN_HOAN_THIEN §H6)
String errorText(AppLocalizations l, AppError e) => switch (e.kind) {
      ErrorKind.bluetoothOff => l.errBluetoothOff,
      ErrorKind.permission => l.errPermission,
      ErrorKind.unreachable => l.errUnreachable,
      ErrorKind.unsupported => l.errUnsupported,
      ErrorKind.badData => l.errBadData,
      ErrorKind.noResponse => l.errNoResponse,
      ErrorKind.rejected => l.errRejected,
      ErrorKind.device => e.deviceText ?? l.errRejected,
      ErrorKind.tooLong => l.errTooLong,
      ErrorKind.notConnected => l.errNotConnected,
      ErrorKind.notAccepted => l.errNotAccepted,
      ErrorKind.file => l.errFile,
      ErrorKind.fileFormat => l.errFileFormat,
      ErrorKind.scan => l.errScan,
      ErrorKind.unknown => l.errUnknown,
    };

/// Muc song theo so vach 1..4
String signalLevelText(AppLocalizations l, int bars) => switch (bars) {
      4 => l.signalExcellent,
      3 => l.signalGood,
      2 => l.signalFair,
      _ => l.signalWeak,
    };

/// Thu 2 ... Chu nhat
List<String> dayLabels(AppLocalizations l) =>
    [l.dayMon, l.dayTue, l.dayWed, l.dayThu, l.dayFri, l.daySat, l.daySun];

/// Ten giao thuc that cua transport (chi hien o Technician)
String protoText(AppLocalizations l, String protoId) => switch (protoId) {
      'demo' => l.protoDemo,
      'kiln_v0' => l.protoKiln,
      'c3relay_v1' => l.protoC3,
      _ => protoId,
    };
