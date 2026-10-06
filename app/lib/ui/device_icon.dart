import 'package:flutter/material.dart';

/// Goi y bieu tuong trong INFO (PROTOCOL §4) -> icon
IconData deviceIcon(String? icon) => switch (icon) {
      'relay' => Icons.power_settings_new,
      'heater' => Icons.local_fire_department,
      'sensor' => Icons.sensors,
      'pump' => Icons.water_drop,
      'light' => Icons.lightbulb,
      'motor' => Icons.settings_suggest,
      _ => Icons.memory,
    };
