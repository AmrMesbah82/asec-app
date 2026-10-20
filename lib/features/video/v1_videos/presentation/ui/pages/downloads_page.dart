/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: downloads_page.dart
/// Purpose: Declares `DownloadsPage` — the student's "Downloads" section:
///          lessons saved inside ASEC, playable with no internet. Also shown
///          on the offline screen (core/settings/app_connectivity.dart).
/// Author: ASEC team
/// Created: 1/10/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/video/v1_videos/data/download/video_downloads.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_player_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_download_button.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_grid.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    VideoDownloads.ensureLoaded().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  Future<void> _removeAll() async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.downloadsRemoveAllQuestion,
      subtitle: s.downloadRemoveBody,
      confirmLabel: s.downloadsRemoveAll,
      cancelLabel: s.cancel,
      onConfirm: VideoDownloads.removeAll,
    );
  }

  Future<void> _open(VideoItem video, List<VideoItem> playlist) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerPage(video: video, playlist: playlist),
      ),
    );
    if (mounted) setState(() {}); // watched ticks changed
  }

  static String _mb(int bytes) {
    final double mb = bytes / (1024 * 1024);
    return mb >= 1024
        ? '${(mb / 1024).toStringAsFixed(1)} GB'
        : '${mb.toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    if (!_loaded) return const AppLoading();

    return Obx(() {
      // A course the admin closed for this member is not playable offline
      // either. (Offline with no profile loaded yet, nothing is filtered.)
      final AppUser me = SessionController.to.current;
      final List<VideoItem> all = VideoDownloads.items
          .where((VideoItem v) => me.isEmpty || v.free || me.canSeeCourse(v.category))
          .toList();
      VideoDownloads.active.length; // tracked
      final List<VideoItem> pending = VideoDownloads.pending;

      if (all.isEmpty && pending.isEmpty) {
        return ConsolePage(
          title: s.downloads,
          subtitle: s.downloadsSub,
          child: AppEmptyView(
            title: s.downloadsEmptyTitle,
            subtitle: s.downloadsEmptySub,
          ),
        );
      }

      final Widget header = Padding(
        padding: EdgeInsets.only(bottom: 18.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.sd_storage_rounded,
                    size: 18.sp, color: AppColors.secondaryText),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    FormatHelper.capitalize(s.downloadsStorage(_mb(VideoDownloads.totalBytes))),
                    style: StyleText.fontSize13Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ),
                if (all.isNotEmpty)
                  customButton(
                    title: s.downloadsRemoveAll,
                    function: _removeAll,
                    wrapContent: true,
                  ),
              ],
            ),
            for (final VideoItem v in pending) ...<Widget>[
              SizedBox(height: 12.h),
              _PendingRow(video: v),
            ],
          ],
        ),
      );

      return ConsolePage(
        title: s.downloads,
        subtitle: s.downloadsSub,
        child: VideoGrid(
          videos: all,
          header: header,
          onOpen: (VideoItem v) => _open(v, all),
          trailingBuilder: (VideoItem v) => VideoDownloadButton(video: v),
        ),
      );
    });
  }
}

/// "Downloading  Lesson title  ━━━━━━━━──  62%   ✕"
class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.video});

  final VideoItem video;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final double p = VideoDownloads.active[video.id] ?? 0;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.downloading_rounded, size: 20.sp, color: AppColors.primary),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    FormatHelper.capitalize(video.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize13Weight600
                        .copyWith(color: AppColors.text),
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: p > 0 ? p : null,
                      minHeight: 5.h,
                      backgroundColor: AppColors.secondaryText.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              FormatHelper.capitalize('${(p * 100).round()}%'),
              style: StyleText.fontSize12Weight600
                  .copyWith(color: AppColors.secondaryText),
            ),
            SizedBox(width: 4.w),
            VideoDownloadButton(video: video),
          ],
        ),
      );
    });
  }
}
