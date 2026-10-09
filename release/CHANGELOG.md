# VP Hub — Changelog

## 1.4.0 (2026-10-09)

Install `VPHub_1.4.0_arm64.apk` on current phones. Use `VPHub_1.4.0_arm32.apk` only on older 32-bit phones.

### New

- **Standard and Technician modes.** Standard shows what operators need: readings, on/off, mode, schedule and alarms. Technician mode (Settings → Technician mode, optional 4-digit PIN) adds sensor setup, calibration, tuning and diagnostics. A `TECH` badge shows when it is on.
- **Settings screen** for theme, language, auto-connect, keep screen on, and developer tools.
- **Welcome screen** on first launch that explains why Bluetooth access is needed before Android asks for it.
- **Data freshness.** The status line shows how long ago data was updated, and readings dim when no new data arrives for 15 seconds.
- **Charts** show the value and time when you touch them, and keep their history while the app is running.
- **Diagnostics log** that technicians can export and share.
- **Rename** a saved device (the name is used in VP Hub only). Removing a device can be undone.
- Pull down to scan again.
- New app icon (adaptive, with Android 13 themed icon) and a dark launch screen.

### Changed

- Opening the app no longer jumps straight into the last device. VP Hub scans first and connects only if that device is nearby.
- Clearer wording everywhere. Error messages say what happened and what to do next.
- Confirmation buttons name the action (`Restart device`, `Disconnect`) instead of `OK`. Destructive actions use a red button.
- The device screen has a back arrow on the left. The menu button moved to the right.
- Buttons vibrate lightly and show progress while the device is responding.
- Date and time pickers follow the selected language (English or Tiếng Việt).
- Relay controller: the Advanced screen is now **Alarm settings** (all users) and **Sensor setup** (Technician).
- The app download is much smaller (one file per phone type).

### Under the hood

- Bluetooth library replaced with `universal_ble` (BSD-3-Clause). All bundled libraries are listed in Settings → About → Open-source licenses.
- Protocol VPH v1.3: devices can mark screens and fields as advanced (`adv`). Older devices and older app versions keep working.

## 1.3.0 (2026-10-08)

- Agriculture and industrial themes, chosen by the device.
- Language setting: English or Tiếng Việt.

## 1.1.0 (2026-10-07)

- New display styles: tiles, status cards, alarm cards, trend charts.
- Settings screens moved into the menu.

## 1.0.0 (2026-10-06)

- First release.
