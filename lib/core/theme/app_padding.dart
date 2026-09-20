/// Module: core / theme
///
///*************************** FILE INFO ****************************///
/// File Name: app_padding.dart
/// Purpose: Declares `AppPadding` — the app's ONE horizontal padding.
/// Author: Manger Plus team
/// Created: 19/9/2026
///
/// THE RULE (19/9/2026)
/// --------------------
/// Every horizontal padding in the app is [AppPadding.h] — 12 design pixels,
/// scaled — on phone, tablet and desktop alike. Page gutters, card insets,
/// row padding, toolbar padding: all 12.
///
/// Before this the app carried a dozen different horizontal insets (8, 10,
/// 12, 14, 16, 18, 20, 24, 32, 40, 48), so a card's content started at a
/// different x on every screen and nothing lined up down the page. Vertical
/// padding is untouched — it is what gives each block its own rhythm.
///
/// Pass [h] (or the helpers) rather than a number.

import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract final class AppPadding {
  const AppPadding._();

  /// The horizontal padding, in DESIGN pixels. Use [h] to apply it.
  static const double horizontal = 12;

  /// THE horizontal padding, scaled. Every `horizontal:`, `left:`, `right:`,
  /// `start:` and `end:` in the app is this.
  static double get h => horizontal.sp;

  /// 12 each side, [vertical] top and bottom.
  static EdgeInsets symmetric({double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: h, vertical: vertical);

  /// 12 each side and nothing else — a page gutter.
  static EdgeInsets get sides => EdgeInsets.symmetric(horizontal: h);
}
