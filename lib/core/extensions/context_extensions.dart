/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: context_extensions.dart
/// Purpose: Declares `ContextExtension`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isTablet => MediaQuery.of(this).size.shortestSide >= 600;
  // alias used by some widgets
  bool get isTablett => MediaQuery.of(this).size.shortestSide >= 600;

  /// Active language code, read from [Localizations] rather than GetX.
  ///
  /// Falls back to `en` when there is no [Localizations] ancestor (which only
  /// happens above `MaterialApp`), matching the previous GetX behaviour where
  /// an unset locale did not match `'ar'`.
  String get languageCode =>
      Localizations.maybeLocaleOf(this)?.languageCode ?? 'en';

  /// `true` when the app is displaying Arabic.
  bool get isArabic => languageCode == 'ar';

  /// `true` when the app is displaying English. The app ships `en` and `ar`
  /// only, so this is the complement of [isArabic].
  bool get isEnglish => !isArabic;

  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;
  bool get isPhone => MediaQuery.of(this).size.shortestSide < 600;

  /// Wide-and-landscape layout check.
  ///
  /// NOTE: this deliberately keys off `width >= 600`, NOT `isTablet`
  /// (`shortestSide >= 600`). They are not equivalent — a phone held in
  /// landscape (e.g. 812x375) has width 812 but shortestSide 375, so it counts
  /// as `isTabletLandscape` while failing `isTablet`. This preserves the exact
  /// behaviour of the per-file `isTabletLandscape(context)` helpers that are
  /// duplicated across the services, roles and settings modules.
  bool get isTabletLandscape => screenWidth >= 600 && isLandscape;

  /// Pops the nearest navigator, optionally returning [result].
  ///
  /// Ported from the form_builder project, whose module calls `context.pop()`
  /// and `context.popToFirst()` instead of using [Navigator] directly.
  void pop<T extends Object?>([T? result]) => Navigator.of(this).pop<T>(result);

  /// Pops the nearest navigator until the first route.
  void popToFirst() => Navigator.of(this).popUntil((route) => route.isFirst);
}

/// Navigation helper used across the form builder module.
///
/// Pushes a named route onto the nearest [Navigator] — the form module's
/// nested navigator when called from inside it — matching the call style
/// `context.FormNavigateTo(Routes.someScreen, arguments: model)`.
///
/// Ported from the form_builder project. The capitalised method name is not
/// Dart convention but is kept so the module's call sites are unchanged.
// ignore_for_file: non_constant_identifier_names
extension FormNavigationExtension on BuildContext {
  Future<T?> FormNavigateTo<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }
}

