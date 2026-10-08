import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import '../core/schema_cache.dart';
import '../l10n/strings.dart';

/// Mau va kich thuoc dung chung (design token), theo quy chuan giao dien
/// "Top Navigation & Theme System" (docs/, muc 5-7). Widget khong tu dat mau trang thai rieng.
class Vp {
  // ----- Che do sang -----
  static const lightBg = Color(0xFFF8F9FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF1E293B);
  static const lightSub = Color(0xFF64748B);
  static const lightAccent = Color(0xFF0284C7);
  static const lightOk = Color(0xFF15803D);

  // ----- Che do toi (khong dung den thuan / trang thuan) -----
  static const darkBg = Color(0xFF0F172A);
  static const darkCard = Color(0xFF1E293B);
  static const darkText = Color(0xFFF1F5F9);
  static const darkSub = Color(0xFF94A3B8);
  static const darkAccent = Color(0xFF38BDF8);
  static const darkOk = Color(0xFF22C55E);

  // ----- Thanh dau man hinh, thanh tab, menu he thong: luon nen xam dam -----
  static const bar = Color(0xFF0F172A);
  static const barTabs = Color(0xFF1E293B);
  static const onBar = Color(0xFFF1F5F9);
  static const onBarSub = Color(0xFF94A3B8);
  static const barAccent = Color(0xFF38BDF8);
  static const barOk = Color(0xFF22C55E);
  static const barCaution = Color(0xFFFDE047);
  static const barStop = Color(0xFFFCA5A5);
  static const barLine = Color(0xFF334155);

  /// Chieu cao Top App Bar
  static const double barHeight = 56;

  /// Bo goc the
  static const double radius = 12;

  /// Le trang hai ben noi dung
  static const double pad = 12;

  /// Khoang cach giua cac the
  static const double gap = 8;

  static const double bigNumber = 40;
  static const double tileNumber = 24;
  static const double miniNumber = 18;
  static const double heroTitle = 18;

  static bool _dark(ColorScheme cs) => cs.brightness == Brightness.dark;

  /// Trang thai tot / dang bat
  static Color ok(ColorScheme cs) => _dark(cs) ? darkOk : lightOk;
  static Color okContainer(ColorScheme cs) => _dark(cs) ? const Color(0xFF052E16) : const Color(0xFFDCFCE7);
  static Color onOkContainer(ColorScheme cs) => _dark(cs) ? const Color(0xFF86EFAC) : const Color(0xFF166534);

  /// Nen SnackBar bao thanh cong (chu trang)
  static const Color okSolid = Color(0xFF15803D);

  /// Trang thai canh bao (vang): dang cho, ghi chu, thay doi chua luu
  static Color caution(ColorScheme cs) => cs.tertiary;
  static Color cautionContainer(ColorScheme cs) => cs.tertiaryContainer;

  /// Dang cho (ket noi lai)
  static Color busy(ColorScheme cs) => cs.tertiary;

  /// Loi / dung khan (do)
  static Color warn(ColorScheme cs) => cs.error;

  /// Khong hoat dong
  static Color idle(ColorScheme cs) => cs.outline;

  /// Nen khoi so noi bat (the so lon, o so)
  static Color well(ColorScheme cs) => cs.surfaceContainer;
}

/// Mau cua thanh dau man hinh, thanh tab va menu he thong; khac nhau theo linh vuc cua thiet bi
class VpBars extends ThemeExtension<VpBars> {
  final Color bar, tabs, accent, sub, line, ok, avatar, onAvatar;
  const VpBars({
    required this.bar,
    required this.tabs,
    required this.accent,
    required this.sub,
    required this.line,
    required this.ok,
    required this.avatar,
    required this.onAvatar,
  });

  /// Cong nghiep (Factory SCADA): xam dam + xanh duong
  static const industrial = VpBars(
    bar: Vp.bar,
    tabs: Vp.barTabs,
    accent: Vp.barAccent,
    sub: Vp.onBarSub,
    line: Vp.barLine,
    ok: Vp.barOk,
    avatar: Vp.lightAccent,
    onAvatar: Colors.white,
  );

  /// Nong nghiep (Smart Farm): xanh la dam + xanh la sang
  static const agri = VpBars(
    bar: Color(0xFF14532D),
    tabs: Color(0xFF166534),
    accent: Color(0xFF86EFAC),
    sub: Color(0xFFBBF7D0),
    line: Color(0xFF15803D),
    ok: Color(0xFF86EFAC),
    avatar: Color(0xFF22C55E),
    onAvatar: Color(0xFF14532D),
  );

  static VpBars of(BuildContext context) => Theme.of(context).extension<VpBars>() ?? industrial;

  @override
  VpBars copyWith() => this;

  @override
  VpBars lerp(ThemeExtension<VpBars>? other, double t) => t < 0.5 || other is! VpBars ? this : other;
}

ColorScheme _scheme(Brightness b, bool agri) {
  final dark = b == Brightness.dark;
  // Mau nhan: xanh duong (cong nghiep) hoac xanh la (nong nghiep)
  final primary = agri ? (dark ? Vp.darkOk : Vp.lightOk) : (dark ? Vp.darkAccent : Vp.lightAccent);
  final container = agri
      ? (dark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
      : (dark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE));
  final onContainer = agri
      ? (dark ? const Color(0xFFBBF7D0) : const Color(0xFF166534))
      : (dark ? const Color(0xFFBAE6FD) : const Color(0xFF075985));
  return ColorScheme.fromSeed(seedColor: Vp.lightAccent, brightness: b).copyWith(
    primary: primary,
    onPrimary: dark ? Vp.darkBg : Vp.lightCard,
    primaryContainer: container,
    onPrimaryContainer: onContainer,
    secondary: dark ? Vp.darkSub : Vp.lightSub,
    onSecondary: dark ? Vp.darkBg : Vp.lightCard,
    secondaryContainer: container,
    onSecondaryContainer: onContainer,
    // Canh bao: nen vang nhat / chu nau (sang), nen nau dam / chu vang (toi)
    tertiary: dark ? const Color(0xFFFDE047) : const Color(0xFF92400E),
    onTertiary: dark ? const Color(0xFF451A03) : Vp.lightCard,
    tertiaryContainer: dark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
    onTertiaryContainer: dark ? const Color(0xFFFDE047) : const Color(0xFF92400E),
    // Dung khan
    error: dark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
    onError: dark ? const Color(0xFF450A0A) : Vp.lightCard,
    errorContainer: dark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
    onErrorContainer: dark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
    surface: dark ? Vp.darkCard : Vp.lightCard,
    onSurface: dark ? Vp.darkText : Vp.lightText,
    onSurfaceVariant: dark ? Vp.darkSub : Vp.lightSub,
    surfaceDim: dark ? Vp.darkBg : const Color(0xFFE2E8F0),
    surfaceBright: dark ? const Color(0xFF334155) : Vp.lightCard,
    surfaceContainerLowest: dark ? Vp.darkBg : Vp.lightCard,
    surfaceContainerLow: dark ? const Color(0xFF172033) : Vp.lightBg,
    surfaceContainer: dark ? const Color(0xFF273449) : const Color(0xFFF1F5F9),
    surfaceContainerHigh: dark ? const Color(0xFF2B3A52) : const Color(0xFFF1F5F9),
    surfaceContainerHighest: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    outline: dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
    outlineVariant: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    surfaceTint: Colors.transparent,
    scrim: Colors.black,
  );
}

final Map<String, ThemeData> _themes = {};

/// Giao dien cua app theo che do sang/toi va linh vuc cua thiet bi ('ind' | 'agri', PROTOCOL §4 `dom`)
ThemeData vpHubTheme(Brightness b, [String domain = 'ind']) =>
    _themes['${b.name}/$domain'] ??= _buildTheme(b, domain == 'agri');

ThemeData _buildTheme(Brightness b, bool agri) {
  final cs = _scheme(b, agri);
  final dark = b == Brightness.dark;
  final bars = agri ? VpBars.agri : VpBars.industrial;
  return ThemeData(
    extensions: [bars],
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: dark ? Vp.darkBg : Vp.lightBg,
    appBarTheme: AppBarTheme(
      backgroundColor: bars.bar,
      foregroundColor: Vp.onBar,
      toolbarHeight: Vp.barHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      titleTextStyle: const TextStyle(color: Vp.onBar, fontSize: 18, fontWeight: FontWeight.w600),
      iconTheme: const IconThemeData(color: Vp.onBar),
      actionsIconTheme: const IconThemeData(color: Vp.onBar),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: bars.accent,
      unselectedLabelColor: bars.sub,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.6),
      indicatorSize: TabBarIndicatorSize.tab,
      // Tab dang chon: nen xanh mo + gach chan
      indicator: BoxDecoration(
        color: bars.accent.withValues(alpha: 0.15),
        border: Border(bottom: BorderSide(color: bars.accent, width: 3)),
      ),
      dividerColor: Colors.transparent,
      labelPadding: const EdgeInsets.symmetric(horizontal: 18),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: bars.bar,
      // Lop phu nen khi mo menu: rgba(0, 0, 0, 0.5)
      scrimColor: const Color(0x80000000),
      elevation: 0,
      shape: const RoundedRectangleBorder(),
    ),
    cardTheme: CardThemeData(
      color: cs.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: Vp.gap / 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Vp.radius),
        side: BorderSide(color: cs.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(color: cs.outlineVariant, space: 1, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary, linearTrackColor: cs.outlineVariant),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Cai dat cua app: che do giao dien (Theo he thong / Sang / Toi) va ngon ngu (Anh / Viet).
/// Luu trong kho cua app; doi la ap dung ngay, khong can mo lai app.
class ThemeController extends ChangeNotifier {
  static const _key = 'theme';
  static const _langKey = 'lang';
  final KvStore store;
  ThemeMode _mode;

  ThemeController(this.store) : _mode = _parse(store.getString(_key)) {
    Lang.code = store.getString(_langKey) == Lang.vi ? Lang.vi : Lang.en;
  }

  String get lang => Lang.code;

  Future<void> setLang(String code) async {
    if (code == Lang.code) return;
    Lang.code = code == Lang.vi ? Lang.vi : Lang.en;
    notifyListeners();
    // Chu nam trong nhieu widget khong nghe controller nay: ve lai ca cay
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    await store.setString(_langKey, Lang.code);
  }

  static ThemeMode _parse(String? s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode m) async {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
    await store.setString(_key, m.name);
  }
}

/// Dua ThemeController xuong cay widget (menu he thong dung de doi giao dien)
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({super.key, required ThemeController controller, required super.child})
      : super(notifier: controller);

  static ThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;
}
