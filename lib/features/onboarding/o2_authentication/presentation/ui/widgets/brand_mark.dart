/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: brand_mark.dart
/// Purpose: Declares `BrandMark` — the app's logo lock-up.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/generated/l10n.dart';

/// A glyph on a brand gradient, with the name beside or beneath it.
/// Drawn in code so it follows the branding colours automatically.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 56,
    this.showName = true,
    this.vertical = false,
    this.onDark = false,
  });

  final double size;
  final bool showName;
  final bool vertical;

  /// White name, for gradient backgrounds.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Widget mark = Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
        ),
        borderRadius: BorderRadius.circular((size * 0.3).r),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 18.sp,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AppIcon(
        Icons.play_circle_fill_rounded,
        color: Colors.white,
        size: (size * 0.56).r,
      ),
    );

    if (!showName) return mark;

    final Widget name = Column(
      crossAxisAlignment:
          vertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          S.of(context).appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: StyleText.fontSize22Weight700.copyWith(
            color: onDark ? Colors.white : AppColors.text,
            fontSize: (size * 0.42).sp,
          ),
        ),
        Text(
          S.of(context).appTagline,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: StyleText.fontSize12Weight500.copyWith(
            color: onDark ? Colors.white70 : AppColors.secondaryText,
          ),
        ),
      ],
    );

    return vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[mark, SizedBox(height: 14.h), name],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              mark,
              SizedBox(width: 12.w),
              Flexible(child: name),
            ],
          );
  }
}
