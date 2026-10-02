/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_card.dart
/// Purpose: Declares `CvCard` — one CV in the directory.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/generated/l10n.dart';

class CvCard extends StatelessWidget {
  const CvCard({
    super.key,
    required this.cv,
    this.onTap,
    this.showStatus = false,
  });

  final CvProfile cv;
  final VoidCallback? onTap;

  /// The admin sees the review state on the card; members do not.
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CvAvatar(cv: cv, size: 48),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        cv.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize15Weight600,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        cv.headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize12Weight400
                            .copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
                if (showStatus)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.chip,
                      borderRadius: AppRadius.buttonR,
                    ),
                    child: Text(
                      cv.status.label(context),
                      style: StyleText.fontSize10Weight600
                          .copyWith(color: AppColors.onChip),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: <Widget>[
                AppIcon(
                  Icons.location_on_outlined,
                  size: 13.sp,
                  color: AppColors.secondaryText,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    cv.location.isEmpty ? '—' : cv.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize11Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ),
                if (cv.graduationYear.isNotEmpty) ...<Widget>[
                  AppIcon(
                    Icons.school_outlined,
                    size: 13.sp,
                    color: AppColors.secondaryText,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    cv.graduationYear,
                    style: StyleText.fontSize11Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ],
            ),
            if (cv.proSkills.isNotEmpty) ...<Widget>[
              SizedBox(height: 10.h),
              // Three skills and a counter: a card that lists twelve is a
              // wall, and the detail page has them all anyway.
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: <Widget>[
                  for (final String skill in cv.proSkills.take(3))
                    _SkillChip(label: skill),
                  if (cv.proSkills.length > 3)
                    _SkillChip(
                      label: '+${cv.proSkills.length - 3}',
                      muted: true,
                    ),
                ],
              ),
            ],
            if (cv.updatedAt != null) ...<Widget>[
              SizedBox(height: 10.h),
              Text(
                s.cvUpdatedOn(AppDates.day(context, cv.updatedAt)),
                style: StyleText.fontSize10Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The CV's photo, or the app's avatar when there is none.
class CvAvatar extends StatelessWidget {
  const CvAvatar({super.key, required this.cv, this.size = 48});

  final CvProfile cv;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!cv.hasPhoto) return AppAvatar(name: cv.fullName, size: size);

    return Container(
      width: size.r,
      height: size.r,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.chip,
      ),
      child: Image.network(
        cv.photoUrl,
        fit: BoxFit.cover,
        // A photo that will not load must not leave a broken box in a list:
        // the initials avatar is the fallback.
        errorBuilder: (BuildContext context, Object _, StackTrace? __) =>
            AppAvatar(name: cv.fullName, size: size),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final Color color = muted ? AppColors.secondaryText : AppColors.onChip;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: AppRadius.buttonR,
      ),
      child: Text(
        label,
        style: StyleText.fontSize10Weight600.copyWith(color: color),
      ),
    );
  }
}
