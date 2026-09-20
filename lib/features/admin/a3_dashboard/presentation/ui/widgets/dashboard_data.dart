/// Module: admin / a3_dashboard
///
///*************************** FILE INFO ****************************///
/// File Name: dashboard_data.dart
/// Purpose: Declares `DashboardData` — everything the dashboard draws, worked
///          out once from the four live streams.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// THE MATHS LIVES HERE, NOT IN THE WIDGETS.
/// A chart card that computes its own series recomputes it on every rebuild
/// and, worse, two cards can disagree about the same number. This class is
/// built once per snapshot; the cards only turn its lists into `ChartData`.

import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';

/// One bar / slice: a label and a number, before any widget sees it.
class Series {
  const Series(this.label, this.value);

  final String label;
  final double value;
}

class DashboardData {
  DashboardData({
    required this.members,
    required this.videos,
    required this.quizzes,
    required this.attempts,
  });

  final List<AppUser> members;
  final List<VideoItem> videos;
  final List<Quiz> quizzes;
  final List<QuizAttempt> attempts;

  bool get hasAttempts => attempts.isNotEmpty;

  /// The average of every attempt's percentage, rounded. 0 with no attempts.
  int get averagePercent {
    if (attempts.isEmpty) return 0;
    final double sum = attempts.fold<double>(
      0,
      (double total, QuizAttempt a) => total + a.percent,
    );
    return (sum / attempts.length).round();
  }

  /// How many attempts fall in each band. The four bands cover 0–100 with no
  /// gap and no overlap, which is what makes a ring the honest shape for them.
  ///
  /// Index 0 = below 50, 1 = 50–64, 2 = 65–79, 3 = 80–100.
  List<int> get scoreBands {
    final List<int> bands = <int>[0, 0, 0, 0];
    for (final QuizAttempt a in attempts) {
      final double p = a.percent;
      if (p >= 80) {
        bands[3]++;
      } else if (p >= 65) {
        bands[2]++;
      } else if (p >= 50) {
        bands[1]++;
      } else {
        bands[0]++;
      }
    }
    return bands;
  }

  /// Attempts per day for the last [days] days, oldest first.
  ///
  /// Every day is present even when nobody sat anything — a bar chart with the
  /// empty days missing lies about the shape of the week.
  List<Series> attemptsByDay({int days = 7}) {
    final DateTime today = DateTime.now();
    final DateTime start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));

    final Map<String, int> counts = <String, int>{};
    for (final QuizAttempt a in attempts) {
      final DateTime? at = a.submittedAt;
      if (at == null) continue;
      final DateTime day = DateTime(at.year, at.month, at.day);
      if (day.isBefore(start)) continue;
      counts[_key(day)] = (counts[_key(day)] ?? 0) + 1;
    }

    return <Series>[
      for (int i = 0; i < days; i++)
        () {
          final DateTime day = start.add(Duration(days: i));
          return Series(_dayLabel(day), (counts[_key(day)] ?? 0).toDouble());
        }(),
    ];
  }

  /// Average percentage per quiz, best first. Quizzes nobody has sat are left
  /// out: a zero bar would read as "everybody failed it".
  List<Series> averageByQuiz({int take = 6}) {
    final List<Series> rows = <Series>[];
    for (final Quiz quiz in quizzes) {
      final List<QuizAttempt> mine = attempts
          .where((QuizAttempt a) => a.quizId == quiz.id)
          .toList();
      if (mine.isEmpty) continue;
      final double avg = mine.fold<double>(
            0,
            (double total, QuizAttempt a) => total + a.percent,
          ) /
          mine.length;
      rows.add(Series(quiz.title, avg.roundToDouble()));
    }
    rows.sort((Series a, Series b) => b.value.compareTo(a.value));
    return rows.take(take).toList();
  }

  /// Average percentage per member, best first.
  List<Series> topMembers({int take = 5}) {
    final Map<String, List<QuizAttempt>> byUser = <String, List<QuizAttempt>>{};
    for (final QuizAttempt a in attempts) {
      byUser.putIfAbsent(a.userId, () => <QuizAttempt>[]).add(a);
    }

    final List<Series> rows = <Series>[];
    byUser.forEach((String uid, List<QuizAttempt> list) {
      final double avg = list.fold<double>(
            0,
            (double total, QuizAttempt a) => total + a.percent,
          ) /
          list.length;
      final String name = list.first.userName.isNotEmpty
          ? list.first.userName
          : uid;
      rows.add(Series(name, avg.roundToDouble()));
    });
    rows.sort((Series a, Series b) => b.value.compareTo(a.value));
    return rows.take(take).toList();
  }

  /// The newest attempts, for the table at the bottom of the page.
  List<QuizAttempt> latestAttempts({int take = 8}) {
    final List<QuizAttempt> list = attempts.toList()
      ..sort((QuizAttempt a, QuizAttempt b) => (b.submittedAt ?? DateTime(0))
          .compareTo(a.submittedAt ?? DateTime(0)));
    return list.take(take).toList();
  }

  /// The quiz an attempt belongs to, or null if it has been deleted.
  Quiz? quizFor(QuizAttempt attempt) {
    for (final Quiz quiz in quizzes) {
      if (quiz.id == attempt.quizId) return quiz;
    }
    return null;
  }

  static String _key(DateTime day) => '${day.year}-${day.month}-${day.day}';

  /// Short enough to fit under a bar: "19/9".
  static String _dayLabel(DateTime day) => '${day.day}/${day.month}';
}
