/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_base_repository.dart
/// Purpose: Declares `QuizBaseRepository`.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:dartz/dartz.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';

abstract class QuizBaseRepository {
  /// Every quiz, drafts included — the admin's list.
  Stream<List<Quiz>> watchAll();

  /// Published quizzes only — what a member is allowed to read.
  Stream<List<Quiz>> watchPublished();

  Stream<Quiz?> watchQuiz(String id);

  Future<Either<AppFailure, String>> create(Quiz quiz);

  Future<Either<AppFailure, Unit>> update(Quiz quiz);

  Future<Either<AppFailure, Unit>> setPublished(String id, bool published);

  /// Deletes the quiz AND every attempt on it.
  Future<Either<AppFailure, Unit>> delete(String id);

  // ── Attempts ─────────────────────────────────────────────────────────────

  /// Every attempt on one quiz — the admin's results table.
  Stream<List<QuizAttempt>> watchAttemptsFor(String quizId);

  /// One member's attempts, newest first.
  Stream<List<QuizAttempt>> watchMyAttempts(String uid);

  /// Every attempt in the app — the admin's dashboard count.
  Stream<List<QuizAttempt>> watchAllAttempts();

  Future<QuizAttempt?> fetchAttempt(String quizId, String uid);

  Future<Either<AppFailure, Unit>> submitAttempt(QuizAttempt attempt);
}
