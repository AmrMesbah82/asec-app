/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 9-filter_tab_with_container.dart
/// Purpose: Declares `CustomSegmentedTabs`.
/// Author: Manger Plus team
/// Created: 4/9/2026 — ported from knowticed_plus.
///
/// A segmented switch: a filled tray at radius 8 holding the tabs, the
/// selected one filled with brand primary. No borders, no underline.
///
/// Example:
/// ```dart
/// CustomSegmentedTabs(
///   tabs: const <String>['Cards', 'Table'],
///   selectedIndex: index,
///   onTabSelected: (int i) => setState(() => index = i),
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class CustomSegmentedTabs extends StatelessWidget {
  const CustomSegmentedTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.containerPadding,
    this.containerColor,
    this.borderRadius,
    this.spacing,
    this.tabHorizontalPadding,
    this.tabVerticalPadding,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.textStyle,
    this.equalWidth = false,
  });

  /// List of tab titles.
  final List<String> tabs;

  /// Currently selected tab index (0-based).
  final int selectedIndex;

  /// Called with the tapped tab's index.
  final ValueChanged<int> onTabSelected;

  final EdgeInsets? containerPadding;
  final Color? containerColor;
  final double? borderRadius;
  final double? spacing;
  final double? tabHorizontalPadding;
  final double? tabVerticalPadding;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final TextStyle? textStyle;

  /// True gives every tab the same width.
  final bool equalWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
        color: containerColor ?? AppColors.field,
      ),
      padding: containerPadding ?? EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 8.sp),
      child: Row(
        mainAxisSize: equalWidth ? MainAxisSize.max : MainAxisSize.min,
        children: List<Widget>.generate(tabs.length * 2 - 1, (int index) {
          // Even indices are tabs, odd indices are spacers.
          if (index.isOdd) return SizedBox(width: spacing ?? 10.sp);

          final int tabIndex = index ~/ 2;
          final Widget tab = _buildTab(
            title: tabs[tabIndex],
            isSelected: tabIndex == selectedIndex,
            onTap: () => onTabSelected(tabIndex),
          );

          return equalWidth ? Expanded(child: tab) : tab;
        }),
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.buttonR,
            color: isSelected
                ? (selectedColor ?? AppColors.primary)
                : (unselectedColor ?? AppColors.field),
          ),
          padding: EdgeInsets.symmetric(
            vertical: tabVerticalPadding ?? 6.sp,horizontal: AppPadding.h),
          child: Center(
            child: FittedBox(
              child: Text(
                FormatHelper.capitalize(title),
                style: (textStyle ?? StyleText.fontSize14Weight600).copyWith(
                  height: 1.h,
                  color: isSelected
                      ? (selectedTextColor ?? AppColors.textButton)
                      : (unselectedTextColor ?? AppColors.secondaryText),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
