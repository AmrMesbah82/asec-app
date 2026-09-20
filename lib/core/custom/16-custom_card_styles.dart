/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: custom_card_styles.dart
/// Purpose: Declares `CardSvg`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

// Shared visual tokens & helpers for the reusable Figma card widgets.
// Theme source: Knowticed app (AppColors / AppFontWeights).
// All sizes are responsive via flutter_screenutil (.sp / .w / .h / .r).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/custom/32-custom_svg.dart';

/// SVG icon assets used by the card widgets.
/// All paths point to existing, pubspec-declared assets in assets/icons_assets.
abstract class CardSvg {
  static const String services = 'assets/icons_assets/main_icons_assets/services_building_stars.svg';
  static const String serviceProvider = 'assets/icons_assets/main_icons_assets/healthcare_provider_hand_shield.svg';
  static const String jobTitle = 'assets/icons_assets/main_icons_assets/Case.svg';
  static const String duration = 'assets/icons_assets/main_icons_assets/clock_circle.svg';
  static const String approval = 'assets/icons_assets/main_icons_assets/approval_badge_check.svg';
  static const String personalInfo = 'assets/icons_assets/main_icons_assets/person_outline.svg';
  static const String department = 'assets/icons_assets/services_assets/department_hierarchy_people.svg';
  static const String message = 'assets/icons_assets/main_icons_assets/chat_bubble_dots.svg';
  static const String email = 'assets/icons_assets/main_icons_assets/email_envelope.svg';
  static const String phone = 'assets/icons_assets/services_assets/phone_handset.svg';
  static const String male = 'assets/icons_assets/main_icons_assets/male_avatar.svg';
  static const String approve = 'assets/icons_assets/main_icons_assets/approval_badge_check.svg';
  static const String reject = 'assets/icons_assets/main_icons_assets/status_rejected_stamp_red.svg';
  static const String remove = 'assets/icons_assets/main_icons_assets/minus_circle_red.svg';

  /// Builds an SVG icon, optionally tinted with [color].
  static Widget icon(String path, {Color? color, double? size}) =>
      CustomSvgImage.natural(
        assetPath: path,
        width: size?.r,
        height: size?.r,
        colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
      );
}

abstract class CardStyles {
  /// Default card corner radius — [AppRadius.container].
  static BorderRadius radius([double r = AppRadius.container]) =>
      BorderRadius.circular(r.r);

  /// Figma drop shadow: (-3, 4) blur 20, black 2%.
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: AppColors.totalBlack.withOpacity(0.02),
          offset: Offset(-3.w, 4.h),
          blurRadius: 20.r,
        ),
      ];

  /// Maps a font size to the matching regular (w400) [StyleText] token.
  static TextStyle _regular(double size) {
    switch (size.round()) {
      case 8:
        return StyleText.fontSize8Weight400;
      case 10:
        return StyleText.fontSize10Weight400;
      case 11:
        return StyleText.fontSize11Weight400;
      case 12:
        return StyleText.fontSize12Weight400;
      case 13:
        return StyleText.fontSize13Weight400;
      case 15:
        return StyleText.fontSize15Weight400;
      case 16:
        return StyleText.fontSize16Weight400;
      case 14:
      default:
        return StyleText.fontSize14Weight400;
    }
  }

  /// Maps a font size to the matching medium (w500) [StyleText] token.
  static TextStyle _medium(double size) {
    switch (size.round()) {
      case 12:
        return StyleText.fontSize12Weight500;
      case 13:
        return StyleText.fontSize13Weight500;
      case 14:
        return StyleText.fontSize14Weight500;
      case 15:
        return StyleText.fontSize15Weight500;
      case 18:
        return StyleText.fontSize18Weight500;
      case 20:
        return StyleText.fontSize20Weight500;
      case 16:
      default:
        return StyleText.fontSize16Weight500;
    }
  }

  /// Grey label style (e.g. "Job Title:").
  static TextStyle label(double size) =>
      _regular(size).copyWith(color: AppColors.secondaryText);

  /// Dark value style (e.g. "Marketing Manager").
  static TextStyle value(double size) =>
      _regular(size).copyWith(color: AppColors.text);

  /// Card title style.
  static TextStyle title(double size) =>
      _medium(size).copyWith(color: AppColors.text);
}

/// A "label: value" entry used by the cards, with an optional leading icon.
class CardInfo {
  final String label;
  final String value;
  final Widget? icon;

  const CardInfo({required this.label, required this.value, this.icon});
}

/// Renders: [icon] label value   (e.g. "👤 Service Provider: Ahmed Mohammed")
class CardInfoRow extends StatelessWidget {
  final CardInfo info;
  final double fontSize;
  final double iconSize;

  const CardInfoRow({
    super.key,
    required this.info,
    this.fontSize = 14,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info.icon != null) ...[
          SizedBox(
            width: iconSize.r,
            height: iconSize.r,
            child: FittedBox(child: info.icon,),
          ),
          SizedBox(width: 4.w),
        ],
        Flexible(
          child: Text.rich(
            TextSpan(
              text: '${info.label} ',
              style: CardStyles.label(fontSize),
              children: [
                TextSpan(
                  text: info.value,
                  style: CardStyles.value(fontSize),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
