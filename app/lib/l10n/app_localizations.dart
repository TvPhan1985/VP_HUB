import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Monitor and control your devices'**
  String get appTagline;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get stay;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @errBluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn it on to connect.'**
  String get errBluetoothOff;

  /// No description provided for @errPermission.
  ///
  /// In en, this message translates to:
  /// **'VP Hub needs Bluetooth access to connect.'**
  String get errPermission;

  /// No description provided for @errUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the device. Move closer and make sure it\'s powered on.'**
  String get errUnreachable;

  /// No description provided for @errUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This device isn\'t supported by VP Hub.'**
  String get errUnsupported;

  /// No description provided for @errBadData.
  ///
  /// In en, this message translates to:
  /// **'The device sent invalid data. Restart the device and try again.'**
  String get errBadData;

  /// No description provided for @errNoResponse.
  ///
  /// In en, this message translates to:
  /// **'The device didn\'t respond. Try again.'**
  String get errNoResponse;

  /// No description provided for @errRejected.
  ///
  /// In en, this message translates to:
  /// **'The device rejected the change.'**
  String get errRejected;

  /// No description provided for @errTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too many changes at once. Save fewer changes and try again.'**
  String get errTooLong;

  /// No description provided for @errNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected. Wait for the device to reconnect.'**
  String get errNotConnected;

  /// No description provided for @errNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'The device didn\'t accept the value. Check the value and try again.'**
  String get errNotAccepted;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errUnknown;

  /// No description provided for @errFile.
  ///
  /// In en, this message translates to:
  /// **'Can\'t open the file. Choose a different file.'**
  String get errFile;

  /// No description provided for @errFileFormat.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t a valid device file.'**
  String get errFileFormat;

  /// No description provided for @errScan.
  ///
  /// In en, this message translates to:
  /// **'Can\'t scan for devices. Make sure Bluetooth is on and try again.'**
  String get errScan;

  /// No description provided for @errorDetails.
  ///
  /// In en, this message translates to:
  /// **'Error details'**
  String get errorDetails;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @interfaceReloaded.
  ///
  /// In en, this message translates to:
  /// **'Interface reloaded'**
  String get interfaceReloaded;

  /// No description provided for @commandSent.
  ///
  /// In en, this message translates to:
  /// **'{label}: command sent'**
  String commandSent(String label);

  /// No description provided for @turnedOn.
  ///
  /// In en, this message translates to:
  /// **'{label} turned on'**
  String turnedOn(String label);

  /// No description provided for @turnedOff.
  ///
  /// In en, this message translates to:
  /// **'{label} turned off'**
  String turnedOff(String label);

  /// No description provided for @changedTo.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String changedTo(String label, String value);

  /// No description provided for @protoDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo device (no hardware)'**
  String get protoDemo;

  /// No description provided for @protoKiln.
  ///
  /// In en, this message translates to:
  /// **'Legacy kiln controller (kiln_v0 adapter)'**
  String get protoKiln;

  /// No description provided for @protoC3.
  ///
  /// In en, this message translates to:
  /// **'Legacy C3 relay (c3relay_v1 adapter)'**
  String get protoC3;

  /// No description provided for @demoTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo devices'**
  String get demoTitle;

  /// No description provided for @demoHint.
  ///
  /// In en, this message translates to:
  /// **'Simulated devices for exploring the interface without hardware. Readings drift slightly every second and every command succeeds.'**
  String get demoHint;

  /// No description provided for @demoRelay.
  ///
  /// In en, this message translates to:
  /// **'Demo relay'**
  String get demoRelay;

  /// No description provided for @demoRelaySub.
  ///
  /// In en, this message translates to:
  /// **'Overview, schedule with repeating slots, and settings screens in the menu.'**
  String get demoRelaySub;

  /// No description provided for @demoAll.
  ///
  /// In en, this message translates to:
  /// **'All data types'**
  String get demoAll;

  /// No description provided for @demoAllSub.
  ///
  /// In en, this message translates to:
  /// **'Every type and display hint, show and enable conditions, and one unknown type.'**
  String get demoAllSub;

  /// No description provided for @openJson.
  ///
  /// In en, this message translates to:
  /// **'Open JSON file'**
  String get openJson;

  /// No description provided for @openJsonSub.
  ///
  /// In en, this message translates to:
  /// **'Choose a device file from phone storage to preview the schema of a new device.'**
  String get openJsonSub;

  /// No description provided for @onboardBody.
  ///
  /// In en, this message translates to:
  /// **'VP Hub connects to your sensors and controllers over Bluetooth.'**
  String get onboardBody;

  /// No description provided for @onboardWhy.
  ///
  /// In en, this message translates to:
  /// **'To find devices near you and connect to them, VP Hub needs Bluetooth access. It is never used to track your location.'**
  String get onboardWhy;

  /// No description provided for @onboardAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluetooth access'**
  String get onboardAllow;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @stopScan.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopScan;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @noNewDevices.
  ///
  /// In en, this message translates to:
  /// **'No new devices nearby.'**
  String get noNewDevices;

  /// No description provided for @myDevices.
  ///
  /// In en, this message translates to:
  /// **'My devices'**
  String get myDevices;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @inRange.
  ///
  /// In en, this message translates to:
  /// **'In range'**
  String get inRange;

  /// No description provided for @scanEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No devices nearby'**
  String get scanEmptyTitle;

  /// No description provided for @scanEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on your device and keep the phone within a few meters.'**
  String get scanEmptyHint;

  /// No description provided for @tagLegacy.
  ///
  /// In en, this message translates to:
  /// **'Legacy'**
  String get tagLegacy;

  /// No description provided for @removeDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get removeDevice;

  /// No description provided for @deviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Device removed'**
  String get deviceRemoved;

  /// No description provided for @renameDevice.
  ///
  /// In en, this message translates to:
  /// **'Rename device'**
  String get renameDevice;

  /// No description provided for @renameDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'This name is used in VP Hub only.'**
  String get renameDeviceHint;

  /// No description provided for @deviceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get deviceNameLabel;

  /// No description provided for @btOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn it on to find devices.'**
  String get btOff;

  /// No description provided for @btTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth'**
  String get btTurnOn;

  /// No description provided for @permMissing.
  ///
  /// In en, this message translates to:
  /// **'VP Hub needs Bluetooth access to find and connect to devices. Allow it in the app settings.'**
  String get permMissing;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on Location to find Bluetooth devices.'**
  String get locationOff;

  /// No description provided for @openLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open location settings'**
  String get openLocationSettings;

  /// No description provided for @btOn.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is on'**
  String get btOn;

  /// No description provided for @btOffShort.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off'**
  String get btOffShort;

  /// No description provided for @rssiDbm.
  ///
  /// In en, this message translates to:
  /// **'{r} dBm'**
  String rssiDbm(int r);

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenu;

  /// No description provided for @secDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get secDevice;

  /// No description provided for @secApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get secApp;

  /// No description provided for @deviceList.
  ///
  /// In en, this message translates to:
  /// **'Device list'**
  String get deviceList;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @helpAbout.
  ///
  /// In en, this message translates to:
  /// **'Help & about'**
  String get helpAbout;

  /// No description provided for @secGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get secGeneral;

  /// No description provided for @secAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get secAdvanced;

  /// No description provided for @secDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer tools'**
  String get secDeveloper;

  /// No description provided for @secAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get secAbout;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @autoConnect.
  ///
  /// In en, this message translates to:
  /// **'Auto-connect to last device'**
  String get autoConnect;

  /// No description provided for @keepAwake.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on while connected'**
  String get keepAwake;

  /// No description provided for @techMode.
  ///
  /// In en, this message translates to:
  /// **'Technician mode'**
  String get techMode;

  /// No description provided for @techModeSub.
  ///
  /// In en, this message translates to:
  /// **'Shows setup, calibration and diagnostic options.'**
  String get techModeSub;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @removePin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get removePin;

  /// No description provided for @pinSub.
  ///
  /// In en, this message translates to:
  /// **'Ask for a 4-digit PIN before turning on Technician mode.'**
  String get pinSub;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @pinWrong.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Try again.'**
  String get pinWrong;

  /// No description provided for @pinFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter 4 digits.'**
  String get pinFormat;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs don\'t match.'**
  String get pinMismatch;

  /// No description provided for @removePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN?'**
  String get removePinTitle;

  /// No description provided for @removePinBody.
  ///
  /// In en, this message translates to:
  /// **'Technician mode will turn on without asking for a PIN.'**
  String get removePinBody;

  /// No description provided for @pinSet.
  ///
  /// In en, this message translates to:
  /// **'PIN set'**
  String get pinSet;

  /// No description provided for @pinRemoved.
  ///
  /// In en, this message translates to:
  /// **'PIN removed'**
  String get pinRemoved;

  /// No description provided for @showAddr.
  ///
  /// In en, this message translates to:
  /// **'Show device addresses'**
  String get showAddr;

  /// No description provided for @exportLog.
  ///
  /// In en, this message translates to:
  /// **'Export diagnostics log'**
  String get exportLog;

  /// No description provided for @exportLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'The diagnostics log is empty.'**
  String get exportLogEmpty;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear saved interfaces'**
  String get clearCache;

  /// No description provided for @clearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear saved interfaces?'**
  String get clearCacheTitle;

  /// No description provided for @clearCacheBody.
  ///
  /// In en, this message translates to:
  /// **'VP Hub will load each device interface again the next time you connect.'**
  String get clearCacheBody;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Saved interfaces cleared'**
  String get cacheCleared;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get licenses;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get reconnecting;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @connectedUpdated.
  ///
  /// In en, this message translates to:
  /// **'Connected · updated {sec} s ago'**
  String connectedUpdated(int sec);

  /// No description provided for @noNewData.
  ///
  /// In en, this message translates to:
  /// **'No new data for {sec} s'**
  String noNewData(int sec);

  /// No description provided for @onCaps.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get onCaps;

  /// No description provided for @offCaps.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get offCaps;

  /// No description provided for @alarmNone.
  ///
  /// In en, this message translates to:
  /// **'No active alarms'**
  String get alarmNone;

  /// No description provided for @alarmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active alarms'**
  String get alarmsTitle;

  /// No description provided for @alarmsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarmsTooltip;

  /// No description provided for @showTrend.
  ///
  /// In en, this message translates to:
  /// **'Show chart'**
  String get showTrend;

  /// No description provided for @durDH.
  ///
  /// In en, this message translates to:
  /// **'{d} d {h} h'**
  String durDH(String d, String h);

  /// No description provided for @durHM.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String durHM(String h, String m);

  /// No description provided for @durMS.
  ///
  /// In en, this message translates to:
  /// **'{m} min {s} s'**
  String durMS(String m, String s);

  /// No description provided for @loadingDevice.
  ///
  /// In en, this message translates to:
  /// **'Loading device…'**
  String get loadingDevice;

  /// No description provided for @connectFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect'**
  String get connectFailed;

  /// No description provided for @lostRetrying.
  ///
  /// In en, this message translates to:
  /// **'Connection lost. Reconnecting…'**
  String get lostRetrying;

  /// No description provided for @lostGiveUp.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reconnect to the device.'**
  String get lostGiveUp;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device info'**
  String get deviceInfo;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @disconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from {name}?'**
  String disconnectTitle(String name);

  /// No description provided for @disconnectBody.
  ///
  /// In en, this message translates to:
  /// **'Changes you haven\'t saved will be lost.'**
  String get disconnectBody;

  /// No description provided for @reloadInterface.
  ///
  /// In en, this message translates to:
  /// **'Reload interface'**
  String get reloadInterface;

  /// No description provided for @needUpdate.
  ///
  /// In en, this message translates to:
  /// **'This device needs a newer version of VP Hub.'**
  String get needUpdate;

  /// No description provided for @noScreens.
  ///
  /// In en, this message translates to:
  /// **'This device has nothing to show. Update the device firmware or contact support.'**
  String get noScreens;

  /// No description provided for @screenError.
  ///
  /// In en, this message translates to:
  /// **'This screen can\'t be displayed. Update the device firmware or contact support.'**
  String get screenError;

  /// No description provided for @unsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Save changes?'**
  String get unsavedTitle;

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// No description provided for @flagsNone.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get flagsNone;

  /// No description provided for @flagN.
  ///
  /// In en, this message translates to:
  /// **'Alarm {n}'**
  String flagN(int n);

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number.'**
  String get invalidNumber;

  /// No description provided for @rangeHint.
  ///
  /// In en, this message translates to:
  /// **'From {min} to {max}'**
  String rangeHint(String min, String max);

  /// No description provided for @outOfRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a value from {min} to {max}.'**
  String outOfRange(String min, String max);

  /// No description provided for @atLeast.
  ///
  /// In en, this message translates to:
  /// **'Enter {min} or more.'**
  String atLeast(String min);

  /// No description provided for @atMost.
  ///
  /// In en, this message translates to:
  /// **'Enter {max} or less.'**
  String atMost(String max);

  /// No description provided for @maxLen.
  ///
  /// In en, this message translates to:
  /// **'Use up to {n} characters.'**
  String maxLen(int n);

  /// No description provided for @notEmpty.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be empty.'**
  String get notEmpty;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @trendEmpty.
  ///
  /// In en, this message translates to:
  /// **'Collecting data…'**
  String get trendEmpty;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mo'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tu'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'We'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Th'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fr'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sa'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Su'**
  String get daySun;

  /// No description provided for @infoName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get infoName;

  /// No description provided for @infoModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get infoModel;

  /// No description provided for @infoFw.
  ///
  /// In en, this message translates to:
  /// **'Firmware'**
  String get infoFw;

  /// No description provided for @infoHw.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get infoHw;

  /// No description provided for @infoSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get infoSignal;

  /// No description provided for @infoStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get infoStatus;

  /// No description provided for @signalExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get signalExcellent;

  /// No description provided for @signalGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get signalGood;

  /// No description provided for @signalFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get signalFair;

  /// No description provided for @signalWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get signalWeak;

  /// No description provided for @infoPv.
  ///
  /// In en, this message translates to:
  /// **'Protocol version'**
  String get infoPv;

  /// No description provided for @infoProto.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get infoProto;

  /// No description provided for @infoScreens.
  ///
  /// In en, this message translates to:
  /// **'Screens'**
  String get infoScreens;

  /// No description provided for @infoSch.
  ///
  /// In en, this message translates to:
  /// **'Schema ID'**
  String get infoSch;

  /// No description provided for @infoCaps.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get infoCaps;

  /// No description provided for @infoSchemaSrc.
  ///
  /// In en, this message translates to:
  /// **'Schema source'**
  String get infoSchemaSrc;

  /// No description provided for @fromCache.
  ///
  /// In en, this message translates to:
  /// **'Saved in app'**
  String get fromCache;

  /// No description provided for @fromDevice.
  ///
  /// In en, this message translates to:
  /// **'Read from device'**
  String get fromDevice;

  /// No description provided for @infoMtu.
  ///
  /// In en, this message translates to:
  /// **'MTU'**
  String get infoMtu;

  /// No description provided for @infoMaxValues.
  ///
  /// In en, this message translates to:
  /// **'Largest data packet'**
  String get infoMaxValues;

  /// No description provided for @infoPackets.
  ///
  /// In en, this message translates to:
  /// **'Data packets received'**
  String get infoPackets;

  /// No description provided for @infoBad.
  ///
  /// In en, this message translates to:
  /// **'Corrupted packets'**
  String get infoBad;

  /// No description provided for @infoAddr.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get infoAddr;

  /// No description provided for @valuesTooBig.
  ///
  /// In en, this message translates to:
  /// **'A data packet is larger than 240 bytes. The firmware must split the screen or use shorter field IDs (PROTOCOL §8).'**
  String get valuesTooBig;

  /// No description provided for @badPacketsWarn.
  ///
  /// In en, this message translates to:
  /// **'Corrupted data packets were received. The data may be too long for the MTU.'**
  String get badPacketsWarn;

  /// No description provided for @bytesN.
  ///
  /// In en, this message translates to:
  /// **'{n} bytes'**
  String bytesN(int n);

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'VP Hub connects to your sensors and controllers over Bluetooth.'**
  String get aboutBody;

  /// No description provided for @aboutProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol VPH v1.3'**
  String get aboutProtocol;

  /// No description provided for @aboutSupported.
  ///
  /// In en, this message translates to:
  /// **'Supported devices'**
  String get aboutSupported;

  /// No description provided for @aboutSupportedList.
  ///
  /// In en, this message translates to:
  /// **'• Devices made for VP Hub\n• ESP32-C3 relay controller\n• MAX31856 kiln controller'**
  String get aboutSupportedList;

  /// No description provided for @versionN.
  ///
  /// In en, this message translates to:
  /// **'Version {v}'**
  String versionN(String v);

  /// No description provided for @unsavedBody.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{This screen has 1 change that isn\'t saved to the device.} other{This screen has {n} changes that aren\'t saved to the device.}}'**
  String unsavedBody(int n);

  /// No description provided for @batchChanges.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 unsaved change} other{{n} unsaved changes}}'**
  String batchChanges(int n);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
