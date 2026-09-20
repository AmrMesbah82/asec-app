/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: custom_button_sizing.dart
/// Purpose: Declares `ButtonSizing`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

// Objectives: Single source of truth for app-wide custom button sizing.
// Rule:
// - mobile  : width 38.sp
// - tablet  : width 135.sp
// - height  : always 38.sp
// - radius  : always 8.r
// - If the content (text + optional icon) needs more than the fixed width,
//   the button wraps its content with 12.sp horizontal padding instead.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ButtonSizing {
  ButtonSizing._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide < 600;

  /// Enforced button height.
  static double get height => 38.sp;

  /// Enforced border radius.
  static double get radius => 8.r;

  /// Horizontal padding used when the button wraps its content.
  static double get horizontalPadding => 12.sp;

  /// Size for icon-only buttons (always square, all devices).
  static double get iconButtonSize => 38.sp;

  /// Returns the fixed width for the current device (38.sp mobile /
  /// 135.sp tablet), or `null` when the content doesn't fit — in that
  /// case the button should size to its content with
  /// [horizontalPadding] on both sides.
  ///
  /// [fixedWidth] (ADDED 19/8/2026) overrides the device default for call
  /// sites pinned to a Figma spec rather than to the app-wide rule — e.g. the
  /// Form Builder home action row, where Figma (MESBAH / node 7444-37189)
  /// specifies Filter 100, Sort 100 and Create Form 150, not 135. Opt-in per
  /// call site: pass nothing and every other button in the app keeps 135.sp.
  /// An overridden width still yields to content that does not fit, exactly
  /// like the default does.
  static double? width(
    BuildContext context, {
    String title = '',
    TextStyle? textStyle,
    double extraContentWidth = 0,
    double? fixedWidth,
  }) {
    final double fixed = fixedWidth ?? (isMobile(context) ? 38.sp : 135.sp);
    if (title.trim().isEmpty) return fixed;

    final TextPainter painter = TextPainter(
      text: TextSpan(text: title, style: textStyle),
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    final double needed =
        painter.width + extraContentWidth + (2 * horizontalPadding);
    return needed > fixed ? null : fixed;
  }
}
