/// Module: admin / a3_dashboard
///
///*************************** FILE INFO ****************************///
/// File Name: dashboard_table.dart
/// Purpose: Declares `DashboardTable` — the latest attempts, as rows.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// The app's own table (`100-custom_data_table`), so this list sorts, lays
/// itself out as cards on a tablet and reads exactly like every other table in
/// the app. `shrinkWrap` is on because the page is already scrolling — a table
/// scrolling inside a scrolling page is the one thing this layout must not do.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/100-custom_data_table.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a3_dashboard/presentation/ui/widgets/dashboard_data.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/attempt_detail_page.dart';
import 'package:asec/generated/l10n.dart';

class DashboardTable extends StatelessWidget {
  const DashboardTable({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final List<QuizAttempt> rows = data.latestAttempts();

    return AppCard(
      title: s.latestAttempts,
      caption: s.seeAllAttempts,
      child: AppDataTable<QuizAttempt>(
        shrinkWrap: true,
        showRowNumbers: true,
        rows: rows,
        emptyState: AppEmptyView(
          title: s.noAttemptsYet,
          subtitle: s.noAttemptsYetSub,
          size: 130,
        ),
        // A row is a person's sitting; tapping it opens that sitting in full.
        // A quiz deleted since then has nothing to open, so the row is inert.
        onRowTap: (QuizAttempt attempt) {
          final Quiz? quiz = data.quizFor(attempt);
          if (quiz == null) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AttemptDetailPage(quiz: quiz, attempt: attempt),
            ),
          );
        },
        columns: <AppTableColumn<QuizAttempt>>[
          AppTableColumn<QuizAttempt>(
            label: s.member,
            flex: 3,
            cell: (BuildContext context, QuizAttempt a) => AppTableCellText(
              a.userName.isEmpty ? a.userId : a.userName,
              emphasis: true,
            ),
          ),
          AppTableColumn<QuizAttempt>(
            label: s.quizLabel,
            flex: 3,
            cell: (BuildContext context, QuizAttempt a) =>
                AppTableCellText(a.quizTitle),
          ),
          AppTableColumn<QuizAttempt>(
            label: s.score,
            flex: 1,
            cell: (BuildContext context, QuizAttempt a) =>
                AppTableCellText('${a.score}/${a.totalPoints}'),
          ),
          AppTableColumn<QuizAttempt>(
            label: '%',
            fixedWidth: 64.w,
            alignment: Alignment.center,
            cell: (BuildContext context, QuizAttempt a) =>
                _PercentChip(percent: a.percent),
          ),
          AppTableColumn<QuizAttempt>(
            label: s.dateLabel,
            flex: 2,
            cell: (BuildContext context, QuizAttempt a) =>
                AppTableCellText(AppDates.dateTime(context, a.submittedAt)),
          ),
        ],
      ),
    );
  }
}

class _PercentChip extends StatelessWidget {
  const _PercentChip({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final Color color = percent >= 80
        ? AppColors.green
        : (percent >= 50 ? AppColors.statusPending : AppColors.red);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.buttonR,
      ),
      child: Text(
        '${percent.round()}%',
        textAlign: TextAlign.center,
        style: StyleText.fontSize12Weight700.copyWith(color: color),
      ),
    );
  }
}
