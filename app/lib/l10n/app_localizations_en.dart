// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Monitor and control your devices';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get apply => 'Apply';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Try again';

  @override
  String get back => 'Back';

  @override
  String get stay => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get close => 'Close';

  @override
  String get remove => 'Remove';

  @override
  String get clear => 'Clear';

  @override
  String get undo => 'Undo';

  @override
  String get details => 'Details';

  @override
  String get turnOn => 'Turn on';

  @override
  String get rename => 'Rename';

  @override
  String get errBluetoothOff => 'Bluetooth is off. Turn it on to connect.';

  @override
  String get errPermission => 'VP Hub needs Bluetooth access to connect.';

  @override
  String get errUnreachable =>
      'Can\'t reach the device. Move closer and make sure it\'s powered on.';

  @override
  String get errUnsupported => 'This device isn\'t supported by VP Hub.';

  @override
  String get errBadData =>
      'The device sent invalid data. Restart the device and try again.';

  @override
  String get errNoResponse => 'The device didn\'t respond. Try again.';

  @override
  String get errRejected => 'The device rejected the change.';

  @override
  String get errTooLong =>
      'Too many changes at once. Save fewer changes and try again.';

  @override
  String get errNotConnected =>
      'Not connected. Wait for the device to reconnect.';

  @override
  String get errNotAccepted =>
      'The device didn\'t accept the value. Check the value and try again.';

  @override
  String get errUnknown => 'Something went wrong. Try again.';

  @override
  String get errFile => 'Can\'t open the file. Choose a different file.';

  @override
  String get errFileFormat => 'This file isn\'t a valid device file.';

  @override
  String get errScan =>
      'Can\'t scan for devices. Make sure Bluetooth is on and try again.';

  @override
  String get errorDetails => 'Error details';

  @override
  String get saved => 'Saved';

  @override
  String get interfaceReloaded => 'Interface reloaded';

  @override
  String commandSent(String label) {
    return '$label: command sent';
  }

  @override
  String turnedOn(String label) {
    return '$label turned on';
  }

  @override
  String turnedOff(String label) {
    return '$label turned off';
  }

  @override
  String changedTo(String label, String value) {
    return '$label: $value';
  }

  @override
  String get protoDemo => 'Demo device (no hardware)';

  @override
  String get protoKiln => 'Legacy kiln controller (kiln_v0 adapter)';

  @override
  String get protoC3 => 'Legacy C3 relay (c3relay_v1 adapter)';

  @override
  String get demoTitle => 'Demo devices';

  @override
  String get demoHint =>
      'Simulated devices for exploring the interface without hardware. Readings drift slightly every second and every command succeeds.';

  @override
  String get demoRelay => 'Demo relay';

  @override
  String get demoRelaySub =>
      'Overview, schedule with repeating slots, and settings screens in the menu.';

  @override
  String get demoAll => 'All data types';

  @override
  String get demoAllSub =>
      'Every type and display hint, show and enable conditions, and one unknown type.';

  @override
  String get openJson => 'Open JSON file';

  @override
  String get openJsonSub =>
      'Choose a device file from phone storage to preview the schema of a new device.';

  @override
  String get onboardBody =>
      'VP Hub connects to your sensors and controllers over Bluetooth.';

  @override
  String get onboardWhy =>
      'To find devices near you and connect to them, VP Hub needs Bluetooth access. It is never used to track your location.';

  @override
  String get onboardAllow => 'Allow Bluetooth access';

  @override
  String get scan => 'Scan';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get stopScan => 'Stop';

  @override
  String get scanning => 'Scanning…';

  @override
  String get noNewDevices => 'No new devices nearby.';

  @override
  String get myDevices => 'My devices';

  @override
  String get nearby => 'Nearby';

  @override
  String get inRange => 'In range';

  @override
  String get scanEmptyTitle => 'No devices nearby';

  @override
  String get scanEmptyHint =>
      'Turn on your device and keep the phone within a few meters.';

  @override
  String get tagLegacy => 'Legacy';

  @override
  String get removeDevice => 'Remove device';

  @override
  String get deviceRemoved => 'Device removed';

  @override
  String get renameDevice => 'Rename device';

  @override
  String get renameDeviceHint => 'This name is used in VP Hub only.';

  @override
  String get deviceNameLabel => 'Name';

  @override
  String get btOff => 'Bluetooth is off. Turn it on to find devices.';

  @override
  String get btTurnOn => 'Turn on Bluetooth';

  @override
  String get permMissing =>
      'VP Hub needs Bluetooth access to find and connect to devices. Allow it in the app settings.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get locationOff => 'Turn on Location to find Bluetooth devices.';

  @override
  String get openLocationSettings => 'Open location settings';

  @override
  String get btOn => 'Bluetooth is on';

  @override
  String get btOffShort => 'Bluetooth is off';

  @override
  String rssiDbm(int r) {
    return '$r dBm';
  }

  @override
  String get openMenu => 'Open menu';

  @override
  String get secDevice => 'This device';

  @override
  String get secApp => 'App';

  @override
  String get deviceList => 'Device list';

  @override
  String get settings => 'Settings';

  @override
  String get helpAbout => 'Help & about';

  @override
  String get secGeneral => 'General';

  @override
  String get secAdvanced => 'Advanced';

  @override
  String get secDeveloper => 'Developer tools';

  @override
  String get secAbout => 'About';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get autoConnect => 'Auto-connect to last device';

  @override
  String get keepAwake => 'Keep screen on while connected';

  @override
  String get techMode => 'Technician mode';

  @override
  String get techModeSub => 'Shows setup, calibration and diagnostic options.';

  @override
  String get setPin => 'Set PIN';

  @override
  String get removePin => 'Remove PIN';

  @override
  String get pinSub =>
      'Ask for a 4-digit PIN before turning on Technician mode.';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get newPin => 'New PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get pinWrong => 'Incorrect PIN. Try again.';

  @override
  String get pinFormat => 'Enter 4 digits.';

  @override
  String get pinMismatch => 'The PINs don\'t match.';

  @override
  String get removePinTitle => 'Remove PIN?';

  @override
  String get removePinBody =>
      'Technician mode will turn on without asking for a PIN.';

  @override
  String get pinSet => 'PIN set';

  @override
  String get pinRemoved => 'PIN removed';

  @override
  String get showAddr => 'Show device addresses';

  @override
  String get exportLog => 'Export diagnostics log';

  @override
  String get exportLogEmpty => 'The diagnostics log is empty.';

  @override
  String get clearCache => 'Clear saved interfaces';

  @override
  String get clearCacheTitle => 'Clear saved interfaces?';

  @override
  String get clearCacheBody =>
      'VP Hub will load each device interface again the next time you connect.';

  @override
  String get cacheCleared => 'Saved interfaces cleared';

  @override
  String get versionLabel => 'Version';

  @override
  String get licenses => 'Open-source licenses';

  @override
  String get connecting => 'Connecting…';

  @override
  String get connected => 'Connected';

  @override
  String get reconnecting => 'Reconnecting…';

  @override
  String get disconnected => 'Disconnected';

  @override
  String connectedUpdated(int sec) {
    return 'Connected · updated $sec s ago';
  }

  @override
  String noNewData(int sec) {
    return 'No new data for $sec s';
  }

  @override
  String get onCaps => 'ON';

  @override
  String get offCaps => 'OFF';

  @override
  String get alarmNone => 'No active alarms';

  @override
  String get alarmsTitle => 'Active alarms';

  @override
  String get alarmsTooltip => 'Alarms';

  @override
  String get showTrend => 'Show chart';

  @override
  String durDH(String d, String h) {
    return '$d d $h h';
  }

  @override
  String durHM(String h, String m) {
    return '$h h $m min';
  }

  @override
  String durMS(String m, String s) {
    return '$m min $s s';
  }

  @override
  String get loadingDevice => 'Loading device…';

  @override
  String get connectFailed => 'Can\'t connect';

  @override
  String get lostRetrying => 'Connection lost. Reconnecting…';

  @override
  String get lostGiveUp => 'Can\'t reconnect to the device.';

  @override
  String get deviceInfo => 'Device info';

  @override
  String get disconnect => 'Disconnect';

  @override
  String disconnectTitle(String name) {
    return 'Disconnect from $name?';
  }

  @override
  String get disconnectBody => 'Changes you haven\'t saved will be lost.';

  @override
  String get reloadInterface => 'Reload interface';

  @override
  String get needUpdate => 'This device needs a newer version of VP Hub.';

  @override
  String get noScreens =>
      'This device has nothing to show. Update the device firmware or contact support.';

  @override
  String get screenError =>
      'This screen can\'t be displayed. Update the device firmware or contact support.';

  @override
  String get unsavedTitle => 'Save changes?';

  @override
  String get noLimit => 'No limit';

  @override
  String get flagsNone => 'Normal';

  @override
  String flagN(int n) {
    return 'Alarm $n';
  }

  @override
  String get invalidNumber => 'Enter a number.';

  @override
  String rangeHint(String min, String max) {
    return 'From $min to $max';
  }

  @override
  String outOfRange(String min, String max) {
    return 'Enter a value from $min to $max.';
  }

  @override
  String atLeast(String min) {
    return 'Enter $min or more.';
  }

  @override
  String atMost(String max) {
    return 'Enter $max or less.';
  }

  @override
  String maxLen(int n) {
    return 'Use up to $n characters.';
  }

  @override
  String get notEmpty => 'This can\'t be empty.';

  @override
  String get notSet => 'Not set';

  @override
  String get trendEmpty => 'Collecting data…';

  @override
  String get dayMon => 'Mo';

  @override
  String get dayTue => 'Tu';

  @override
  String get dayWed => 'We';

  @override
  String get dayThu => 'Th';

  @override
  String get dayFri => 'Fr';

  @override
  String get daySat => 'Sa';

  @override
  String get daySun => 'Su';

  @override
  String get infoName => 'Name';

  @override
  String get infoModel => 'Model';

  @override
  String get infoFw => 'Firmware';

  @override
  String get infoHw => 'Hardware';

  @override
  String get infoSignal => 'Signal';

  @override
  String get infoStatus => 'Status';

  @override
  String get signalExcellent => 'Excellent';

  @override
  String get signalGood => 'Good';

  @override
  String get signalFair => 'Fair';

  @override
  String get signalWeak => 'Weak';

  @override
  String get infoPv => 'Protocol version';

  @override
  String get infoProto => 'Protocol';

  @override
  String get infoScreens => 'Screens';

  @override
  String get infoSch => 'Schema ID';

  @override
  String get infoCaps => 'Capabilities';

  @override
  String get infoSchemaSrc => 'Schema source';

  @override
  String get fromCache => 'Saved in app';

  @override
  String get fromDevice => 'Read from device';

  @override
  String get infoMtu => 'MTU';

  @override
  String get infoMaxValues => 'Largest data packet';

  @override
  String get infoPackets => 'Data packets received';

  @override
  String get infoBad => 'Corrupted packets';

  @override
  String get infoAddr => 'Address';

  @override
  String get valuesTooBig =>
      'A data packet is larger than 240 bytes. The firmware must split the screen or use shorter field IDs (PROTOCOL §8).';

  @override
  String get badPacketsWarn =>
      'Corrupted data packets were received. The data may be too long for the MTU.';

  @override
  String bytesN(int n) {
    return '$n bytes';
  }

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'VP Hub connects to your sensors and controllers over Bluetooth.';

  @override
  String get aboutProtocol => 'Protocol VPH v1.3';

  @override
  String get aboutSupported => 'Supported devices';

  @override
  String get aboutSupportedList =>
      '• Devices made for VP Hub\n• ESP32-C3 relay controller\n• MAX31856 kiln controller';

  @override
  String versionN(String v) {
    return 'Version $v';
  }

  @override
  String unsavedBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'This screen has $n changes that aren\'t saved to the device.',
      one: 'This screen has 1 change that isn\'t saved to the device.',
    );
    return '$_temp0';
  }

  @override
  String batchChanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n unsaved changes',
      one: '1 unsaved change',
    );
    return '$_temp0';
  }
}
