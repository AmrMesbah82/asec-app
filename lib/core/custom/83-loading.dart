/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: circle_progress.dart
/// Purpose: Declares `CircleProgress`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:asec/core/theme/app_colors.dart';

class CircleProgress extends StatelessWidget {
  const CircleProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryPrimary),
        backgroundColor: AppColors.white,
        strokeWidth: 2.0,
      ),
    );
  }
}


/// Full-screen modal loading overlay.
///
/// Canonical home for the app's loading indicator: every feature calls these
/// two instead of rolling its own overlay.
Future showLoadingIndicator() {
  double size = 70;
  return Get.dialog(
    Scaffold(
      backgroundColor: AppColors.transparent,
      body: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightPrimary),
            backgroundColor: AppColors.white.withOpacity(0.6),
            strokeWidth: 2.0,
          ),
        ),
      ),
    ),
    barrierDismissible: false,
    barrierColor: AppColors.totalBlack.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 700),
  );
}

hideLoadingIndicator() {
  Get.back();
}
