/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_card.dart
/// Purpose: Declares `CvCard` — one CV in the directory.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

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
    final bool hasYear = cv.graduationYear.isNotEmpty;
    final bool hasPlace = cv.location.isNotEmpty;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.secondaryText.withOpacity(0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // ── Who ────────────────────────────────────────────────────
              Row(
                children: <Widget>[
                  // A thin brand ring makes the photo the card's anchor.
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: CvAvatar(cv: cv, size: 46),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          FormatHelper.capitalize(cv.fullName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize15Weight600
                              .copyWith(color: AppColors.text),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          FormatHelper.capitalize(cv.headline),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize12Weight400.copyWith(
                            color: AppColors.secondaryText,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (showStatus)
                    _Tag(label: cv.status.label(context), strong: true)
                  else
                    AppIcon(
                      Icons.chevron_right_rounded,
                      size: 20.sp,
                      color: AppColors.secondaryText,
                    ),
                ],
              ),

              // ── Where / when ───────────────────────────────────────────
              if (hasPlace || hasYear) ...<Widget>[
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: <Widget>[
                    if (hasPlace)
                      _Meta(icon: Icons.location_on_outlined, text: cv.location),
                    if (hasYear)
                      _Meta(icon: Icons.school_outlined, text: cv.graduationYear),
                  ],
                ),
              ],

              // ── Skills ─────────────────────────────────────────────────
              if (cv.proSkills.isNotEmpty) ...<Widget>[
                SizedBox(height: 10.h),
                // Three skills and a counter: a card that lists twelve is a
                // wall, and the detail page has them all anyway.
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: <Widget>[
                    for (final String skill in cv.proSkills.take(3))
                      _Tag(label: skill),
                    if (cv.proSkills.length > 3)
                      _Tag(label: '+${cv.proSkills.length - 3}', muted: true),
                  ],
                ),
              ],

              // ── Footer ─────────────────────────────────────────────────
              if (cv.updatedAt != null) ...<Widget>[
                SizedBox(height: 12.h),
                Divider(
                  height: 1,
                  color: AppColors.secondaryText.withOpacity(0.12),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: <Widget>[
                    AppIcon(
                      Icons.update_rounded,
                      size: 13.sp,
                      color: AppColors.secondaryText,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        FormatHelper.capitalize(s.cvUpdatedOn(AppDates.day(context, cv.updatedAt))),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize10Weight400
                            .copyWith(color: AppColors.secondaryText),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Location / graduation year: icon + text on a soft pill.
class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(icon, size: 13.sp, color: AppColors.secondaryText),
          SizedBox(width: 4.w),
          Text(
            FormatHelper.capitalize(text),
            style: StyleText.fontSize11Weight400
                .copyWith(color: AppColors.secondaryText),
          ),
        ],
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

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.muted = false, this.strong = false});

  final String label;
  final bool muted;

  /// The admin's review state — brand-tinted so it stands out from skills.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final Color color = strong
        ? AppColors.primary
        : (muted ? AppColors.secondaryText : AppColors.onChip);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: strong ? AppColors.primary.withOpacity(0.10) : AppColors.chip,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        FormatHelper.capitalize(label),
        style: StyleText.fontSize10Weight600.copyWith(color: color),
      ),
    );
  }
}
