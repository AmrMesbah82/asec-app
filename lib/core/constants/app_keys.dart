/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: app_keys.dart
/// Purpose: Declares `AppKeys` — every GetStorage key used by the app, in one
///          place so no two features can collide.
/// Author: Manger Plus team
/// Created: 18/9/2026

abstract class AppKeys {
  AppKeys._();

  // ── Theme & locale ───────────────────────────────────────────────────────
  static const String darkMode = 'dark_mode';
  static const String language = 'language';
  static const String primaryColor = 'primary_color';
  static const String secondaryColor = 'secondary_color';
  static const String haptic = 'haptic';
  static const String font = 'font';
  static const String fontArabic = 'font_arabic';

  // ── Session ──────────────────────────────────────────────────────────────
  static const String savedEmail = 'saved_email';

  /// Parent app: which child was last selected.
  static const String selectedChild = 'selected_child';

  /// Debug only: lets a developer open the mobile apps on a desktop build
  /// (and the console on a phone) to test without a second device.
  static const String debugDeviceOverride = 'debug_device_override';
}
