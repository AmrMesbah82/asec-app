/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: custom_check_box.dart
/// Purpose: Declares `CustomCheckBox`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

/// ******************* FILE INFO *******************
/// File Name: custom_check_box.dart
/// Description: Custom CheckBox widget with styling to responed to secondary color
/// Created by: Mohamed Elrashidy

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';

class CustomCheckBox extends StatelessWidget {
  CustomCheckBox(
      {this.size, required this.isSelected, this.borderColor, super.key});
  bool isSelected = false;
  Color? borderColor;
  double? size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? 22.sp,
      height: size ?? 22.sp,
      decoration: BoxDecoration(
        // CHANGED 4/9/2026: unchecked was a 1.5 outline over transparent, the
        // last outlined control in the app. It is a filled well now — the same
        // "empty box" reading, drawn the way every other surface here is.
        color: isSelected ? AppColors.secondaryPrimary : AppColors.field,
        borderRadius: AppRadius.containerR,
      ),
      child: Center(
        child: CustomSvgImage(
          assetPath: AppAssets.success,
          width: (size ?? 22.sp) - 7.sp,
          height: (size ?? 22.sp) - 7.sp,
          color: isSelected
              ? AppColors.secondaryPrimaryText
              : AppColors.transparent,
        ),
      ),
    );
  }
}
