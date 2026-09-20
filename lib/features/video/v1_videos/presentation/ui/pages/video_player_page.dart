/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_player_page.dart
/// Purpose: Declares `VideoPlayerPage` — plays one lesson, with a fallback to
///          the system player where Flutter has no video plugin.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/generated/l10n.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key, required this.video});

  final VideoItem video;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  /// `video_player` has no implementation on Windows and Linux, and a stream
  /// can simply refuse to play. Either way the screen must end up offering
  /// the system player rather than a dead black box — hence the try/catch
  /// around initialize() and [_failed].
  Future<void> _open() async {
    try {
      final VideoPlayerController controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.video.url));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _openExternally() async {
    final Uri uri = Uri.parse(widget.video.url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.video.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: StyleText.fontSize16Weight600,
        ),
        actions: <Widget>[
          IconButton(
            tooltip: s.openExternally,
            onPressed: _openExternally,
            icon: const AppIcon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding:
              EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 16.h),
          child: ConstrainedBox(
            // A player wider than this on a desktop is a wall of pixels; the
            // video keeps its own aspect ratio inside it.
            constraints: BoxConstraints(maxWidth: 900.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _player(context, s),
                if (widget.video.description.trim().isNotEmpty) ...<Widget>[
                  SizedBox(height: 16.h),
                  Text(
                    widget.video.description,
                    style: StyleText.fontSize14Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _player(BuildContext context, S s) {
    if (_failed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppErrorView(message: s.videoFailed),
          SizedBox(height: 12.h),
          AppButton(
            label: s.openExternally,
            icon: Icons.open_in_new_rounded,
            kind: AppButtonKind.subtle,
            onPressed: _openExternally,
          ),
        ],
      );
    }

    final VideoPlayerController? controller = _controller;
    if (controller == null) return const AppLoading();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: AppRadius.containerR,
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio == 0
                ? 16 / 9
                : controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                VideoPlayer(controller),
                VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: AppColors.primary,
                    bufferedColor: AppColors.primary.withOpacity(0.3),
                    backgroundColor: Colors.black26,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        // The controls are rebuilt from the controller itself, so the play /
        // pause glyph follows the video even when it ends on its own.
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (
            BuildContext context,
            VideoPlayerValue value,
            Widget? child,
          ) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  onPressed: () => controller.seekTo(
                    value.position - const Duration(seconds: 10),
                  ),
                  icon: const AppIcon(Icons.replay_10_rounded),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  iconSize: 44.sp,
                  onPressed: () => value.isPlaying
                      ? controller.pause()
                      : controller.play(),
                  icon: AppIcon(
                    value.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: () => controller.seekTo(
                    value.position + const Duration(seconds: 10),
                  ),
                  icon: const AppIcon(Icons.forward_10_rounded),
                ),
                SizedBox(width: 12.w),
                Text(
                  '${_clock(value.position)} / ${_clock(value.duration)}',
                  style: StyleText.fontSize12Weight500
                      .copyWith(color: AppColors.secondaryText),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  static String _clock(Duration d) {
    final String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }
}
