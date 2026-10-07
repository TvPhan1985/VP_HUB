import 'package:flutter/material.dart';

/// Mau va kich thuoc dung chung (design token). Widget khong tu dat mau trang thai rieng.
class Vp {
  static const seed = Color(0xFF00796B);

  /// Bo goc the
  static const double radius = 16;

  /// Le trang hai ben noi dung
  static const double pad = 12;

  /// Khoang cach giua cac the
  static const double gap = 8;

  static const double tileNumber = 28;
  static const double miniNumber = 18;
  static const double heroTitle = 22;

  static bool _dark(ColorScheme cs) => cs.brightness == Brightness.dark;

  /// Trang thai tot / dang bat
  static Color ok(ColorScheme cs) => _dark(cs) ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
  static Color okContainer(ColorScheme cs) => _dark(cs) ? const Color(0xFF1B5E20) : const Color(0xFFC8E6C9);
  static Color onOkContainer(ColorScheme cs) => _dark(cs) ? const Color(0xFFC8E6C9) : const Color(0xFF1B5E20);

  /// Nen SnackBar bao thanh cong (chu trang)
  static const Color okSolid = Color(0xFF2E7D32);

  /// Dang cho (ket noi lai)
  static Color busy(ColorScheme cs) => _dark(cs) ? const Color(0xFFFFD54F) : const Color(0xFFF57F17);

  /// Loi / canh bao
  static Color warn(ColorScheme cs) => cs.error;

  /// Khong hoat dong
  static Color idle(ColorScheme cs) => cs.outline;
}

ThemeData vpHubTheme(Brightness b) => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Vp.seed, brightness: b),
      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(vertical: Vp.gap / 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Vp.radius)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
