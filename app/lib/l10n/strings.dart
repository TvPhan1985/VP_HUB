/// Moi chu hien thi trong app (tieng Anh) gom o day
class S {
  static const appName = 'VP Hub';
  static const appTagline = 'BLE Device Manager';

  // ----- Chung -----
  static const ok = 'OK';
  static const cancel = 'Cancel';
  static const save = 'Save';
  static const retry = 'Retry';
  static const back = 'Back';
  static const stay = 'Stay';
  static const discard = 'Discard';
  static const close = 'Close';
  static const confirmTitle = 'Confirm';
  static const noData = '--';

  // ----- Loi / thong bao tu transport -----
  static const badInfo = 'The device did not answer with a valid VPH INFO packet';
  static const deviceRefused = 'Command rejected by the device';
  static const noResponse = 'No response from the device';
  static const linkLost = 'Disconnected';
  static const notConnected = 'Not connected to the device';
  static const emptySchema = 'The device did not send any screen';
  static const kilnNotAccepted = 'Value not accepted by the device';
  static const unsupportedDevice = 'This device uses a protocol that VP Hub does not support';
  static const saved = 'Saved';
  static const schemaReloaded = 'Schema reloaded from the device';
  static String writeTooLong(int len, int max) =>
      'Command too long ($len bytes, max $max). Save fewer changes at a time.';
  static String sendFailed(Object e) => 'Send failed: ${_short(e)}';
  static String selectFailed(Object e) => 'Could not switch screen: ${_short(e)}';
  static String sent(String label) => 'Sent: $label';
  static String turnedOn(String label) => '$label turned on';
  static String turnedOff(String label) => '$label turned off';
  static String changedTo(String label, String value) => '$label: $value';

  static const protoDemo = 'Demo device (no hardware)';
  static const protoKiln = 'Legacy: kiln controller (kiln_v0 adapter)';
  static const protoC3 = 'Legacy: C3 relay (c3relay_v1 adapter)';

  // ----- Demo -----
  static const demoTitle = 'Demo Devices';
  static const demoHint =
      'Simulated devices for exploring the interface without hardware. Readings drift slightly every second and every write succeeds.';
  static const demoRelay = 'Demo Relay';
  static const demoRelaySub = 'Overview, schedule with repeating slots, 2 settings screens in the drawer';
  static const demoAll = 'All Data Types';
  static const demoAllSub = 'Every type and display hint, show/enable conditions, one unknown type';
  static const openJson = 'Open JSON File';
  static const openJsonSub = 'Pick a demo file from phone storage to try the schema of a new device';
  static const demoNoScreens = 'Invalid file: the "screens" array is missing';
  static String demoBadJson(String e) => 'Invalid JSON file: $e';
  static String demoOpenFailed(Object e) => 'Could not open the file: ${_short(e)}';

  // ----- Man Quet -----
  static const scan = 'Scan';
  static const stopScan = 'Stop';
  static const scanning = 'Scanning for devices...';
  static const noDevices = 'No other devices nearby.\nTap "Scan" to search again.';
  static const knownDevices = 'Saved Devices';
  static const nearby = 'Nearby Devices';
  static const seenNow = 'In range';
  static const scanEmptyTitle = 'No devices found';
  static const scanEmptyHint = 'Power on the device, keep the phone close, then tap "Scan".';
  static const tagVph = 'VPH';
  static const tagLegacy = 'Legacy';
  static const forget = 'Remove from list';
  static const btOff = 'Bluetooth is off. Turn on Bluetooth to scan for devices.';
  static const btTurnOn = 'Turn On Bluetooth';
  static const permMissing =
      'VP Hub needs the "Nearby devices" (Bluetooth) permission to scan and connect. Grant it in the app settings.';
  static const openSettings = 'Open Settings';
  static const menuDemo = 'Demo Devices';
  static const menuAuto = 'Auto-connect on Launch';
  static const menuAbout = 'About';
  static const btReady = 'Bluetooth ready';
  static const btOffShort = 'Bluetooth off';
  static String scanFailed(Object e) => 'Scan failed: ${_short(e)}';
  static String rssi(int r) => '$r dBm';

  // ----- Menu he thong (Navigation Drawer) -----
  static const openMenu = 'Open menu';
  static const secDevices = 'Devices';
  static const secDevice = 'Device';
  static const secApp = 'App Settings';
  static const secSupport = 'Support';
  static const menuDeviceList = 'Device List';
  static const menuTheme = 'Theme';
  static const themeSystem = 'System default';
  static const themeLight = 'Light';
  static const themeDark = 'Dark';
  static const on = 'On';
  static const off = 'Off';

  // ----- Man Thiet bi -----
  static const connecting = 'Connecting...';
  static const linkOk = 'Connected';
  static const linkRetry = 'Reconnecting…';
  static const onCaps = 'ON';
  static const offCaps = 'OFF';
  static const alarmNone = 'No active alarms';
  static const alarmsTitle = 'Active Alarms';
  static const alarmsTooltip = 'Alarms';
  static const showTrend = 'Tap to show the trend chart';
  static String durDH(int d, int h) => '$d d $h h';
  static String durHM(int h, int m) => '$h h $m min';
  static String durMS(int m, int s) => '$m min $s s';
  static const loadingSchema = 'Loading the interface from the device...';
  static const connectFailed = 'Connection failed';
  static const lostRetrying = 'Connection lost, reconnecting…';
  static const lostGiveUp = 'Connection to the device was lost.';
  static const menuInfo = 'Device Information';
  static const menuDisconnect = 'Disconnect';
  static const menuReload = 'Reload Schema';
  static const needUpdate = 'This device uses a newer protocol. Please update VP Hub.';
  static const noScreens = 'The device has no screens';
  static const schemaError = 'The schema of this screen is invalid and cannot be rendered';
  static const unsavedTitle = 'Unsaved changes';
  static String unsavedBody(int n) =>
      n == 1 ? 'This screen has 1 change not yet saved to the device.' : 'This screen has $n changes not yet saved to the device.';
  static String batchChanges(int n) => n == 1 ? '1 change' : '$n changes';
  static const noLimit = 'No limit';
  static const flagsNone = 'Normal';
  static String flagBit(int i) => 'Alarm bit $i';
  static const repDefault = 'Item';
  static const dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const invalidNumber = 'Enter a number';
  static String outOfRange(String min, String max) => 'Must be between $min and $max';
  static String atLeast(String min) => 'Must be at least $min';
  static String atMost(String max) => 'Must be at most $max';
  static String maxLen(int n) => 'Up to $n characters';
  static const notEmpty = 'Must not be empty';
  static const notSet = 'Not set';
  static const pickDate = 'Select date';
  static const pickTime = 'Select time';
  static const trendEmpty = 'Collecting chart data...';

  // ----- Thong tin thiet bi -----
  static const infoName = 'Name';
  static const infoModel = 'Model';
  static const infoFw = 'Firmware';
  static const infoHw = 'Hardware';
  static const infoPv = 'Protocol version';
  static const infoProto = 'Transport';
  static const infoScreens = 'Screens';
  static const infoSch = 'Schema ID';
  static const infoCaps = 'Capabilities';
  static const infoSchemaSrc = 'Schema source';
  static const fromCache = 'App cache';
  static const fromDevice = 'Read from device';
  static const infoMtu = 'MTU';
  static const infoMaxValues = 'Largest VALUES packet';
  static const infoPackets = 'VALUES packets received';
  static const infoBad = 'Corrupt (truncated) packets';
  static const valuesTooBig =
      'A VALUES packet exceeds 240 bytes: the firmware violates PROTOCOL §8. Split the screen or shorten the ids.';
  static const badPacketsWarn = 'Corrupt VALUES packets received: VALUES may be too long for the MTU.';
  static String bytes(int n) => '$n bytes';

  // ----- Gioi thieu -----
  static const aboutBody =
      'One app for every ESP32 device: scan, monitor and control over BLE. The interface is rendered from the schema sent by the device (VPH protocol v1.1), so a new device needs no new app.';
  static const aboutSupported = 'Supported devices';
  static const aboutSupportedList =
      '• Any device that speaks the VPH v1 protocol\n• ESP32-C3 relay controller (legacy firmware)\n• MAX31856 kiln controller (legacy firmware)';
  static String version(String v) => 'Version $v';

  static String _short(Object e) {
    var s = e.toString();
    if (s.startsWith('Exception: ')) s = s.substring(11);
    return s.length > 120 ? '${s.substring(0, 120)}...' : s;
  }
}
