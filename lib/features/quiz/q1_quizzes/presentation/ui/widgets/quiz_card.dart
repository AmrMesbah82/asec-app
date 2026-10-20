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
import 'package:asec/core/helper/main_helper/format_helper.dart';

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
      // COMPACT: title and description on one line each, the chips on one
      // line that scrolls sideways instead of wrapping — about half the
      // height the card used to take.
      child: AppCard(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: AppIcon(
                      quiz.certificate
                          ? Icons.workspace_premium_rounded
                          : Icons.quiz_outlined,
                      size: 19.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        FormatHelper.capitalize(quiz.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize15Weight600,
                      ),
                      if (quiz.description.trim().isNotEmpty)
                        Text(
                          FormatHelper.capitalize(quiz.description),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize12Weight400
                              .copyWith(color: AppColors.secondaryText),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: 10.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  if (quiz.certificate) ...<Widget>[
                    QuizChip(
                      icon: Icons.folder_rounded,
                      label: quiz.course.isEmpty ? s.chooseCourse : quiz.course,
                      color: quiz.course.isEmpty ? AppColors.statusPending : null,
                    ),
                    SizedBox(width: 6.w),
                  ],
                  QuizChip(
                    icon: Icons.rule_rounded,
                    label: s.questionsCount('${quiz.questionCount}'),
                  ),
                  SizedBox(width: 6.w),
                  QuizChip(
                    icon: Icons.timer_outlined,
                    label: quiz.isTimed
                        ? s.minutesShort('${quiz.durationMinutes}')
                        : s.untimed,
                  ),
                  SizedBox(width: 6.w),
                  QuizWindowLabel(quiz: quiz),
                  if (!quiz.published) ...<Widget>[
                    SizedBox(width: 6.w),
                    QuizChip(
                      icon: Icons.edit_note_rounded,
                      label: s.draft,
                      color: AppColors.statusPending,
                    ),
                  ],
                ],
              ),
            ),
            if (footer != null) ...<Widget>[
              SizedBox(height: 8.h),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
