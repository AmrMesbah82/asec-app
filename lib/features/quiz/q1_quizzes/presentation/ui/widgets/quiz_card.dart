/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_card.dart
/// Purpose: Declares `QuizCard` — one quiz in a list, for the admin and for a
///          member.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_meta.dart';
import 'package:asec/generated/l10n.dart';

class QuizCard extends StatelessWidget {
  const QuizCard({
    super.key,
    required this.quiz,
    this.onTap,
    this.trailing,
    this.footer,
  });

  final Quiz quiz;
  final VoidCallback? onTap;

  /// The admin's overflow menu, or a member's score badge.
  final Widget? trailing;

  /// An extra line under the chips — "Taken · 8 / 10", say.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppIcon(
                  Icons.quiz_outlined,
                  size: 22.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        quiz.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize16Weight600,
                      ),
                      if (quiz.description.trim().isNotEmpty) ...<Widget>[
                        SizedBox(height: 4.h),
                        Text(
                          quiz.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize13Weight400
                              .copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: <Widget>[
                QuizChip(
                  icon: Icons.rule_rounded,
                  label: s.questionsCount('${quiz.questionCount}'),
                ),
                QuizChip(
                  icon: Icons.timer_outlined,
                  label: quiz.isTimed
                      ? s.minutesShort('${quiz.durationMinutes}')
                      : s.untimed,
                ),
                QuizWindowLabel(quiz: quiz),
                if (!quiz.published)
                  QuizChip(
                    icon: Icons.edit_note_rounded,
                    label: s.draft,
                    color: AppColors.statusPending,
                  ),
              ],
            ),
            if (footer != null) ...<Widget>[
              SizedBox(height: 10.h),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
