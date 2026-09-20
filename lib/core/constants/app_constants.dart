/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: app_constants.dart
/// Purpose: Declares `AppConstants` — app-wide sizing, timing and copy that is
///          not tied to any one feature.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';

abstract class AppConstants {
  AppConstants._();

  /// The design canvas every `.sp` / `.h` / `.w` value is relative to on a
  /// phone or tablet. The desktop window uses its own live size instead
  /// (see main.dart).
  static const Size designSize = Size(390, 844);

  /// English brand name. On screen use `S.of(context).appName`.
  static const String appName = 'ASEC';
  static const String appNameAr = 'ASEC';

  static String appNameFor(String languageCode) =>
      languageCode == 'ar' ? appNameAr : appName;

  /// THE ADMIN.
  ///
  /// One account runs this app, and it is this email. Everybody who registers
  /// is a member. Two places enforce it, and they must stay in step:
  ///
  ///   * here — the app gives this email the admin role when it registers,
  ///   * firestore.rules — `isAdminEmail()` refuses an admin profile written
  ///     by any other email, which is the boundary that actually matters
  ///     (this constant is only what the client believes).
  static const String adminEmail = 'adminamr@gmail.com';

  static bool isAdminEmail(String email) =>
      email.trim().toLowerCase() == adminEmail;

  /// How long the splash holds on a cold start (the floor, not the length).
  static const Duration splashDuration = Duration(milliseconds: 2000);

  static const double pagePadding = 16;
  static const double cardRadius = 16;
  static const double sectionGap = 20;

  /// Firebase Auth's own minimum.
  static const int minPasswordLength = 6;

  /// Max video accepted from the admin, in megabytes.
  static const int maxUploadMb = 500;

  /// Longest countdown the admin can set on a quiz, in minutes.
  static const int maxQuizMinutes = 600;

  /// Most options a multiple-choice question may have.
  static const int maxOptions = 6;
  static const int minOptions = 2;
}
