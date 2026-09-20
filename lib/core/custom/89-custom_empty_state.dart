/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 89-custom_empty_state.dart
/// Purpose: Declares `CustomEmptyState`.
/// Author: Manger Plus team
/// Created: 3/9/2026
///
/// The app's ONE empty state: the `lottie_empty` animation, no words.
///
/// WHY NO TEXT
/// -----------
/// Every list and table used to write its own sentence — "No orders yet", "No
/// customers match", "Nothing here". Same fact, four wordings, four
/// translations. The animation carries it.
///
/// EMPTY IS NOT AN ERROR
/// ---------------------
/// Do not reach for this when a read FAILED. "There is nothing here" and "we
/// could not find out what is here" are different facts; a failed read keeps
/// its own branch with a retry.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import 'package:asec/core/constants/app_assets.dart';

class CustomEmptyState extends StatelessWidget {
  const CustomEmptyState({super.key, this.size, this.verticalPadding});

  /// Width and height of the animation. Defaults to 220 — big enough to read
  /// as a deliberate state rather than a loading glitch, small enough to sit
  /// inside a console card without pushing its footer off screen.
  final double? size;

  /// Space above and below. Defaults to 24.
  final double? verticalPadding;

  @override
  Widget build(BuildContext context) {
    final double dimension = (size ?? 220).r;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (verticalPadding ?? 24).h),
      child: Center(
        child: Lottie.asset(
          AppAssets.lottieEmpty,
          width: dimension,
          height: dimension,
          // Loops. A one-shot animation that has finished looks like a static
          // illustration that failed to load, and this is often the first
          // thing on an otherwise blank screen.
          repeat: true,
        ),
      ),
    );
  }
}
