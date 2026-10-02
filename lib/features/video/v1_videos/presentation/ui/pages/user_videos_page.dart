/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: user_videos_page.dart
/// Purpose: Declares `UserVideosPage` — the lessons a member can watch, laid
///          out like a video site: a search box, filter chips, and a grid of
///          thumbnails with watch progress.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 25/9/2026 - Video-site layout, search and filters.
/// Updated: 1/10/2026 - Categories first (one per Drive sub-folder), then
///          the videos of the category opened. Lesson numbers, locks and
///          progress count within the category.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/base_repository/video_base_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/video_player_page.dart';
import 'package:asec/features/video/v1_videos/data/download/video_downloads.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_categories.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_download_button.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_grid.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/settings/app_features.dart';

enum _VideoFilter { all, recent, continueWatching, watched }

class UserVideosPage extends StatefulWidget {
  const UserVideosPage({super.key});

  @override
  State<UserVideosPage> createState() => _UserVideosPageState();
}

class _UserVideosPageState extends State<UserVideosPage> {
  final VideoBaseRepository _repository = VideoRepository();
  late final Stream<List<VideoItem>> _videos = _repository.watchPublished();
  final TextEditingController _search = TextEditingController();

  _VideoFilter _filter = _VideoFilter.all;
  String _query = '';

  /// The category opened; null = the category list.
  String? _category;

  /// The sub-folder opened inside [_category]; null = its sub-folder list.
  String? _subcategory;

  void _openCategory(String? name) => setState(() {
        _category = name;
        _subcategory = null;
        _resetSearch();
      });

  void _openSubcategory(String? name) => setState(() {
        _subcategory = name;
        _resetSearch();
      });

  void _resetSearch() {
    _filter = _VideoFilter.all;
    _query = '';
    _search.clear();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<VideoItem> _apply(List<VideoItem> all) {
    if (!AppFeatures.to.isOn(AppFeature.videoSearch)) return all;
    final String q = _query.trim().toLowerCase();
    return all.where((VideoItem v) {
      if (q.isNotEmpty &&
          !v.title.toLowerCase().contains(q) &&
          !v.description.toLowerCase().contains(q)) {
        return false;
      }
      final double p = VideoWatchStore.progress(v.id);
      switch (_filter) {
        case _VideoFilter.all:
          return true;
        case _VideoFilter.recent:
          return v.createdAt != null &&
              DateTime.now().difference(v.createdAt!).inDays < 14;
        case _VideoFilter.continueWatching:
          return p > 0 && p < 1;
        case _VideoFilter.watched:
          return p >= 1;
      }
    }).toList();
  }

  Future<void> _open(VideoItem video, List<VideoItem> playlist) async {
    final bool sequential = AppFeatures.to.isOn(AppFeature.videoSequential);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerPage(
          video: video,
          playlist: playlist,
          sequential: sequential,
        ),
      ),
    );
    // Progress bars and "watched" ticks changed while the player was open.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Obx(() {
    AppFeatures.to.values.length; // rebuild when a switch flips
    SessionController.to.user.value; // and when the admin changes my courses
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

          // Only the courses the admin opened for this member.
          final AppUser me = SessionController.to.current;
          final List<VideoItem> all = snapshot.data!
              .where((VideoItem v) => v.hasFile && me.canSeeCourse(v.category))
              .toList()
            // COURSE ORDER: the first lesson added is lesson 1.
            ..sort((VideoItem a, VideoItem b) => (a.createdAt ?? DateTime(0))
                .compareTo(b.createdAt ?? DateTime(0)));

          if (all.isEmpty) {
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosUserSub,
              child: AppEmptyView(
                title: s.noVideosTitle,
                subtitle: s.noVideosUserSub,
              ),
            );
          }

          final AppFeatures features = AppFeatures.to;

          // CATEGORIES FIRST. With more than one, the member picks a category
          // and only then sees its videos.
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
            final int watchedAll = all
                .where((VideoItem v) => VideoWatchStore.isWatched(v.id))
                .length;
            return ConsolePage(
              title: s.typeVideos,
              subtitle: s.videosUserSub,
              child: VideoCategoryGrid(
                categories: categories,
                onOpen: (VideoCategory c) => _openCategory(c.name),
                header: features.isOn(AppFeature.videoCourseProgress)
                    ? Padding(
                        padding: EdgeInsets.only(bottom: 18.h),
                        child: _CourseProgress(
                            watched: watchedAll, total: all.length),
                      )
                    : null,
              ),
            );
          }

          // SUB-FOLDERS NEXT. A category whose Drive folder holds folders
          // (AutoCAD → Introduction-01, Draw and Modify-02) shows them as a
          // second level of folders before any video.
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
                subtitle: s.videosUserSub,
                child: VideoCategoryGrid(
                  categories: subs,
                  onOpen: (VideoCategory c) => _openSubcategory(c.name),
                  header: grouped
                      ? VideoCategoryHeader(
                          category: category,
                          onBack: () => _openCategory(null),
                        )
                      : null,
                ),
              );
            }
            current = sub;
          }

          // From here on "the course" is the folder that is open.
          final List<VideoItem> course = current.videos;
          final List<VideoItem> shown = _apply(course);

          // Locks and numbers come from the WHOLE category, never the
          // filtered view — searching must not unlock anything.
          final Map<String, int> numbers = <String, int>{
            for (int i = 0; i < course.length; i++) course[i].id: i + 1,
          };
          final bool sequential = features.isOn(AppFeature.videoSequential);
          final Set<String> locked = sequential
              ? VideoWatchStore.lockedIds(
                  <String>[for (final VideoItem v in course) v.id],
                )
              : const <String>{};
          final int watched = course
              .where((VideoItem v) => VideoWatchStore.isWatched(v.id))
              .length;

          final Widget header = Padding(
            padding: EdgeInsets.only(bottom: 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (sub != null)
                  VideoCategoryHeader(
                    category: sub,
                    backLabel: category.label(s),
                    onBack: () => _openSubcategory(null),
                  )
                else if (grouped)
                  VideoCategoryHeader(
                    category: current,
                    onBack: () => _openCategory(null),
                  ),
                if (features.isOn(AppFeature.videoCourseProgress)) ...<Widget>[
                  _CourseProgress(watched: watched, total: course.length),
                  SizedBox(height: 16.h),
                ],
                if (features.isOn(AppFeature.videoSearch)) ...<Widget>[
                _SearchBox(
                  controller: _search,
                  hint: s.searchVideos,
                  onChanged: (String v) => setState(() => _query = v),
                  onClear: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
                SizedBox(height: 14.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (final (_VideoFilter f, String label) in <(_VideoFilter, String)>[
                        (_VideoFilter.all, s.filterAll),
                        (_VideoFilter.recent, s.filterRecent),
                        (_VideoFilter.continueWatching, s.filterContinue),
                        (_VideoFilter.watched, s.filterWatched),
                      ]) ...<Widget>[
                        _FilterChip(
                          label: label,
                          selected: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                        SizedBox(width: 8.w),
                      ],
                    ],
                  ),
                ),
                ],
                if (shown.isEmpty) ...<Widget>[
                  SizedBox(height: 40.h),
                  AppEmptyView(
                    title: s.noLessonsMatch,
                    subtitle: s.noLessonsMatchSub,
                  ),
                ],
              ],
            ),
          );

          return ConsolePage(
            title: s.typeVideos,
            subtitle: s.videosUserSub,
            child: VideoGrid(
              videos: shown,
              header: header,
              lockedIds: locked,
              lessonNumbers: numbers,
              // Save inside the app for offline. A locked lesson cannot be
              // downloaded — that would get round the order.
              trailingBuilder: VideoDownloads.supported
                  ? (VideoItem v) => locked.contains(v.id)
                      ? const SizedBox.shrink()
                      : VideoDownloadButton(video: v)
                  : null,
              onOpen: (VideoItem v) {
                if (locked.contains(v.id)) {
                  final int n = numbers[v.id]!;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Row(
                        children: <Widget>[
                          const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.finishLessonFirst(n - 1))),
                        ],
                      ),
                    ));
                  return;
                }
                _open(v, course);
              },
            ),
          );
        },
      ),
    );
    });
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.card,
            hintText: hint,
            hintStyle: StyleText.fontSize14Weight400
                .copyWith(color: AppColors.secondaryText),
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: AppIcon(Icons.search_rounded,
                  size: 20.sp, color: AppColors.secondaryText),
            ),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: AppIcon(Icons.close_rounded,
                        size: 18.sp, color: AppColors.secondaryText),
                  ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40.r),
              borderSide: BorderSide(
                  color: AppColors.secondaryText.withOpacity(0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40.r),
              borderSide: BorderSide(
                  color: AppColors.secondaryText.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40.r),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.text : AppColors.chip,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Text(
            label,
            style: StyleText.fontSize13Weight600.copyWith(
              color: selected ? AppColors.background : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// "3 of 10 lessons watched" with a bar — the course at a glance.
class _CourseProgress extends StatelessWidget {
  const _CourseProgress({required this.watched, required this.total});

  final int watched;
  final int total;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final double p = total == 0 ? 0 : watched / total;
    final bool done = total > 0 && watched >= total;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: AppColors.chip,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(
                done ? Icons.emoji_events_rounded : Icons.play_lesson_rounded,
                size: 20.sp,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        done ? s.courseComplete : s.courseProgress(watched, total),
                        style: StyleText.fontSize14Weight600
                            .copyWith(color: AppColors.text),
                      ),
                    ),
                    Text(
                      '${(p * 100).round()}%',
                      style: StyleText.fontSize13Weight600.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: p),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext context, double v, Widget? _) =>
                        LinearProgressIndicator(
                      value: v,
                      minHeight: 7.h,
                      backgroundColor:
                          AppColors.secondaryText.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        done ? const Color(0xFF16A34A) : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
