/// Module: core/network
///
///*************************** FILE INFO ****************************///
/// File Name: guard.dart
/// Purpose: `guard` / `guardUnit` — the try/catch every repository method
///          would otherwise repeat.
/// Author: Manger Plus team
/// Created: 18/9/2026

import 'package:dartz/dartz.dart';

import 'package:asec/core/network/app_failure.dart';

/// Runs [run]; a value becomes `Right`, any throw becomes `Left(AppFailure)`.
Future<Either<AppFailure, T>> guard<T>(Future<T> Function() run) async {
  try {
    return Right<AppFailure, T>(await run());
  } catch (error) {
    return Left<AppFailure, T>(AppFailure.from(error));
  }
}

/// [guard] for calls that return nothing.
Future<Either<AppFailure, Unit>> guardUnit(Future<void> Function() run) =>
    guard<Unit>(() async {
      await run();
      return unit;
    });
