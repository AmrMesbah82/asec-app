/// Module: admin / a3_dashboard
///
///*************************** FILE INFO ****************************///
/// File Name: admin_dashboard_page.dart
/// Purpose: Declares `AdminDashboardPage` — the centre at a glance: the four
///          numbers, four charts, and the latest attempts as rows.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 20/9/2026 - Charts and a table, the way manger_plus's console
///          dashboard does it. The page was four tiles and a list before.
///
/// LAYOUT
/// ------
/// Tiles, charts, table — the same descent from "how are we doing" to "which
/// record" the manger_plus dashboard uses. The page scrolls as one column and
/// the table shrink-wraps, so there is never a scrollbar inside a scrollbar.
///
/// ONE READ, FOUR STREAMS. Members, videos, quizzes and attempts are combined
/// into a single snapshot ([DashboardData]) before anything is drawn: four
/// separate `StreamBuilder`s would each flash their own spinner, and two cards
/// could disagree about the same number mid-frame.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/69-cross_axis_count_helper.dart';
import 'package:asec/core/helper/main_helper/stream_combine.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/admin/a3_dashboard/presentation/ui/widgets/dashboard_charts.dart';
import 'package:asec/features/admin/a3_dashboard/presentation/ui/widgets/dashboard_data.dart';
import 'package:asec/features/admin/a3_dashboard/presentation/ui/widgets/dashboard_table.dart';
import 'package:asec/features/onboarding/o2_authentication/data/repository/auth_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/base_repository/auth_base_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/base_repository/quiz_base_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/base_repository/video_base_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/generated/l10n.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.admin});

  final AppUser admin;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final UsersBaseRepository _users = UsersRepository();
  final VideoBaseRepository _videos = VideoRepository();
  final QuizBaseRepository _quizzes = QuizRepository();

  late final Stream<DashboardData> _stream = combineLatest<Object, DashboardData>(
    <Stream<Object>>[
      _users.watchMembers(),
      _videos.watchAll(),
      _quizzes.watchAll(),
      _quizzes.watchAllAttempts(),
    ],
    (List<Object> values) => DashboardData(
      members: values[0] as List<AppUser>,
      videos: values[1] as List<VideoItem>,
      quizzes: values[2] as List<Quiz>,
      attempts: values[3] as List<QuizAttempt>,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DashboardData>(
        stream: _stream,
        builder: (BuildContext context, AsyncSnapshot<DashboardData> snapshot) {
          if (snapshot.hasError) return AppErrorView(message: s.errUnknown);
          if (!snapshot.hasData) return const AppLoading();

          final DashboardData data = snapshot.data!;

          return ConsolePage(
            title: s.helloName(widget.admin.firstName),
            subtitle: s.dashboardAsecSub,
            child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return ListView(
                padding: EdgeInsets.only(bottom: 16.h),
                children: <Widget>[
                  // ── The four numbers ─────────────────────────────────────
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: CrossAxisCountHelper.gridDelegate(
                      context,
                      mainAxisExtent: 110,
                      minCellWidth: 170,
                      availableWidth: constraints.maxWidth,
                    ),
                    children: <Widget>[
                      StatTile(
                        icon: Icons.groups_2_rounded,
                        label: s.totalMembers,
                        value: '${data.members.length}',
                      ),
                      StatTile(
                        icon: Icons.video_library_rounded,
                        label: s.totalVideos,
                        value: '${data.videos.length}',
                      ),
                      StatTile(
                        icon: Icons.quiz_outlined,
                        label: s.totalQuizzes,
                        value: '${data.quizzes.length}',
                      ),
                      StatTile(
                        icon: Icons.fact_check_rounded,
                        label: s.totalAttempts,
                        value: '${data.attempts.length}',
                        caption: data.hasAttempts
                            ? '${s.average} ${data.averagePercent}%'
                            : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // ── The charts ───────────────────────────────────────────
                  AppSectionHeader(
                    title: s.charts,
                    caption: data.hasAttempts ? null : s.nothingToChartAsec,
                  ),
                  SizedBox(height: 12.h),
                  DashboardCharts(data: data),
                  SizedBox(height: 20.h),

                  // ── The records ──────────────────────────────────────────
                  DashboardTable(data: data),
                  SizedBox(height: 24.h),
                ],
              );
            },
          ),
          );
        },
      ),
    );
  }
}

/// One number with its icon. Public so the charts row and the tiles row can
/// never drift apart in padding or type scale.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;

  /// A second line under the label — "Average 72%", say.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: AppIcon(icon, size: 22.sp, color: AppColors.primary),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(value, style: StyleText.fontSize22Weight700),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.secondaryText),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize11Weight600
                        .copyWith(color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
