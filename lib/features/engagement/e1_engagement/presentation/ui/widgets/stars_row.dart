/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: stars_row.dart
/// Purpose: Declares `StarsRow` — 0..5 stars in a row (1 per 20% watched),
///          and `StarsChip` — "⭐ 12" for a total.
/// Author: ASEC team
/// Created: 15/10/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/controller/watch_sync.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// The star colour on light and dark surfaces alike.
const Color kStarColor = Color(0xFFF5B301);

class StarsRow extends StatelessWidget {
  const StarsRow({
    super.key,
    required this.stars,
    this.size = 18,
    this.emptyColor,
  });

  final int stars;
  final double size;

  /// Defaults to a faint grey; pass white-ish on a coloured card.
  final Color? emptyColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < CourseStars.max; i++)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.6, end: 1),
            duration: Duration(milliseconds: 300 + i * 90),
            curve: Curves.easeOutBack,
            builder: (BuildContext context, double v, Widget? child) =>
                Transform.scale(scale: v, child: child),
            child: Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size.r,
              color: i < stars
                  ? kStarColor
                  : (emptyColor ?? AppColors.secondaryText.withOpacity(0.35)),
            ),
          ),
      ],
    );
  }
}

class StarsChip extends StatelessWidget {
  const StarsChip({
    super.key,
    required this.label,
    this.onColor = false,
  });

  final String label;

  /// True on the coloured hero card (white text on a translucent pill).
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: onColor
            ? AppColors.textButton.withOpacity(0.16)
            : kStarColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.star_rounded, size: 16.r, color: kStarColor),
          SizedBox(width: 4.w),
          Text(
            FormatHelper.capitalize(label),
            style: StyleText.fontSize12Weight700.copyWith(
              color: onColor ? AppColors.textButton : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
