/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_grid.dart
/// Purpose: Declares `VideoGrid` — lessons in a responsive video-site grid:
///          as many ~300 px columns as fit, each tile exactly as tall as a
///          16:9 thumbnail plus its text, so nothing overflows or gaps.
/// Author: ASEC team
/// Created: 25/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_card.dart';
import 'package:asec/core/animation/app_animations.dart';

class VideoGrid extends StatelessWidget {
  const VideoGrid({
    super.key,
    required this.videos,
    required this.onOpen,
    this.trailingBuilder,
    this.bottomPadding = 24,
    this.header,
    this.lockedIds = const <String>{},
    this.lessonNumbers,
  });

  /// Lessons behind a padlock (sequential course).
  final Set<String> lockedIds;

  /// id → 1-based lesson number. Null hides the numbers (admin view).
  final Map<String, int>? lessonNumbers;

  final List<VideoItem> videos;
  final void Function(VideoItem video) onOpen;
  final Widget Function(VideoItem video)? trailingBuilder;
  final double bottomPadding;

  /// Scrolls with the grid (search bar, filter chips).
  final Widget? header;

  static const double _minTile = 280;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double gapX = _gap.w;
        final int columns =
            ((width + gapX) / (_minTile + gapX)).floor().clamp(1, 6);
        final double tileWidth = (width - gapX * (columns - 1)) / columns;
        final double tileHeight =
            tileWidth * 9 / 16 + 10.h + kVideoCardTextHeight.h + 12;

        return CustomScrollView(
          slivers: <Widget>[
            if (header != null) SliverToBoxAdapter(child: header),
            SliverPadding(
              padding: EdgeInsets.only(bottom: bottomPadding.h),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: gapX,
                  mainAxisSpacing: 20.h,
                  mainAxisExtent: tileHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final VideoItem video = videos[index];
                    return FadeSlideIn(
                      delay: staggerDelay(index, stepMs: 60),
                      child: VideoCard(
                        video: video,
                        onTap: () => onOpen(video),
                        trailing: trailingBuilder?.call(video),
                        locked: lockedIds.contains(video.id),
                        lessonNumber: lessonNumbers?[video.id],
                      ),
                    );
                  },
                  childCount: videos.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
