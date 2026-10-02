/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz.dart
/// Purpose: Declares `Quiz` — a timed set of multiple-choice questions.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/enums/quiz_window_state.dart';

class Quiz {
  final String id;
  final String title;
  final String description;

  /// The COUNTDOWN, in minutes, that starts when a member opens the quiz.
  /// Zero means untimed.
  final int durationMinutes;

  /// The WINDOW. Null on either side means "no bound that way", so both null
  /// is a quiz that is simply always open.
  final DateTime? opensAt;
  final DateTime? closesAt;

  /// Members only ever see published quizzes; the admin sees drafts too.
  final bool published;

  /// A CERTIFICATE QUIZ is a course's final exam: it lives in its own drawer
  /// tab, opens once every lesson of [course] is watched, may be retaken
  /// until passed, and a score of [passPercent] or more earns the member an
  /// ASEC certificate.
  final bool certificate;

  /// The video category (Drive folder) this exam closes. Certificate quizzes
  /// only.
  final String course;

  static const int passPercent = 70;

  final List<QuizQuestion> questions;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Quiz({
    required this.id,
    required this.title,
    this.description = '',
    this.durationMinutes = 0,
    this.opensAt,
    this.closesAt,
    this.published = false,
    this.certificate = false,
    this.course = '',
    this.questions = const <QuizQuestion>[],
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  static const Quiz empty = Quiz(id: '', title: '');

  bool get isTimed => durationMinutes > 0;
  int get questionCount => questions.length;

  int get totalPoints =>
      questions.fold<int>(0, (int sum, QuizQuestion q) => sum + q.points);

  /// Ready to publish: a title and at least one complete question.
  bool get isComplete =>
      title.trim().isNotEmpty &&
      questions.isNotEmpty &&
      questions.every((QuizQuestion q) => q.isComplete);

  /// The window is only backwards if BOTH bounds are set.
  bool get hasValidWindow =>
      opensAt == null || closesAt == null || closesAt!.isAfter(opensAt!);

  QuizWindowState windowStateAt(DateTime now) {
    if (opensAt != null && now.isBefore(opensAt!)) {
      return QuizWindowState.notOpenYet;
    }
    if (closesAt != null && now.isAfter(closesAt!)) {
      return QuizWindowState.closed;
    }
    return QuizWindowState.open;
  }

  /// Whether a member may start it right now.
  bool isAvailableAt(DateTime now) =>
      published && windowStateAt(now).isOpen && questions.isNotEmpty;

  /// How long an attempt started at [startedAt] may run.
  ///
  /// THE WINDOW CAPS THE COUNTDOWN. A 30-minute quiz started 10 minutes before
  /// it closes gets 10 minutes, not 30 — otherwise the countdown would keep
  /// running past a closing time the admin chose on purpose.
  Duration remainingFor(DateTime startedAt, DateTime now) {
    Duration? left;
    if (isTimed) {
      final DateTime deadline =
          startedAt.add(Duration(minutes: durationMinutes));
      left = deadline.difference(now);
    }
    if (closesAt != null) {
      final Duration untilClose = closesAt!.difference(now);
      left = left == null || untilClose < left ? untilClose : left;
    }
    if (left == null) return Duration.zero; // untimed and never closing
    return left.isNegative ? Duration.zero : left;
  }

  /// True when nothing bounds the attempt: no countdown and no closing time.
  bool get runsForever => !isTimed && closesAt == null;

  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    int? durationMinutes,
    Object? opensAt = _keep,
    Object? closesAt = _keep,
    bool? published,
    bool? certificate,
    String? course,
    List<QuizQuestion>? questions,
    String? createdBy,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      // `null` is a real value for the dates — "no bound" — so a sentinel is
      // what distinguishes "clear it" from "leave it alone".
      opensAt: opensAt == _keep ? this.opensAt : opensAt as DateTime?,
      closesAt: closesAt == _keep ? this.closesAt : closesAt as DateTime?,
      published: published ?? this.published,
      certificate: certificate ?? this.certificate,
      course: course ?? this.course,
      questions: questions ?? this.questions,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static const Object _keep = Object();
}
