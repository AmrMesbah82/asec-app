/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: user_videos_page.dart
/// Purpose: Declares `UserVideosPage` — the lessons a member can watch.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/69-cross_axis_count_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/base_repository/video_base_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_player_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_card.dart';
import 'package:asec/generated/l10n.dart';

class UserVideosPage extends StatefulWidget {
  const UserVideosPage({super.key});

  @override
  State<UserVideosPage> createState() => _UserVideosPageState();
}

class _UserVideosPageState extends State<UserVideosPage> {
  final VideoBaseRepository _repository = VideoRepository();
  late final Stream<List<VideoItem>> _videos = _repository.watchPublished();

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<VideoItem>>(
        stream: _videos,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<VideoItem>> snapshot,
        ) {
          if (snapshot.hasError) return AppErrorView(message: s.errUnknown);
          if (!snapshot.hasData) return const AppLoading();

          final List<VideoItem> videos = snapshot.data!
              .where((VideoItem v) => v.hasFile)
              .toList();
          if (videos.isEmpty) {
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosUserSub,
              child: AppEmptyView(
                title: s.noVideosTitle,
                subtitle: s.noVideosUserSub,
              ),
            );
          }

          return ConsolePage(
            title: s.typeVideos,
            subtitle: s.videosUserSub,
            child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GridView.builder(
                padding: EdgeInsets.only(bottom: 24.h),
                gridDelegate: CrossAxisCountHelper.gridDelegate(
                  context,
                  mainAxisExtent: 270,
                  minCellWidth: 280,
                  availableWidth: constraints.maxWidth,
                ),
                itemCount: videos.length,
                itemBuilder: (BuildContext context, int index) => VideoCard(
                  video: videos[index],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => VideoPlayerPage(video: videos[index]),
                    ),
                  ),
                ),
              );
            },
          ),
          );
        },
      ),
    );
  }
}
