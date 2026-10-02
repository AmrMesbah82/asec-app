/// Colours and type taken from asecbim.com (WordPress / Elementor):
///   buttons  #DD183B   headings red #F3050C   links blue #256EE5
///   navy     #102D5E   body text #33373D      muted #69727D
/// The site uses "DIN Next LT Arabic", which is a paid font; Cairo is the
/// closest free Arabic geometric sans and is already in the ASEC app.
///
/// LIGHT AND DARK. The brand colours (red, blue, …) never change. The
/// NEUTRALS — page, card, text, borders — come from a [WebPalette]:
///   * the public site always uses [WebPalette.light];
///   * inside the ASEC app, the "Website" tab builds one from the app's own
///     colours on every build (web_control_page.dart), so the panel follows
///     the app's light / dark switch and looks like the rest of the app.
/// That is why the neutrals are getters and never `const`.
library;

import 'package:flutter/material.dart';

class WebPalette {
  const WebPalette({
    required this.isDark,
    required this.page,
    required this.card,
    required this.surface,
    required this.border,
    required this.text,
    required this.heading,
    required this.muted,
  });

  final bool isDark;

  /// Behind everything (the panel's grey page).
  final Color page;

  /// Cards, menus, dialogs, app bars.
  final Color card;

  /// A slightly raised fill: placeholders, chips, input backgrounds.
  final Color surface;
  final Color border;

  /// Body text.
  final Color text;

  /// Titles and strong text (navy on light).
  final Color heading;

  /// Secondary text, hints.
  final Color muted;

  static const WebPalette light = WebPalette(
    isDark: false,
    page: Color(0xFFF3F5F9),
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFF6F7F9),
    border: Color(0xFFE6E8EC),
    text: Color(0xFF33373D),
    heading: Color(0xFF102D5E),
    muted: Color(0xFF69727D),
  );

  static const WebPalette dark = WebPalette(
    isDark: true,
    page: Color(0xFF10151D),
    card: Color(0xFF19202B),
    surface: Color(0xFF222B38),
    border: Color(0xFF2E3847),
    text: Color(0xFFE3E7EE),
    heading: Color(0xFFF2F5FA),
    muted: Color(0xFF9AA4B2),
  );
}

abstract final class WebColors {
  /// The neutrals in use. Set by the host before building (see top).
  static WebPalette palette = WebPalette.light;

  static bool get isDark => palette.isDark;

  // ── Brand: the same in light and dark ──────────────────────────────────
  static const Color red = Color(0xFFDD183B);
  static const Color redBright = Color(0xFFF3050C);
  static const Color blue = Color(0xFF256EE5);
  static const Color success = Color(0xFF1E9E5A);
  static const Color warning = Color(0xFFE08A00);
  static const Color black = Color(0xFF000000);

  /// Pure white — text and icons ON a brand colour, or on a photo.
  static const Color white = Color(0xFFFFFFFF);

  // ── Neutrals: follow [palette] ─────────────────────────────────────────
  static Color get navy => palette.heading;
  static Color get ink => palette.text;
  static Color get muted => palette.muted;
  static Color get card => palette.card;
  static Color get surface => palette.surface;
  static Color get border => palette.border;
  static Color get adminBg => palette.page;

  /// The stand-alone web panel's dark side menu.
  static const Color adminSide = Color(0xFF0B1B38);
}

abstract final class WebTheme {
  /// The public site, and the stand-alone web panel.
  static ThemeData get light => of(WebPalette.light);

  static ThemeData of(WebPalette p) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: WebColors.red,
      brightness: p.isDark ? Brightness.dark : Brightness.light,
      primary: WebColors.red,
      onPrimary: WebColors.white,
      secondary: p.isDark ? WebColors.blue : const Color(0xFF102D5E),
      surface: p.card,
      onSurface: p.text,
      outline: p.border,
    );
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: p.border),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: p.isDark ? Brightness.dark : Brightness.light,
      fontFamily: 'Cairo',
      colorScheme: scheme,
      scaffoldBackgroundColor: p.card,
      canvasColor: p.card,
      iconTheme: IconThemeData(color: p.text),
      textTheme: const TextTheme().apply(bodyColor: p.text, displayColor: p.text),
      appBarTheme: AppBarTheme(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.heading,
        iconTheme: IconThemeData(color: p.heading),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.isDark ? p.surface : p.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: p.muted),
        labelStyle: TextStyle(color: p.muted),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: WebColors.red, width: 1.4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WebColors.red,
          foregroundColor: WebColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: WebColors.red,
          foregroundColor: WebColors.white,
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.heading,
          side: BorderSide(color: p.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.isDark ? p.heading : const Color(0xFF102D5E),
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: p.heading),
        contentTextStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: p.text),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(fontFamily: 'Cairo', color: p.text),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        side: BorderSide(color: p.border),
        labelStyle: TextStyle(fontFamily: 'Cairo', color: p.text),
      ),
      listTileTheme: ListTileThemeData(textColor: p.text, iconColor: p.text),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected) ? WebColors.white : p.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected) ? WebColors.red : p.surface,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected) ? WebColors.red : p.border,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border),
        ),
      ),
    );
  }
}
