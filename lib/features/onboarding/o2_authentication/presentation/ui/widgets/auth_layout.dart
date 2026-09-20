/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: auth_layout.dart
/// Purpose: Declares `AuthLayout` and `AuthLanguageToggle` — the responsive
///          frame the sign-in and register forms sit in.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/112-powered_by_footer.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/theme_controller.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/ui/widgets/brand_mark.dart';
import 'package:asec/generated/l10n.dart';

/// One frame, two shapes.
///
/// WIDTH DECIDES, NOT THE PLATFORM. At [splitWidth] and above the screen is a
/// brand panel BESIDE the form; below it the gradient header sits above the
/// form instead. A macOS window dragged down to phone width gets the phone
/// layout, because at 400pt the two-panel layout is two squeezed columns.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.form,
    required this.illustration,
  });

  /// The card of fields — sign-in or register.
  final Widget form;

  /// The SVG on the brand side (see [AppAssets]).
  final String illustration;

  /// From this width on, the layout splits in two.
  static const double splitWidth = 900;

  static bool isSplit(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= splitWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isSplit(context) ? _split(context) : _stacked(context),
    );
  }

  // ── Desktop / wide window: brand panel | form ────────────────────────────

  Widget _split(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.h,
              vertical: 48.sp,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const BrandMark(size: 52, onDark: true),
                const Spacer(),
                Center(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: 420.w, maxHeight: 340.h),
                    child: CustomSvgImage.natural(assetPath: illustration),
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  S.of(context).heroTitle,
                  style: StyleText.fontSize28Weight600
                      .copyWith(color: Colors.white),
                ),
                SizedBox(height: 8.h),
                Text(
                  S.of(context).heroSubtitle,
                  style: StyleText.fontSize15Weight400
                      .copyWith(color: Colors.white70),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Stack(
            children: <Widget>[
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppPadding.h,
                    vertical: 40.sp,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 420.w),
                    child: form,
                  ),
                ),
              ),
              PositionedDirectional(
                top: 20.h,
                end: 20,
                child: const AuthLanguageToggle(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Phone / tablet: gradient header over the form ────────────────────────

  Widget _stacked(BuildContext context) {
    // THE LAST LINE HAS TO BE REACHABLE. The system inset is added to the
    // bottom of the scroll padding so the footer can always be scrolled clear
    // of the gesture bar. `viewPadding`, not `padding`: with the keyboard open
    // the Scaffold has already consumed the inset, and `padding` would then
    // read zero.
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset + 12.h),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding:
                EdgeInsets.fromLTRB(AppPadding.h, 56.h, AppPadding.h, 36.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(36.r)),
            ),
            child: Column(
              children: <Widget>[
                const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AuthLanguageToggle(onDark: true),
                ),
                const BrandMark(size: 64, vertical: true, onDark: true),
                SizedBox(height: 20.h),
                SizedBox(
                  height: 140.h,
                  child: CustomSvgImage.natural(assetPath: illustration),
                ),
              ],
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 480.w),
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(AppPadding.h, 24.h, AppPadding.h, 28.h),
                child: form,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EN | ع — switches the whole app's language.
class AuthLanguageToggle extends StatelessWidget {
  const AuthLanguageToggle({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.to;
    final Color color = onDark ? Colors.white : AppColors.text;
    return Obx(
      () => TextButton.icon(
        onPressed: theme.toggleLanguage,
        icon: AppIcon(Icons.translate_rounded, color: color, size: 18.sp),
        label: Text(
          theme.languageCode.value == 'ar' ? 'English' : 'العربية',
          style: StyleText.fontSize13Weight600.copyWith(color: color),
        ),
      ),
    );
  }
}

/// The "Powered by" line every auth screen ends with.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: const PoweredByFooter(),
      );
}
