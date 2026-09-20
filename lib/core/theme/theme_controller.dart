/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: theme_controller.dart
/// Purpose: Declares `ThemeController` — the single owner of dark mode,
///          locale and brand colours for the whole app.
/// Author: Manger Plus team
/// Updated: 3/9/2026 - Initial port from knowticed_plus.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/constants/app_keys.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';

/// Owns every piece of "how the app looks" state that outlives a screen:
/// dark mode, the active locale and the two branding colours.
///
/// Same contract as the knowticed_plus controller: mutate through the
/// controller, never through [AppTheme] directly, so the palette swap and the
/// `Get.forceAppUpdate()` that repaints the tree always happen together.
class ThemeController extends GetxController {
  static ThemeController get to => Get.find<ThemeController>();

  final GetStorage _storage = GetStorage();

  final RxBool isDarkMode = false.obs;
  final RxString languageCode = 'en'.obs;
  /// The colours the app ships with. Named so "reset" and "first run" cannot
  /// drift apart, and so the two literals live in exactly one place.
  static const Color defaultPrimary = Color(0xff6C63FF);
  static const Color defaultSecondary = Color(0xff4B45C6);

  final Rx<Color> primaryColor = defaultPrimary.obs;
  final Rx<Color> secondaryColor = defaultSecondary.obs;

  @override
  void onInit() {
    super.onInit();
    loadFromStorage();
  }

  /// Reads the persisted preferences and pushes them into [AppTheme].
  /// Call this once before `runApp` (see `main.dart`) so the very first frame
  /// is already painted in the user's theme instead of flashing the default.
  void loadFromStorage() {
    isDarkMode.value = _storage.read(AppKeys.darkMode) ?? false;
    languageCode.value = _storage.read(AppKeys.language) ?? 'en';

    final int? storedPrimary = _storage.read(AppKeys.primaryColor);
    final int? storedSecondary = _storage.read(AppKeys.secondaryColor);
    if (storedPrimary != null) primaryColor.value = Color(storedPrimary);
    if (storedSecondary != null) secondaryColor.value = Color(storedSecondary);

    // Set the palette directly rather than through AppTheme.initTheme: that
    // path ends in Get.forceAppUpdate(), and this runs before runApp, when
    // there is no element tree to reassemble.
    AppTheme.isDark = isDarkMode.value;
    AppTheme.lightThemeColors['primary'] = primaryColor.value;
    AppTheme.lightThemeColors['secondaryPrimary'] = secondaryColor.value;
    AppTheme.darkThemeColors['primary'] = primaryColor.value;
    AppTheme.darkThemeColors['secondaryPrimary'] = secondaryColor.value;
    AppColors.currentThemeColors = isDarkMode.value
        ? AppTheme.darkThemeColors
        : AppTheme.lightThemeColors;
  }

  // ── Dark mode ────────────────────────────────────────────────────────────

  void toggleDarkMode() => setDarkMode(!isDarkMode.value);

  void setDarkMode(bool value) {
    isDarkMode.value = value;
    _storage.write(AppKeys.darkMode, value);
    AppTheme.isDark = value;
    AppTheme.setCurrentThemeColors();
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    update();
  }

  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  // ── Locale ───────────────────────────────────────────────────────────────

  void toggleLanguage() => setLanguage(languageCode.value == 'en' ? 'ar' : 'en');

  void setLanguage(String code) {
    languageCode.value = code;
    _storage.write(AppKeys.language, code);
    Get.updateLocale(Locale(code));
    update();
  }

  bool get isArabic => languageCode.value == 'ar';

  // ── Branding ─────────────────────────────────────────────────────────────

  /// Swaps the brand pair in both palettes at once. Everything reading
  /// `AppColors.primary` / `AppColors.secondaryPrimary` follows on the next
  /// frame — which is every custom widget in `core/custom`.
  void setBrandingColors(Color primary, Color secondary) {
    primaryColor.value = primary;
    secondaryColor.value = secondary;
    _storage.write(AppKeys.primaryColor, primary.value);
    _storage.write(AppKeys.secondaryColor, secondary.value);
    AppTheme.interfaceUpdateBrandingColors(primary, secondary);
    update();
  }

  /// Back to the shipped pair. Writes them like any other choice rather than
  /// clearing the keys, so "reset" survives a restart the same way a pick does
  /// — clearing would silently re-apply whatever a future release ships.
  void resetBrandingColors() =>
      setBrandingColors(defaultPrimary, defaultSecondary);
}
