/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: custom_main_button.dart
/// Purpose: Declares `MainCustomButton`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
// REMOVED_MODULE: import 'package:asec/features/external/services_mangment_module/core/new_theme.dart';

class MainCustomButton extends StatelessWidget {
  final String? buttonText;
  final VoidCallback onPressed;
  final double? height;
  final Color? buttonColor;
  final TextStyle? textStyle;

  const MainCustomButton({
    Key? key,
    required this.buttonText,
    required this.onPressed,
    this.height,
    this.buttonColor,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      height: height ?? 50.h,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonR,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(buttonText== null?"":buttonText!,
                style: textStyle ??
                    StyleText.fontSize23Weight600
                        .copyWith(color: AppColors.textButton)
            ),
          ],
        ),
      ),
    );
  }
}
