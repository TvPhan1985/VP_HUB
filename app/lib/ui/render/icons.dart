import 'package:flutter/material.dart';

/// Bo icon chuan cua giao thuc (PROTOCOL §5.6): ten co dinh -> Material Icons
const Map<String, IconData> _vphIcons = {
  'dashboard': Icons.dashboard_outlined,
  'schedule': Icons.schedule,
  'settings': Icons.settings_outlined,
  'tune': Icons.tune,
  'info': Icons.info_outline,
  'device': Icons.developer_board,
  'temp': Icons.thermostat,
  'hum': Icons.water_drop,
  'water': Icons.water,
  'soil': Icons.grass,
  'light': Icons.lightbulb_outline,
  'sun': Icons.wb_sunny_outlined,
  'fan': Icons.mode_fan_off_outlined,
  'pump': Icons.water_damage_outlined,
  'motor': Icons.settings_suggest_outlined,
  'fire': Icons.local_fire_department,
  'heater': Icons.whatshot,
  'bolt': Icons.bolt,
  'power': Icons.power_settings_new,
  'plug': Icons.power,
  'speed': Icons.speed,
  'gauge': Icons.av_timer,
  'timer': Icons.timer_outlined,
  'clock': Icons.access_time,
  'calendar': Icons.event,
  'alarm': Icons.notifications_active_outlined,
  'warning': Icons.warning_amber_rounded,
  'mute': Icons.volume_off,
  'bell': Icons.notifications_none,
  'hand': Icons.pan_tool_outlined,
  'auto': Icons.auto_mode,
  'sensor': Icons.sensors,
  'wifi': Icons.wifi,
  'ble': Icons.bluetooth,
  'battery': Icons.battery_std,
  'chip': Icons.memory,
  'play': Icons.play_arrow,
  'pause': Icons.pause,
  'stop': Icons.stop,
  'refresh': Icons.refresh,
  'reset': Icons.restart_alt,
  'check': Icons.check_circle_outline,
  'save': Icons.save_outlined,
};

/// Ten la hoac null -> null (khong hien icon, khong loi)
IconData? vphIcon(String? name) => name == null ? null : _vphIcons[name];

/// Icon cua tab khi man hinh khong co `ic`: chon theo vi tri
IconData screenIcon(String? name, int index) =>
    vphIcon(name) ??
    const [Icons.dashboard_outlined, Icons.schedule, Icons.tune, Icons.info_outline, Icons.settings_outlined][index % 5];
