/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 10-custom_tabs.dart
/// Purpose: Declares `CustomTabs`.
/// Author: Manger Plus team
/// Created: 4/9/2026 — ported from knowticed_plus.
///
/// Horizontally scrollable text tabs; the selected one is tinted with brand
/// primary and carries a 1.5 underline. Use this for page-level sections
/// (Role Management / User Management); use `CustomSegmentedTabs` for a
/// two-or-three-way switch inside a toolbar.
///
/// ```dart
/// CustomTabs(
///   tabs: const <String>['Active', 'Completed'],
///   selectedValue: index,
///   onChanged: (int v) => setState(() => index = v),
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';

class CustomTabs extends StatelessWidget {
  /// Visible tab titles (already translated).
  final List<String> tabs;

  /// Underlying value of each tab. Defaults to `[0..tabs.length-1]`.
  /// Must have the same length as [tabs] — pass it when some tabs are hidden
  /// by permissions and the caller still keys on the original indices.
  final List<int>? values;

  /// Currently selected value (compared against [values]).
  final int selectedValue;

  /// Called with the tapped tab's value, only when it changes.
  final ValueChanged<int> onChanged;

  /// Gap between tabs. Defaults to 32.sp.
  final double? spacing;

  final TextStyle? textStyle;
  final Color? selectedColor;
  final Color? unselectedColor;

  const CustomTabs({
    super.key,
    required this.tabs,
    required this.selectedValue,
    required this.onChanged,
    this.values,
    this.spacing,
    this.textStyle,
    this.selectedColor,
    this.unselectedColor,
  }) : assert(values == null || values.length == tabs.length,
            'values must match tabs length');

  @override
  Widget build(BuildContext context) {
    final List<int> tabValues =
        values ?? List<int>.generate(tabs.length, (int i) => i);
    final TextStyle baseStyle = textStyle ??
        StyleText.fontSize20Weight500
            .copyWith(color: AppColors.secondaryBlack);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < tabs.length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: spacing ?? 32.sp),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (selectedValue != tabValues[i]) onChanged(tabValues[i]);
                },
                // IntrinsicWidth so the underline is exactly as wide as its
                // label — a fixed width leaves a short tab underlined past its
                // last letter and clips a long one.
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        tabs[i],
                        style: baseStyle.copyWith(
                          height: 1.3.h,
                          color: selectedValue == tabValues[i]
                              ? (selectedColor ?? AppColors.primary)
                              : (unselectedColor ?? AppColors.secondaryBlack),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        height: 1.5.sp,
                        color: selectedValue == tabValues[i]
                            ? (selectedColor ?? AppColors.primary)
                            : AppColors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
