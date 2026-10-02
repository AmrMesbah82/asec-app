/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: admin_videos_page.dart
/// Purpose: Declares `AdminVideosPage` — every lesson, with the way in to the
///          upload form.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 1/10/2026 - Categories first (one per Drive sub-folder), then
///          the videos of the category opened.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/data/seed/drive_lessons.dart';
import 'package:asec/features/video/v1_videos/domain/base_repository/video_base_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_form_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_player_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_categories.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_grid.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
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

  /// The category opened; null = the category list.
  String? _category;

  /// The sub-folder opened inside [_category]; null = its sub-folder list.
  String? _subcategory;

  Future<void> _openForm([VideoItem? video]) => Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => VideoFormPage(
            video: video,
            adminUid: widget.adminUid,
            // A video added from inside a category lands in that category.
            category: _category ?? '',
          ),
        ),
      );

  /// The lessons come from the shared Google Drive folder by themselves:
  /// this page is built when the admin shell opens (it keeps every section
  /// alive), so every time an admin opens the app the videos are brought in
  /// line with the folder — new files added, removed ones dropped, the old
  /// sample videos cleared. See DriveVideoSync. The list below is a live
  /// Firestore stream, so it updates the moment the sync writes.
  @override
  void initState() {
    super.initState();
    DriveVideoSync.run(adminUid: widget.adminUid).then((String? problem) {
      if (problem == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 12),
        content: Text(problem, maxLines: 6, overflow: TextOverflow.ellipsis),
      ));
    });
  }

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
      // Adding videos is for amrmesbah33@gmail.com only.
      floatingActionButton: !SessionController.to.current.isSuperAdmin
          ? null
          : FloatingActionButton.extended(
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

          final List<VideoItem> all = snapshot.data!.toList()
            // Lesson order, the same as members see.
            ..sort((VideoItem a, VideoItem b) => (a.createdAt ?? DateTime(0))
                .compareTo(b.createdAt ?? DateTime(0)));
          if (all.isEmpty) {
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosAdminSub,
              child: AppEmptyView(
                title: s.noVideosTitle,
                subtitle: s.noVideosAdminSub,
              ),
            );
          }

          final List<VideoCategory> categories = VideoCategory.group(all);
          final bool grouped = categories.length > 1;
          VideoCategory? current;
          if (!grouped) {
            current = categories.first;
          } else if (_category != null) {
            for (final VideoCategory c in categories) {
              if (c.name == _category) current = c;
            }
          }

          if (current == null) {
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosAdminSub,
              child: VideoCategoryGrid(
                categories: categories,
                showProgress: false,
                bottomPadding: 96,
                onOpen: (VideoCategory c) => setState(() {
                  _category = c.name;
                  _subcategory = null;
                }),
              ),
            );
          }

          // Sub-folders of the category (AutoCAD → Introduction-01, …).
          final VideoCategory category = current;
          final List<VideoCategory> subs =
              VideoCategory.group(category.videos, bySubcategory: true);
          VideoCategory? sub;
          if (subs.length > 1) {
            for (final VideoCategory c in subs) {
              if (c.name == _subcategory) sub = c;
            }
            if (sub == null) {
              return ConsolePage(
                title: s.typeVideos,
                subtitle: s.videosAdminSub,
                child: VideoCategoryGrid(
                  categories: subs,
                  showProgress: false,
                  bottomPadding: 96,
                  onOpen: (VideoCategory c) =>
                      setState(() => _subcategory = c.name),
                  header: grouped
                      ? VideoCategoryHeader(
                          category: category,
                          onBack: () => setState(() => _category = null),
                        )
                      : null,
                ),
              );
            }
            current = sub;
          }

          final List<VideoItem> videos = current.videos;
          return ConsolePage(
            title: s.typeVideos,
            subtitle: s.videosAdminSub,
            child: VideoGrid(
              videos: videos,
              header: sub != null
                  ? VideoCategoryHeader(
                      category: sub,
                      backLabel: category.label(s),
                      onBack: () => setState(() => _subcategory = null),
                    )
                  : grouped
                      ? VideoCategoryHeader(
                          category: current,
                          onBack: () => setState(() => _category = null),
                        )
                      : null,
              bottomPadding: 96,
              onOpen: (VideoItem video) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      VideoPlayerPage(video: video, playlist: videos),
                ),
              ),
              trailingBuilder: (VideoItem video) => PopupMenuButton<_VideoAction>(
                padding: EdgeInsets.zero,
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
            ),
          );
        },
      ),
    );
  }
}

enum _VideoAction { edit, delete }
