/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: app_colors.dart
/// Purpose: Declares `AppColors`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

// Date: 29/9/2024
// By: Youssef Ashraf, Nada Mohammed, Mohammed Ashraf
// Last update: 29/9/2024
// Objectives: This file is responsible for providing the app colors that are used in the app.

import 'package:flutter/material.dart';

import './app_theme.dart';

abstract class AppColors {
  static Map<String, Color> currentThemeColors = AppTheme.lightThemeColors;

  // Theme-independent constant (avoids raw Colors.transparent in widgets, §12).
  static const Color transparent = Colors.transparent;

  /// Theme-independent disabled/inactive-state grey (was inline
  /// `Color(0xFFD9D9D9)` in custom_check_box.dart). Matches the light-theme
  /// barrierColor value but is kept separate since it's used for disabled
  /// buttons/controls, not modal barriers.
  static const Color disabledGrey = Color(0xFFD9D9D9);

  /// Theme-independent track colour of an off switch — the iOS system fill.
  /// Was inline `Color(0xFF787880)` in the settings cards (§12,
  /// CR-SKEL-SEMAIN-N23). Apply the platform's .16 opacity at the use site.
  static const Color switchTrackOff = Color(0xFF787880);

  /// Theme-independent neutral icon grey, was inline `Color(0xFF797979)` in
  /// the settings header menu (§12, CR-SKEL-SEMAIN-N23).
  static const Color neutralIconGrey = Color(0xFF797979);

  /// Light-mode fill behind a repeated inline field (skills, hobbies, the HR
  /// mobile forms). Was inline `Color(0xFFF6F6F6)` in eight places
  /// (§12, CR-SKEL-SE2-N17). Pair with [colorBlack] in dark mode, which is what
  /// every one of those call sites already did.
  static const Color fieldFillLight = Color(0xFFF6F6F6);

  /// The solid dark chip/button fill used by the "More" buttons on the social
  /// page. Was a raw `Colors.black` (§12, CR-SKEL-SE2-N17).
  static const Color chipDark = Color(0xFF000000);

  /// Request-status accents, theme-independent so an approved badge reads the
  /// same in both themes. Were inline `Color(0xFF34C759)` / `Color(0xffFF814A)`
  /// in details_request.dart (§12, CR-SKEL-SE6-N07).
  static const Color statusApproved = Color(0xFF34C759);
  static const Color statusPending = Color(0xFFFF814A);

  // ── Calendar event palette ─────────────────────────────────────────────
  /// One colour per calendar event source. Were 26 inline `Color(0xFF…)`
  /// literals inside `calendar_data_service.dart` — which is what pulled
  /// `package:flutter/material.dart` into the data layer
  /// (§12, CR-SKEL-CAL-N02-DATA / N11).
  ///
  /// Theme-independent on purpose: a Qiyas event must be the same grey in both
  /// themes, because the colour is the module's identity, not decoration.
  static const Color calendarEventQiyas = Color(0xFF9FADAF);
  static const Color calendarEventKnowledgeHub = Color(0xFF9C27B0);
  static const Color calendarEventServices = Color(0xFFCD7F32);

  /// The deep red of a locked account. Was an inline `Color(0xFFB02A37)`
  /// returned from a *domain* enum (§12, CR-SKEL-O3-N31).
  static const Color statusLocked = Color(0xFFB02A37);


  // ----------------- Black & White Colors -----------------
  static Color get pending => currentThemeColors['pending']!;
  static Color get black => currentThemeColors['black']!;
  static Color get blackShadow => currentThemeColors['blackShadow']!;
  static Color get secondaryBlack => currentThemeColors['secondaryBlack']!;
  static Color get white => currentThemeColors['white']!;
  static Color get whiteShadow => currentThemeColors['whiteShadow']!;
  static Color get darkWhite => currentThemeColors['darkWhite']!;
  static Color get darkWhiteShadow => currentThemeColors['darkWhiteShadow']!;
  static Color get oddRowColor => currentThemeColors['oddRowColor']!;
  static Color get evenRowColor => currentThemeColors['evenRowColor']!;
  static Color get fullBlack => currentThemeColors['fullBlack']!;
  static Color get blackButton => currentThemeColors['blackButton']!;

  static Color get block => currentThemeColors['block']!;
  static Color get darkBackGround => currentThemeColors['darkBackGround']!;
  static Color get warning => currentThemeColors['warning']!;
  static Color get greyBack => currentThemeColors['greyBack']!;
  static Color get barrierColor {
    final v = currentThemeColors['barrierColor'];
    if (v == null) {
    }
    return v ?? const Color(0xFFD9D9D9);
  }
  static Color get unBlock => currentThemeColors['unBlock']!;
  static Color get delete => currentThemeColors['delete']!;
  static Color get expiringSoon => currentThemeColors['expiringSoon']!;

  /// Inactive onboarding page-indicator dot (theme-aware).
  static Color get onboardingDotInactive =>
      currentThemeColors['onboardingDotInactive']!;
  static Color get differentGrey => currentThemeColors['differentGrey']!;
  static Color get whiteDark => currentThemeColors['whiteDark']!;
  static Color get lightRed => currentThemeColors['lightRed']!;

  // ----------------- Primary Colors -----------------

  static Color get primary => currentThemeColors['primary']!;
  static Color get secondaryPrimary => currentThemeColors['secondaryPrimary']!;
  // ----------------- Components Colors -----------------
  static Color get header => currentThemeColors['header']!;
  static Color get text => currentThemeColors['text']!;
  static Color get inputColor => currentThemeColors['inputColor']!;
  static Color get button => currentThemeColors['button']!;
  static Color get textButton => AppTheme.contrastColor();
  static Color get secondaryPrimaryText => AppTheme.secondaryPrimaryText();
  static Color get icon => currentThemeColors['icon']!;
  static Color get card => currentThemeColors['card']!;
  static Color get field => currentThemeColors['field']!;
  static Color get appBar => currentThemeColors['appBar']!;
  static Color get dropShadow => currentThemeColors['dropShadow']!;
  static Color get borderCard => currentThemeColors['borderCard']!;
  static Color get message => currentThemeColors['message']!;
  static Color get messageText => currentThemeColors['messageText']!;
  static Color get background => currentThemeColors['background']!;
  static Color get switchOff => currentThemeColors['switchOff']!;

  static Color get indicator => currentThemeColors['indicator']!;
  static Color get starredCard => currentThemeColors['starredCard']!;
  static Color get border => currentThemeColors['border']!;
  static Color get navyBlue => currentThemeColors['navyBlue']!;

  static Color get dialog => currentThemeColors['dialog']!;
  static Color get chatBackground => currentThemeColors['chatBackground']!;
  static Color get chatField => currentThemeColors['chatField']!;
  static Color get fieldBorder => currentThemeColors['fieldBorder']!;
  static Color get totalBlack => currentThemeColors['totalBlack']!;
  static Color get greyDark => currentThemeColors['greyDark']!;

  //
  // ----------------- Grey Colors -----------------
  static Color get grey => currentThemeColors['grey']!;
  static Color get lightGrey => currentThemeColors['lightGrey']!;
  static Color get moreLightGrey => currentThemeColors['moreLightGrey']!;
  static Color get mediumGrey => currentThemeColors['mediumGrey']!;
  static Color get darkGrey => currentThemeColors['darkGrey']!;
  static Color get lighterGrey => currentThemeColors['lighterGrey']!;
  static Color get darkerGrey => currentThemeColors['darkerGrey']!;
  static Color get greyIcon => currentThemeColors['greyIcon']!;
  static Color get drawerColor => currentThemeColors['drawerColor']!;
  static Color get lightPrimary => currentThemeColors['lightPrimary']!;

  // ----------------- Basic Colors -----------------
  static Color get base => currentThemeColors[
      'base']!; // *** anything white and converted to secondary black in dark mode ***
  static Color get inverseBase => currentThemeColors[
      'inverseBase']!; // *** anything secondary black and converted to white in dark mode ***

  // ----------------- Secondary Colors -----------------
  static Color get lightGreen => currentThemeColors['lightGreen']!;
  static Color get green => currentThemeColors['green']!;
  static Color get darkRed => currentThemeColors['darkRed']!;
  static Color get red => currentThemeColors['red']!;
  static Color get blue => currentThemeColors['blue']!;
  static Color get orange => currentThemeColors['orange']!;
  static Color get yellow => currentThemeColors['yellow']!;
  static Color get warming => currentThemeColors['warming']!;
  static Color get lightBlue => currentThemeColors['liteBlue']!;
  static Color get secondaryText => currentThemeColors['secondaryText']!;
  static Color get spanText => currentThemeColors['spanText']!;
  static Color get secondaryButton => currentThemeColors['secondaryButton']!;
  static Color get borderGrey => currentThemeColors['borderGrey']!;
  static Color get crimson => currentThemeColors['crimson']!;

  static Color get whiteDashboardTable =>
      currentThemeColors['whiteDashboardTable']!;
  static Color get darkDashboardTable =>
      currentThemeColors['darkDashboardTable']!;

  /// Create a list of colors to be used for the chart.
  static List<Color> colors = [
    AppColors.primary,
    AppColors.grey,
    AppColors.black,
    AppColors.secondaryPrimary,
  ];

  // ----------------- MyThemeData backward-compat aliases -----------------
  // These allow files that used to import MyThemeData but now import AppColors
  // to compile without changes. Values match MyThemeData exactly.

  /// Brand primary/action color — same as AppColors.signOut / barColor / bubbleColor
  static Color get signOut => currentThemeColors['primary']!;
  static Color get barColor => currentThemeColors['primary']!;
  static Color get bubbleColor => currentThemeColors['primary']!;
  static Color get mainColor => currentThemeColors['primary']!;
  static Color get primaryYellow => currentThemeColors['primary']!;

  /// Brand secondary color — same as AppColors.switchSettings / lightPrimary (secondary)
  static Color get switchSettings => currentThemeColors['secondaryPrimary']!;

  /// Fixed neutrals — theme-unaware (same in light and dark)
  static const Color colorBlack = Color(0xFF2D2D2D);
  static const Color colorWhite = Color(0xFFFFFFFF);
  static const Color colorGrey = Color(0xFF9E9E9E);
  static const Color colorGreyDark = Color(0xFF6F6F6F);
  static const Color mainBlack = Color(0xFF2D2D2D);
  static const Color offWhite = Color(0xFFF5F5F5);
  static const Color textfieldColor = Color.fromRGBO(246, 246, 246, 1);
  static const Color darkWhiteShadowDisabled = Color(0x9E9E9E9E);

  /// Theme-aware neutral aliases
  static Color get fieldBackGround => currentThemeColors['field']!;
  static Color get lightGreyBg => currentThemeColors['background']!;

  /// ThemeData forwarding — files using AppColors.lightTheme / darkTheme
  static ThemeData get lightTheme => AppTheme.lightTheme;
  static ThemeData get darkTheme => AppTheme.darkTheme;

  // ----------------- Full MyThemeData aliases (for complete removal) -----------------
  /// AppColors.action (was int primary/action, now a Color)
  static Color get action => currentThemeColors['primary']!;

  /// AppColors.colorWhiteDark
  static Color get colorWhiteDark => currentThemeColors['whiteDark']!;

  /// AppColors.colorLightGrey
  static Color get colorLightGrey => currentThemeColors['lightGrey']!;

  /// AppColors.colorRed
  static Color get colorRed => currentThemeColors['red']!;

  /// AppColors.colorTotalBlack
  static Color get colorTotalBlack => currentThemeColors['totalBlack']!;

  /// AppColors.colorGreydark (0xFFCCCCCC)
  static Color get colorGreydark => currentThemeColors['darkerGrey']!;

  /// AppColors.colorDarkGrey (0xFF797979)
  static const Color colorDarkGrey = Color(0xFF797979);

  /// Settings input background (dark mode) — 0xFF545454
  static const Color inputBackgroundDark = Color(0xFF545454);

  /// Invoices table zebra-stripe (light) — 0xFFF1F1F1
  static const Color tableRowLight = Color(0xFFF1F1F1);

  /// Invoices table zebra-stripe (dark) — 0xFF28282B
  static const Color tableRowDark = Color(0xFF28282B);

  /// AppColors.dark (0xFF4B4B4B)
  static Color get dark => currentThemeColors['greyDark']!;

  /// AppColors.dividerGrey (0xFFDBDCDD)
  static Color get dividerGrey => currentThemeColors['border']!;

  /// AppColors.dotBlack — colorBlack with 20% opacity
  static Color get dotBlack => const Color(0xFF2D2D2D).withOpacity(.2);

  /// AppColors.secondaryColor
  static Color get secondaryColor => currentThemeColors['secondaryPrimary']!;

  /// AppColors.textCal (0xFF19181A ≈ black)
  static Color get textCal => currentThemeColors['black']!;

  /// AppColors.textGrey (0xFF8D8D8D ≈ grey)
  static Color get textGrey => currentThemeColors['grey']!;

  /// AppColors.textdeactivecolor (0xFF797979 ≈ darkGrey)
  static Color get textdeactivecolor => currentThemeColors['darkGrey']!;

  /// AppColors.yellowColor (0xffFFCC00)
  static Color get yellowColor => currentThemeColors['yellow']!;

  // ----------------- Services dashboard palette (moved from ServicesColors) --
  // Named colours used by the services admin-dashboard widgets (§12 — no raw
  // Color(0xFF…) literals inside widgets). Kept theme-independent as the
  // originals were.

  // Pie/donut-chart palette (gold -> dark red gradient).
  static const Color chartGold = Color(0xFFFFD700);
  static const Color chartOrange = Color(0xFFFF9500);
  static const Color chartAmber = Color(0xFFD4780A);
  static const Color chartBrown = Color(0xFF8B5200);
  static const Color chartDarkRed = Color(0xFF730606);

  // Services dashboard table backgrounds (light / dark).
  static const Color tableLightBackground = Color(0xFFF7F8FA);
  static const Color tableDarkBackground = Color(0xFF1E1F24);

  // Disabled / neutral button background (services export widgets).
  static const Color disabledButton = Color(0xFFCCCCCC);

  // Mobile-dashboard chart palette (master mobile).
  static const Color chartGreen = Color(0xFF378309);
  static const Color chartYellow = Color(0xFFFFCC00);
  static const Color chartCrimson = Color(0xFF950E0E);
  static const Color chartGoldDeep = Color(0xFFE5C100);
  static const Color chartGoldPale = Color(0xFFE3D38C);
  static const Color chartGoldBright = Color(0xFFFFDE59);
  static const Color chartOlive = Color(0xFFA18A2D);
  static const Color chartAmberDeep = Color(0xFFE5B800);
  static const Color chartGreyOlive = Color(0xFF807B69);
  static const Color chartGrey = Color(0xFF8D8D8D);
  static const Color chartLightGrey = Color(0xFFCACACA);
  static const Color chartTaupe = Color(0xFF6B5650);
  static const Color chartMocha = Color(0xFF795548);
}
