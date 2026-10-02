/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_meta.dart
/// Purpose: Declares `QuizChip`, `QuizWindowLabel` and `CountdownPill` — the
///          small pieces every quiz screen shares.
/// Author: ASEC team
/// Created: 19/9/2026

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/enums/quiz_window_state.dart';
import 'package:asec/generated/l10n.dart';

/// An icon and a word on the shared chip ground — "12 questions", "20 min",
/// "Open now". Every chip looks the same: [AppColors.chip] behind,
/// [AppColors.onChip] ink. [color] is kept for callers but no longer paints
/// the chip — the icon and the word already say which state it is.
class QuizChip extends StatelessWidget {
  const QuizChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = AppColors.onChip;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: AppRadius.buttonR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(icon, size: 14.sp, color: c),
          SizedBox(width: 5.w),
          Text(
            label,
            style: StyleText.fontSize11Weight600.copyWith(color: c),
          ),
        ],
      ),
    );
  }
}

/// "Open now" / "Opens 3 Oct, 18:00" / "Closed" — the quiz's window in one
/// chip, in the colour that says whether it can be taken.
class QuizWindowLabel extends StatelessWidget {
  const QuizWindowLabel({super.key, required this.quiz, this.now});

  final Quiz quiz;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final DateTime at = now ?? DateTime.now();
    final QuizWindowState state = quiz.windowStateAt(at);

    switch (state) {
      case QuizWindowState.notOpenYet:
        return QuizChip(
          icon: Icons.schedule_rounded,
          label: s.quizNotOpenYet(AppDates.dateTime(context, quiz.opensAt)),
          color: AppColors.statusPending,
        );
      case QuizWindowState.closed:
        return QuizChip(
          icon: Icons.lock_outline_rounded,
          label: s.quizClosed,
          color: AppColors.red,
        );
      case QuizWindowState.open:
        return QuizChip(
          icon: Icons.check_circle_rounded,
          label: quiz.closesAt == null
              ? s.quizOpenNow
              : s.quizClosesOn(AppDates.dateTime(context, quiz.closesAt)),
          color: AppColors.green,
        );
    }
  }
}

/// The clock while a quiz is being taken. Turns red in the last minute.
class CountdownPill extends StatelessWidget {
  const CountdownPill({super.key, required this.remaining, this.urgent = false});

  final Duration remaining;
  final bool urgent;

  /// `mm:ss` under an hour, `h:mm:ss` over it.
  static String format(Duration d) {
    final int hours = d.inHours;
    final String minutes =
        (d.inMinutes % 60).toString().padLeft(2, '0');
    final String seconds =
        (d.inSeconds % 60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Chip ground and ink like every other pill; only the last minute
    // turns the time red, because that IS the message.
    final Color color = urgent ? AppColors.red : AppColors.onChip;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: AppRadius.buttonR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(Icons.timer_outlined, size: 16.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            format(remaining),
            style: StyleText.fontSize14Weight700.copyWith(
              color: color,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
