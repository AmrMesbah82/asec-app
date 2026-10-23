/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_card.dart
/// Purpose: Declares `VideoCard` (a grid tile) and `VideoListTile` (a compact
///          "up next" row) — lessons laid out the way a video site does:
///          thumbnail first, then channel avatar, title and "ASEC · 3 days
///          ago" underneath. No card box around them.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 25/9/2026 - Video-site layout: 16:9 thumbnail, hover play,
///          watch progress, relative dates.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_thumbnail.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// The height a [VideoCard] needs below its thumbnail: avatar row with a
/// two-line title and one meta line.
const double kVideoCardTextHeight = 88;

class VideoCard extends StatefulWidget {
  const VideoCard({
    super.key,
    required this.video,
    this.onTap,
    this.trailing,
    this.locked = false,
    this.lessonNumber,
    this.badge,
  });

  final VideoItem video;
  final VoidCallback? onTap;

  /// Drawn on the thumbnail's top corner (the admin's Default / Custom).
  final Widget? badge;

  /// Usually a ⋮ menu (admin: edit / delete).
  final Widget? trailing;

  final bool locked;
  final int? lessonNumber;

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final VideoItem video = widget.video;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: _hover && !widget.locked ? 1.02 : 1,
              child: Stack(
                // The thumbnail keeps the full width the column gives it.
                fit: StackFit.passthrough,
                children: <Widget>[
                  VideoThumbnail(
                    video: video,
                    hover: _hover,
                    locked: widget.locked,
                    lessonNumber: widget.lessonNumber,
                    lockedBehind: widget.lessonNumber == null
                        ? null
                        : widget.lessonNumber! - 1,
                  ),
                  if (widget.badge != null)
                    PositionedDirectional(
                      top: 8.h,
                      end: 8.w,
                      child: widget.badge!,
                    ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _ChannelAvatar(),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        video.title, // exactly as named in Drive
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize15Weight600.copyWith(
                          color: widget.locked
                              ? AppColors.secondaryText
                              : AppColors.text,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      _Meta(video: video),
                    ],
                  ),
                ),
                if (widget.trailing != null)
                  SizedBox(width: 32.w, child: widget.trailing),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact row: small thumbnail left, title and meta right.
class VideoListTile extends StatefulWidget {
  const VideoListTile({
    super.key,
    required this.video,
    this.onTap,
    this.nowPlaying = false,
    this.locked = false,
    this.lessonNumber,
  });

  final VideoItem video;
  final VoidCallback? onTap;
  final bool nowPlaying;
  final bool locked;
  final int? lessonNumber;

  @override
  State<VideoListTile> createState() => _VideoListTileState();
}

class _VideoListTileState extends State<VideoListTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final VideoItem video = widget.video;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: widget.nowPlaying
                ? AppColors.chip
                : (_hover
                    ? AppColors.chip.withOpacity(0.5)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 150,
                child: VideoThumbnail(
                  video: video,
                  compact: true,
                  hover: _hover,
                  nowPlaying: widget.nowPlaying,
                  locked: widget.locked,
                  lessonNumber: widget.lessonNumber,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      video.title, // exactly as named in Drive
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize13Weight600.copyWith(
                        color: AppColors.text,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    _Meta(video: video, small: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelAvatar extends StatelessWidget {
  const _ChannelAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.r,
      height: 34.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
        ),
      ),
      child: Center(
        child: Text(
          FormatHelper.capitalize('AS'),
          style: StyleText.fontSize11Weight700.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// "ASEC ✓" then "3 days ago · 12.4 MB".
class _Meta extends StatelessWidget {
  const _Meta({required this.video, this.small = false});

  final VideoItem video;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = (small
            ? StyleText.fontSize11Weight400
            : StyleText.fontSize12Weight400)
        .copyWith(color: AppColors.secondaryText);
    final String ago = videoTimeAgo(context, video.createdAt);
    final List<String> parts = <String>[
      if (ago.isNotEmpty) ago,
      if (video.sizeBytes > 0) '${video.sizeMb} MB',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(FormatHelper.capitalize('ASEC'), style: style),
            SizedBox(width: 3.w),
            Icon(Icons.check_circle_rounded,
                size: small ? 11 : 12, color: AppColors.secondaryText),
          ],
        ),
        if (parts.isNotEmpty)
          Text(
            FormatHelper.capitalize(parts.join(' · ')),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
      ],
    );
  }
}
