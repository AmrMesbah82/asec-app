/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: admin_videos_page.dart
/// Purpose: Declares `AdminVideosPage` — every lesson, with the way in to the
///          upload form.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/custom/69-cross_axis_count_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/base_repository/video_base_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_form_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_player_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_card.dart';
import 'package:asec/generated/l10n.dart';

class AdminVideosPage extends StatefulWidget {
  const AdminVideosPage({super.key, required this.adminUid});

  final String adminUid;

  @override
  State<AdminVideosPage> createState() => _AdminVideosPageState();
}

class _AdminVideosPageState extends State<AdminVideosPage> {
  final VideoBaseRepository _repository = VideoRepository();
  late final Stream<List<VideoItem>> _videos = _repository.watchAll();

  Future<void> _openForm([VideoItem? video]) => Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => VideoFormPage(video: video, adminUid: widget.adminUid),
        ),
      );

  Future<void> _confirmDelete(VideoItem video) async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.deleteQuestion(video.title),
      subtitle: s.deleteVideoBody,
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      onConfirm: () async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        final String deleted = s.deleted;
        await _repository.delete(video);
        messenger.showSnackBar(SnackBar(content: Text(deleted)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        // THE SHELL KEEPS EVERY SECTION ALIVE (IndexedStack), so this FAB and
        // the quizzes FAB exist in the same route subtree. Flutter gives every
        // FAB the same default hero tag, and two heroes with one tag is an
        // exception on the next page push — hence an explicit tag each.
        heroTag: 'asec_fab_videos',
        onPressed: _openForm,
        backgroundColor: AppColors.primary,
        icon: const AppIcon(Icons.cloud_upload_outlined, color: Colors.white),
        label: Text(
          s.addVideo,
          style: StyleText.fontSize14Weight600.copyWith(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<VideoItem>>(
        stream: _videos,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<VideoItem>> snapshot,
        ) {
          if (snapshot.hasError) return AppErrorView(message: s.errUnknown);
          if (!snapshot.hasData) return const AppLoading();

          final List<VideoItem> videos = snapshot.data!;
          if (videos.isEmpty) {
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosAdminSub,
              child: AppEmptyView(
                title: s.noVideosTitle,
                subtitle: s.noVideosAdminSub,
              ),
            );
          }

          return ConsolePage(
            title: s.typeVideos,
            subtitle: s.videosAdminSub,
            child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GridView.builder(
                padding: EdgeInsets.only(bottom: 96.h),
                gridDelegate: CrossAxisCountHelper.gridDelegate(
                  context,
                  mainAxisExtent: 270,
                  minCellWidth: 280,
                  availableWidth: constraints.maxWidth,
                ),
                itemCount: videos.length,
                itemBuilder: (BuildContext context, int index) {
                  final VideoItem video = videos[index];
                  return VideoCard(
                    video: video,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => VideoPlayerPage(video: video),
                      ),
                    ),
                    trailing: PopupMenuButton<_VideoAction>(
                      icon: AppIcon(Icons.more_vert_rounded, size: 20.sp),
                      onSelected: (_VideoAction action) {
                        switch (action) {
                          case _VideoAction.edit:
                            _openForm(video);
                          case _VideoAction.delete:
                            _confirmDelete(video);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<_VideoAction>>[
                        PopupMenuItem<_VideoAction>(
                          value: _VideoAction.edit,
                          child: Text(s.edit),
                        ),
                        PopupMenuItem<_VideoAction>(
                          value: _VideoAction.delete,
                          child: Text(
                            s.delete,
                            style: StyleText.fontSize14Weight500
                                .copyWith(color: AppColors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          );
        },
      ),
    );
  }
}

enum _VideoAction { edit, delete }
