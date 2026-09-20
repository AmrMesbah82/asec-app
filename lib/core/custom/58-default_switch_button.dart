/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: default_switch_button.dart
/// Purpose: Declares `DefaultSwitchButton`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_switch/flutter_switch.dart';

import 'package:asec/core/theme/app_colors.dart';


class DefaultSwitchButton extends StatelessWidget {
  const DefaultSwitchButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Transform(
      alignment: Alignment.center,
      transform: isArabic ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
      child: FlutterSwitch(
        width: 38.sp,
        height: 22.sp,
        padding: 3.sp,
        borderRadius: 20.sp,
        toggleSize: 16.sp,
        activeColor: AppColors.secondaryPrimary,
        inactiveColor: Colors.grey.withOpacity(.16),
        value: value,
        onToggle: onChanged,
      ),
    );
  }
}