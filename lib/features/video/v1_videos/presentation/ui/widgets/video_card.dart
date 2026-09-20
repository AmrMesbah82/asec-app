/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_card.dart
/// Purpose: Declares `VideoCard` — one lesson in a list.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/generated/l10n.dart';

class VideoCard extends StatelessWidget {
  const VideoCard({
    super.key,
    required this.video,
    this.onTap,
    this.trailing,
  });

  final VideoItem video;
  final VoidCallback? onTap;
  final Widget? trailing;

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
            // A poster would mean generating a thumbnail on upload; the brand
            // gradient with a play badge reads as a video without the round
            // trip, and never shows a broken image.
            Container(
              height: 96.h,
              decoration: BoxDecoration(
                borderRadius: AppRadius.containerR,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppColors.primary.withOpacity(0.85),
                    AppColors.secondaryPrimary.withOpacity(0.85),
                  ],
                ),
              ),
              child: Center(
                child: AppIcon(
                  Icons.play_circle_fill_rounded,
                  size: 40.sp,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize15Weight600,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (video.description.trim().isNotEmpty) ...<Widget>[
              SizedBox(height: 4.h),
              Text(
                video.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize12Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
            ],
            SizedBox(height: 10.h),
            Row(
              children: <Widget>[
                AppIcon(
                  Icons.event_rounded,
                  size: 13.sp,
                  color: AppColors.secondaryText,
                ),
                SizedBox(width: 4.w),
                Text(
                  AppDates.day(context, video.createdAt),
                  style: StyleText.fontSize11Weight400
                      .copyWith(color: AppColors.secondaryText),
                ),
                const Spacer(),
                if (video.sizeBytes > 0)
                  Text(
                    s.megabytes(video.sizeMb),
                    style: StyleText.fontSize11Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                if (!video.published) ...<Widget>[
                  SizedBox(width: 8.w),
                  Text(
                    s.draft,
                    style: StyleText.fontSize11Weight600
                        .copyWith(color: AppColors.statusPending),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
