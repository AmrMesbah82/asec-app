/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_attempt.dart
/// Purpose: Declares `QuizAttempt` — one member's run at one quiz.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';

/// Stored at `attempts/{quizId}_{uid}` — one per member per quiz, so the id
/// itself enforces "one attempt" and the rules can read the owner off the path.
class QuizAttempt {
  final String id;
  final String quizId;
  final String quizTitle;
  final String userId;
  final String userName;

  /// Stored on the attempt rather than looked up later: the admin's results
  /// table must still name the person after the account is gone.
  final String userEmail;

  /// question id -> the index the member chose. A question they skipped is
  /// simply absent.
  final Map<String, int> answers;

  final int score;
  final int totalPoints;
  final int correctCount;
  final int questionCount;

  final DateTime? startedAt;
  final DateTime? submittedAt;

  /// True when the countdown ran out and the app submitted for them.
  final bool autoSubmitted;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    this.quizTitle = '',
    this.userName = '',
    this.userEmail = '',
    this.answers = const <String, int>{},
    this.score = 0,
    this.totalPoints = 0,
    this.correctCount = 0,
    this.questionCount = 0,
    this.startedAt,
    this.submittedAt,
    this.autoSubmitted = false,
  });

  double get percent => totalPoints == 0 ? 0 : (score / totalPoints) * 100;

  /// How long the sitting actually took. Null until both ends are known.
  Duration? get timeTaken => startedAt == null || submittedAt == null
      ? null
      : submittedAt!.difference(startedAt!);

  /// Questions they never touched — a blank is wrong, but it is a different
  /// kind of wrong and the admin can see which.
  int blanksIn(List<String> questionIds) =>
      questionIds.where((String id) => !answers.containsKey(id)).length;

  /// Marks [answers] against [quiz]. The client computes this for the result
  /// screen; `firestore.rules` treats the stored score as a claim the admin
  /// can always re-check against the same answers.
  factory QuizAttempt.marked({
    required Quiz quiz,
    required String userId,
    required String userName,
    required String userEmail,
    required Map<String, int> answers,
    required DateTime startedAt,
    required DateTime submittedAt,
    bool autoSubmitted = false,
  }) {
    int score = 0;
    int correct = 0;
    for (final QuizQuestion question in quiz.questions) {
      if (question.isCorrect(answers[question.id])) {
        score += question.points;
        correct++;
      }
    }
    return QuizAttempt(
      id: '',
      quizId: quiz.id,
      quizTitle: quiz.title,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      answers: answers,
      score: score,
      totalPoints: quiz.totalPoints,
      correctCount: correct,
      questionCount: quiz.questionCount,
      startedAt: startedAt,
      submittedAt: submittedAt,
      autoSubmitted: autoSubmitted,
    );
  }
}
