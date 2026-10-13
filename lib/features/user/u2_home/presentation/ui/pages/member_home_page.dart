/// Module: user / u2_home
///
///*************************** FILE INFO ****************************///
/// File Name: member_home_page.dart
/// Purpose: Declares `MemberHomePage` — the first screen a member sees: a
///          greeting with their overall progress, the lesson to resume, quick
///          access to the main sections and their courses at a glance.
/// Author: ASEC team
/// Created: 13/10/2026
///
/// READ-ONLY. Everything here comes from what already exists: the published
/// lessons (the same stream the Videos page reads), the watch progress kept on
/// the device (VideoWatchStore) and the member's own switches. Tapping a tile
/// switches the shell's section (AppShell.open) or opens a "My space" page on
/// top of it.
///
/// THE MAIN THREE come first and biggest: Videos, the unit converter and the
/// quizzes; CVs and the "My space" pages follow as smaller tiles.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/app_shell.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/widgets/member_links.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/base_repository/video_base_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_player_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_categories.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';
import 'package:asec/generated/l10n.dart';

/// Section ids the home page jumps to (see UserShell).
abstract final class MemberSectionIds {
  static const String home = 'home';
  static const String videos = 'videos';
  static const String converter = 'converter';
  static const String quizzes = 'quizzes';
  static const String cvs = 'cvs';
  static const String settings = 'settings';
}

class MemberHomePage extends StatefulWidget {
  const MemberHomePage({super.key});

  @override
  State<MemberHomePage> createState() => _MemberHomePageState();
}

class _MemberHomePageState extends State<MemberHomePage> {
  final VideoBaseRepository _repository = VideoRepository();
  late final Stream<List<VideoItem>> _videos = _repository.watchPublished();

  /// Watch progress is written to the device while a lesson plays (from the
  /// Videos tab too), so the page listens and refreshes — at most once a
  /// second, not on every saved position.
  VoidCallback? _unlisten;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _unlisten = GetStorage().listen(() {
      if (_debounce?.isActive ?? false) return;
      _debounce = Timer(const Duration(seconds: 1), () {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _unlisten?.call();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _play(VideoItem video, List<VideoItem> playlist) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerPage(
          video: video,
          playlist: playlist,
          sequential: AppFeatures.to.isOn(AppFeature.videoSequential),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      AppFeatures.to.values.length; // a switch flipped live
      final AppUser me = SessionController.to.current;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: StreamBuilder<List<VideoItem>>(
          stream: _videos,
          builder: (BuildContext context, AsyncSnapshot<List<VideoItem>> snap) {
            final bool videosOn = AppFeatures.to.isOn(AppFeature.sectionVideos);
            final List<VideoItem> all = !videosOn || !snap.hasData
                ? const <VideoItem>[]
                : (snap.data!
                    .where((VideoItem v) => v.hasFile && me.canSeeCourse(v.category))
                    .toList()
                  ..sort((VideoItem a, VideoItem b) => (a.createdAt ?? DateTime(0))
                      .compareTo(b.createdAt ?? DateTime(0))));
            return _HomeBody(
              user: me,
              videos: all,
              loading: videosOn && !snap.hasData && !snap.hasError,
              onPlay: _play,
            );
          },
        ),
      );
    });
  }
}

/// The lesson to resume and the course it belongs to.
class _Resume {
  const _Resume(this.video, this.course, this.started);

  final VideoItem video;

  /// The folder the lesson sits in — its playlist and its numbering.
  final List<VideoItem> course;

  /// True = half-watched (resume); false = the next lesson not yet begun.
  final bool started;

  int get number => course.indexWhere((VideoItem v) => v.id == video.id) + 1;

  /// The first half-watched lesson; failing that, the first one not watched.
  static _Resume? pick(List<VideoItem> all) {
    if (all.isEmpty) return null;
    // Courses in the same order the Videos page shows them.
    final List<List<VideoItem>> courses = <List<VideoItem>>[
      for (final VideoCategory c in VideoCategory.group(all))
        for (final VideoCategory sub in VideoCategory.group(c.videos, bySubcategory: true))
          sub.videos,
    ];
    for (final List<VideoItem> course in courses) {
      for (final VideoItem v in course) {
        final double p = VideoWatchStore.progress(v.id);
        if (p > 0 && p < 1 && !VideoWatchStore.isWatched(v.id)) {
          return _Resume(v, course, true);
        }
      }
    }
    for (final List<VideoItem> course in courses) {
      for (final VideoItem v in course) {
        if (!VideoWatchStore.isWatched(v.id)) return _Resume(v, course, false);
      }
    }
    return null;
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.user,
    required this.videos,
    required this.loading,
    required this.onPlay,
  });

  final AppUser user;
  final List<VideoItem> videos;
  final bool loading;
  final Future<void> Function(VideoItem video, List<VideoItem> playlist) onPlay;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final AppFeatures f = AppFeatures.to;

    final int total = videos.length;
    final int watched =
        videos.where((VideoItem v) => VideoWatchStore.isWatched(v.id)).length;
    final _Resume? resume = _Resume.pick(videos);
    final List<VideoCategory> courses = VideoCategory.group(videos);

    void go(String id, [MemberLink? fallback]) {
      if (!AppShell.open(context, id)) fallback?.open(context);
    }

    final List<_Tile> main = <_Tile>[
      if (f.isOn(AppFeature.sectionVideos))
        _Tile(
          icon: Icons.video_library_rounded,
          label: s.typeVideos,
          hint: s.homeVideosHint,
          onTap: () => go(MemberSectionIds.videos),
        ),
      _Tile(
        icon: Icons.calculate_rounded,
        label: s.unitConverter,
        hint: s.homeConverterHint,
        onTap: () => go(MemberSectionIds.converter),
      ),
      if (f.isOn(AppFeature.sectionQuizzes))
        _Tile(
          icon: Icons.quiz_outlined,
          label: s.quizzes,
          hint: s.homeQuizzesHint,
          onTap: () => go(MemberSectionIds.quizzes),
        ),
    ];
    final List<_Tile> more = <_Tile>[
      if (f.isOn(AppFeature.sectionCvDirectory))
        _Tile(
          icon: Icons.assignment_outlined,
          label: s.cvs,
          hint: s.homeCvsHint,
          onTap: () => go(MemberSectionIds.cvs),
        ),
      for (final MemberLink link in MemberLinks.forUser(context, user))
        _Tile(
          icon: link.icon,
          label: link.label,
          hint: link.hint,
          onTap: () => link.open(context),
        ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool wide = c.maxWidth >= 900;

        final Widget hero = _HeroCard(
          user: user,
          watched: watched,
          total: total,
          showProgress: f.isOn(AppFeature.sectionVideos) && total > 0,
        );

        final Widget? resumeCard = !f.isOn(AppFeature.sectionVideos) || (total == 0 && !loading)
            ? null
            : _ResumeCard(
                resume: resume,
                loading: loading,
                allDone: total > 0 && watched == total,
                onPlay: onPlay,
                onBrowse: () => go(MemberSectionIds.videos),
              );

        final Widget tiles = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SectionTitle(s.homeQuickAccess),
            SizedBox(height: 10.h),
            _TileGrid(tiles: main, big: true),
            if (more.isNotEmpty) ...<Widget>[
              SizedBox(height: 12.h),
              _TileGrid(tiles: more, big: false),
            ],
          ],
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppPadding.h, 20.h, AppPadding.h, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FadeSlideIn(child: hero),
              SizedBox(height: 20.h),
              if (wide && resumeCard != null)
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 5, child: resumeCard),
                      SizedBox(width: 20.w),
                      Expanded(flex: 6, child: tiles),
                    ],
                  ),
                )
              else ...<Widget>[
                if (resumeCard != null) ...<Widget>[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: resumeCard,
                  ),
                  SizedBox(height: 20.h),
                ],
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: tiles,
                ),
              ],
              if (courses.isNotEmpty) ...<Widget>[
                SizedBox(height: 24.h),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: _CoursesStrip(
                    courses: courses,
                    onSeeAll: () => go(MemberSectionIds.videos),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Hero ────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.user,
    required this.watched,
    required this.total,
    required this.showProgress,
  });

  final AppUser user;
  final int watched;
  final int total;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final double ratio = total == 0 ? 0 : watched / total;

    final Widget greeting = Row(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(3.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 2),
          ),
          child: AppAvatar(name: user.displayName, size: 54),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                s.homeGreeting(user.firstName),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize22Weight700.copyWith(color: Colors.white),
              ),
              SizedBox(height: 4.h),
              Text(
                s.homeSub,
                style: StyleText.fontSize14Weight400
                    .copyWith(color: Colors.white.withOpacity(0.85)),
              ),
            ],
          ),
        ),
      ],
    );

    final Widget progress = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Ring(value: ratio),
        SizedBox(width: 14.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                s.homeProgress,
                style: StyleText.fontSize12Weight600
                    .copyWith(color: Colors.white.withOpacity(0.8)),
              ),
              SizedBox(height: 2.h),
              Text(
                s.courseProgress(watched, total),
                style: StyleText.fontSize15Weight600.copyWith(color: Colors.white),
              ),
              if (total > watched) ...<Widget>[
                SizedBox(height: 2.h),
                Text(
                  s.homeLessonsLeft(total - watched),
                  style: StyleText.fontSize12Weight500
                      .copyWith(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          // Two soft circles — depth without an image to load.
          PositionedDirectional(
            end: -60,
            top: -70,
            child: _Bubble(size: 220, opacity: 0.10),
          ),
          PositionedDirectional(
            end: 120,
            bottom: -90,
            child: _Bubble(size: 180, opacity: 0.07),
          ),
          Padding(
            padding: EdgeInsets.all(22.r),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                if (!showProgress) return greeting;
                if (c.maxWidth >= 640) {
                  return Row(
                    children: <Widget>[
                      Expanded(child: greeting),
                      SizedBox(width: 20.w),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 300.w),
                        child: progress,
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    greeting,
                    SizedBox(height: 18.h),
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: progress,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );
}

/// The overall progress as a ring with the percentage inside.
class _Ring extends StatelessWidget {
  const _Ring({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final double size = 64.r;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double v, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CircularProgressIndicator(
              value: v,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            Center(
              child: Text(
                '${(v * 100).round()}%',
                style: StyleText.fontSize14Weight700.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Continue watching ───────────────────────────────────────────────────────

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.resume,
    required this.loading,
    required this.allDone,
    required this.onPlay,
    required this.onBrowse,
  });

  final _Resume? resume;
  final bool loading;
  final bool allDone;
  final Future<void> Function(VideoItem video, List<VideoItem> playlist) onPlay;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final _Resume? r = resume;

    Widget content;
    if (loading) {
      content = SizedBox(height: 140.h, child: const AppLoading());
    } else if (r == null) {
      content = _Message(
        icon: allDone ? Icons.emoji_events_rounded : Icons.play_lesson_rounded,
        title: allDone ? s.homeAllDone : s.homeStart,
        subtitle: allDone ? null : s.homeStartSub,
        action: AppButton(
          label: s.typeVideos,
          icon: Icons.video_library_rounded,
          kind: AppButtonKind.subtle,
          dense: true,
          onPressed: onBrowse,
        ),
      );
    } else {
      final double p = r.started ? VideoWatchStore.progress(r.video.id) : 0;
      final String category = r.video.category.trim().isEmpty
          ? s.videoCategoryGeneral
          : r.video.category.trim();
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // A "screen" with a big play button — the lesson is one tap away.
          AspectRatio(
            aspectRatio: 16 / 7,
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: () => onPlay(r.video, r.course),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        AppColors.primary.withOpacity(0.92),
                        AppColors.primary.withOpacity(0.65),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: <Widget>[
                      PositionedDirectional(
                        start: 14.w,
                        top: 12.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            s.homeLessonOf(r.number, r.course.length),
                            style: StyleText.fontSize11Weight600.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 58.r,
                          height: 58.r,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 34.r,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (p > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: p,
                            minHeight: 4,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StyleText.fontSize12Weight600.copyWith(color: AppColors.primary),
          ),
          SizedBox(height: 4.h),
          Text(
            r.video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
          ),
          SizedBox(height: 14.h),
          Row(
            children: <Widget>[
              if (p > 0)
                Expanded(
                  child: Text(
                    '${(p * 100).round()}%',
                    style: StyleText.fontSize13Weight500
                        .copyWith(color: AppColors.secondaryText),
                  ),
                )
              else
                const Spacer(),
              AppButton(
                label: r.started ? s.homeResume : s.homeStart,
                icon: Icons.play_arrow_rounded,
                dense: true,
                onPressed: () => onPlay(r.video, r.course),
              ),
            ],
          ),
        ],
      );
    }

    return _Panel(
      title: s.homeContinue,
      child: content,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 18.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32.r, color: AppColors.primary),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
          ),
          if (subtitle != null) ...<Widget>[
            SizedBox(height: 4.h),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: StyleText.fontSize13Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
          ],
          if (action != null) ...<Widget>[
            SizedBox(height: 14.h),
            action!,
          ],
        ],
      ),
    );
  }
}

// ── Quick access ────────────────────────────────────────────────────────────

class _Tile {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles, required this.big});

  final List<_Tile> tiles;

  /// The main three: taller, icon on top. The rest: one compact row each.
  final bool big;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double gap = 12.w;
        // The main three always share one row; the rest flow two or three
        // to a row on wider screens, one per row on a phone.
        final int cols = big
            ? tiles.length
            : math.max(1, math.min(tiles.length, (c.maxWidth + gap) ~/ (230 + gap)));
        final double width = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (int i = 0; i < tiles.length; i++)
              SizedBox(
                width: width,
                child: _TileCard(tile: tiles[i], big: big, index: i),
              ),
          ],
        );
      },
    );
  }
}

class _TileCard extends StatefulWidget {
  const _TileCard({required this.tile, required this.big, required this.index});

  final _Tile tile;
  final bool big;
  final int index;

  @override
  State<_TileCard> createState() => _TileCardState();
}

class _TileCardState extends State<_TileCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final _Tile t = widget.tile;
    final Color accent = AppColors.primary;

    final Widget badge = Container(
      width: (widget.big ? 46 : 40).r,
      height: (widget.big ? 46 : 40).r,
      decoration: BoxDecoration(
        color: accent.withOpacity(_hover ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: AppIcon(t.icon, size: (widget.big ? 24 : 21).sp, color: accent),
    );

    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.label,
          maxLines: widget.big ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: StyleText.fontSize15Weight600.copyWith(color: AppColors.text),
        ),
        if (t.hint != null) ...<Widget>[
          SizedBox(height: 2.h),
          Text(
            t.hint!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.secondaryText),
          ),
        ],
      ],
    );

    final Widget body = widget.big
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  badge,
                  const Spacer(),
                  AppIcon(
                    Icons.arrow_forward_rounded,
                    size: 18.sp,
                    color: _hover ? accent : AppColors.secondaryText.withOpacity(0.6),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              text,
            ],
          )
        : Row(
            children: <Widget>[
              badge,
              SizedBox(width: 12.w),
              Expanded(child: text),
              AppIcon(
                Icons.chevron_right_rounded,
                size: 20.sp,
                color: AppColors.secondaryText.withOpacity(0.7),
              ),
            ],
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 160),
        offset: Offset(0, _hover ? -0.02 : 0),
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: t.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.all(widget.big ? 16.r : 12.r),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: _hover
                      ? accent.withOpacity(0.35)
                      : AppColors.secondaryText.withOpacity(0.08),
                ),
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Courses ─────────────────────────────────────────────────────────────────

class _CoursesStrip extends StatelessWidget {
  const _CoursesStrip({required this.courses, required this.onSeeAll});

  final List<VideoCategory> courses;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _SectionTitle(s.homeCourses)),
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                s.homeSeeAll,
                style: StyleText.fontSize13Weight600.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double gap = 12.w;
            final int cols = math.max(1, math.min(4, (c.maxWidth + gap) ~/ (240 + gap)));
            final double width = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: <Widget>[
                for (final VideoCategory course in courses)
                  SizedBox(
                    width: width,
                    child: _CourseCard(course: course, onTap: onSeeAll),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final VideoCategory course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final int total = course.videos.length;
    final int watched = course.watched;
    final double ratio = total == 0 ? 0 : watched / total;
    final bool done = total > 0 && watched == total;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      color: (done ? AppColors.statusApproved : AppColors.primary)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : Icons.folder_rounded,
                      size: 20.r,
                      color: done ? AppColors.statusApproved : AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      course.label(s),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    done ? AppColors.statusApproved : AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                s.courseProgress(watched, total),
                style: StyleText.fontSize12Weight500
                    .copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pieces ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: StyleText.fontSize18Weight600.copyWith(color: AppColors.text),
      );
}

/// A titled card in the house surface.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.secondaryText.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _SectionTitle(title),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }
}
