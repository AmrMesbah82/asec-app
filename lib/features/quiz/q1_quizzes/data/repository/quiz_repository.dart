/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_repository.dart
/// Purpose: Declares `QuizRepository`.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:dartz/dartz.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/core/network/guard.dart';
import 'package:asec/features/quiz/q1_quizzes/data/data_source/remote_data_source/quiz_remote_data_source.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/base_repository/quiz_base_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';

class QuizRepository implements QuizBaseRepository {
  QuizRepository({QuizRemoteDataSource? remote})
      : _remote = remote ?? QuizRemoteDataSource();

  final QuizRemoteDataSource _remote;

  @override
  Stream<List<Quiz>> watchAll() => _remote.watchAll();

  @override
  Stream<List<Quiz>> watchPublished() => _remote.watchPublished();

  @override
  Stream<Quiz?> watchQuiz(String id) => _remote.watchQuiz(id);

  @override
  Future<Either<AppFailure, String>> create(Quiz quiz) =>
      guard(() => _remote.create(quiz));

  @override
  Future<Either<AppFailure, Unit>> update(Quiz quiz) =>
      guardUnit(() => _remote.update(quiz));

  @override
  Future<Either<AppFailure, Unit>> setPublished(String id, bool published) =>
      guardUnit(() => _remote.setPublished(id, published));

  @override
  Future<Either<AppFailure, Unit>> delete(String id) =>
      guardUnit(() => _remote.delete(id));

  @override
  Stream<List<QuizAttempt>> watchAttemptsFor(String quizId) =>
      _remote.watchAttemptsFor(quizId);

  @override
  Stream<List<QuizAttempt>> watchMyAttempts(String uid) =>
      _remote.watchMyAttempts(uid);

  @override
  Stream<List<QuizAttempt>> watchAllAttempts() => _remote.watchAllAttempts();

  @override
  Future<QuizAttempt?> fetchAttempt(String quizId, String uid) =>
      _remote.fetchAttempt(quizId, uid);

  @override
  Future<Either<AppFailure, Unit>> submitAttempt(QuizAttempt attempt) =>
      guardUnit(() => _remote.submitAttempt(attempt));
}
