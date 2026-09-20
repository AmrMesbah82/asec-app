/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: custom_appbar_mobile.dart
/// Purpose: Declares `CustomAppBarMobile`.
/// Author: Manger Plus team
/// Updated: 3/9/2026 - Ported from knowticed_plus, stripped of the module
///          registry / notification / company-cubit wiring that app needs.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/haptic_controller.dart';

/// The app bar every mobile page in this app uses.
///
/// Shape follows the knowticed mobile bar: flat (no elevation), scaffold-
/// coloured, title centred, an optional leading back chevron in a rounded
/// container, and a free-form action slot on the trailing side.
class CustomAppBarMobile extends StatelessWidget implements PreferredSizeWidget {
  /// Centre title. Pass [titleWidget] instead for anything richer than text.
  final String? title;
  final Widget? titleWidget;

  /// Shows the rounded back chevron. Defaults to whatever the navigator can
  /// actually pop, so a root tab page gets no stray back button.
  final bool? showBack;

  /// Overrides the default `Navigator.pop`.
  final VoidCallback? onBack;

  /// Trailing widgets (icons, a text button, …).
  final List<Widget> actions;

  /// Background — defaults to `AppColors.appBar`.
  final Color? backgroundColor;

  /// Optional 1px hairline under the bar.
  final bool showDivider;

  /// Extra widget pinned under the title row (a search field, a tab strip).
  final PreferredSizeWidget? bottom;

  const CustomAppBarMobile({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack,
    this.onBack,
    this.actions = const [],
    this.backgroundColor,
    this.showDivider = false,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(56.h + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final bool canPop = showBack ?? Navigator.of(context).canPop();

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.appBar,
        border: showDivider
            ? Border(bottom: BorderSide(color: AppColors.border, width: 1.w))
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56.h,
              child: Row(
                children: [
                  SizedBox(width: 12.w),
                  if (canPop)
                    _CircleIconButton(
                      assetPath: AppAssets.arrowBack,
                      onTap: () {
                        HapticController.low();
                        if (onBack != null) {
                          onBack!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    )
                  else
                    SizedBox(width: 36.sp),
                  Expanded(
                    child: Center(
                      child: titleWidget ??
                          Text(
                            title ?? '',
                            style: StyleText.fontSize16Weight600
                                .copyWith(color: AppColors.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    ),
                  ),
                  // Keeps the title optically centred when there are no
                  // actions: the leading slot is 36.sp wide, so the trailing
                  // side has to reserve the same when it is empty.
                  if (actions.isEmpty)
                    SizedBox(width: 36.sp)
                  else
                    Row(mainAxisSize: MainAxisSize.min, children: actions),
                  SizedBox(width: 12.w),
                ],
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

/// The rounded 36x36 icon button used by the bar's leading and action slots.
class _CircleIconButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;

  const _CircleIconButton({required this.assetPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36.sp,
        height: 36.sp,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.buttonR,
        ),
        child: CustomSvgImage(
          assetPath: assetPath,
          width: 16.sp,
          height: 16.sp,
          color: AppColors.text,
        ),
      ),
    );
  }
}

/// Public twin of [_CircleIconButton] so pages can put matching buttons in
/// [CustomAppBarMobile.actions] without redefining the style.
class AppBarActionButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;
  final Color? iconColor;

  const AppBarActionButton({
    super.key,
    required this.assetPath,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: AppPadding.h),
      child: GestureDetector(
        onTap: () {
          HapticController.low();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36.sp,
          height: 36.sp,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.buttonR,
          ),
          child: CustomSvgImage(
            assetPath: assetPath,
            width: 18.sp,
            height: 18.sp,
            color: iconColor ?? AppColors.text,
          ),
        ),
      ),
    );
  }
}
