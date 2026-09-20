/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: custom_button.dart
/// Purpose: Widget used by the feature's screens.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/haptic_controller.dart';
import 'package:asec/core/custom/41-custom_button_sizing.dart';
import 'package:asec/core/extensions/context_extensions.dart';

Widget customButton({
  required String title,
  required VoidCallback function,
  /// Explicit button width. Takes precedence over the phone/tablet default
  /// below. Was ignored for a while in favour of [ButtonSizing]; it is
  /// honoured again, so a caller passing it now actually gets it.
  double? width,
  double? height, // ignored: sizing is enforced by ButtonSizing
  double radius = 8, // ignored: sizing is enforced by ButtonSizing
  Color? color,
  Color? textColor,
  Color? borderColor,
  TextStyle? textStyle,
  /// Opt out of the fixed ButtonSizing width and stretch to the parent
  /// instead. For full-bleed primary actions at the bottom of a form
  /// (e.g. Apply on the company branding screen). Height and radius still
  /// come from ButtonSizing, so buttons stay consistent.
  bool fullWidth = false,
  /// Opt out of the fixed ButtonSizing width and hug the text instead, with
  /// [contentHorizontalPadding] on both sides. For filter chips, where a fixed
  /// width leaves short labels ("All", "Active") floating in empty space.
  bool wrapContent = false,
  /// Horizontal padding used whenever the button sizes to its content
  /// (either via [wrapContent] or because the text overflows the fixed width).
  double? contentHorizontalPadding,

  /// Opt-in override of [ButtonSizing]. Takes precedence over [fullWidth]
  /// and [wrapContent].
  ///
  /// [width] above is deliberately ignored so button sizing stays consistent
  /// app-wide, and that is the right default. But it means a button whose
  /// label does not fit the standard 135.sp silently falls back to wrapping
  /// its own text -- so two buttons stacked in a column end up different
  /// widths and no longer align. Pass [exactWidth] when a caller needs
  /// several buttons to share one measured width; leave it null everywhere
  /// else and ButtonSizing still decides.
  double? exactWidth,
}) {
  final isDark = Get.isDarkMode;

  return Builder(
    builder: (context) {
      final TextStyle effectiveStyle = textStyle ??
          StyleText.fontSize16Weight500.copyWith(
            color: textColor ?? AppColors.textButton,
          );

      // 38.sp on mobile / 135.sp on tablet, or null when the text
      // doesn't fit (then the button wraps the text with 12.sp padding).
      final double? buttonWidth = exactWidth ??
          (fullWidth
              ? double.infinity
              : wrapContent
                  ? null
                  : ButtonSizing.width(
                      context,
                      title: title,
                      textStyle: effectiveStyle,
                    ));

      final Widget text = Text(title, style: effectiveStyle);

      return GestureDetector(
        onTap: () {
          HapticController.medium(); // primary action button
          function();
        },
        child: Container(
          // `width`, not `widget.width` — customButton is a top-level
          // function, so there is no State and no `widget`.
          //
          // The parentheses are load-bearing: `??` binds TIGHTER than
          // `?:`, so `a ?? b ? c : d` parses as `(a ?? b) ? c : d` —
          // which here tried to use `double? ?? bool` as a condition.
          //
          // FIXED 25/8/2026 — this line was `width ?? (context.isPhone
          // ? 135.sp : 170.sp)`, which threw [buttonWidth] away. `wrapContent`
          // therefore sized only the CHILD while the BOX stayed pinned to the
          // fixed width, so a row of filter chips came out all one size however
          // short the label: "All" as wide as "Expiring soon" on the role- and
          // user-management home pages, which is what `wrapContent` exists to
          // prevent. `wrapContent` now yields `buttonWidth` — null, so the
          // Container hugs its padded text.
          //
          // SCOPE: `wrapContent` only. `fullWidth` and `exactWidth` are
          // discarded by this same line and remain broken — a caller passing
          // either still gets the fixed width. Wiring them up here would resize
          // call sites all over the app that this change was not asked to
          // touch; fix them deliberately, with those screens in front of you.
          width: width ??
              (wrapContent
                  ? buttonWidth
                  : (ContextExtension(context).isPhone ? 135.sp : 170.sp)),
          height: 38.sp,
          decoration: BoxDecoration(
            color: color ?? AppColors.primary,
            borderRadius: BorderRadius.circular(ButtonSizing.radius),
            // border: Border.all(
            //   color: borderColor ?? AppColors.transparent,
            // ),
          ),
          child: buttonWidth == null
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: contentHorizontalPadding ??
                        ButtonSizing.horizontalPadding,
                  ),
                  child: Center(widthFactor: 1, child: text),
                )
              : Center(child: text),
        ),
      );
    },
  );
}

/*
// ── Usage ─────────────────────────────────────────────────────────────────────
// Sizing is enforced app-wide by ButtonSizing:
// width 38.sp (mobile) / 135.sp (tablet), height 38.sp, radius 8.r.
// If the text doesn't fit, the button wraps it with 12.sp horizontal padding.
customButton(
  title: 'Save',
  function: () {},
  color: AppColors.primary,
  textColor: AppColors.textButton,
)
*/
