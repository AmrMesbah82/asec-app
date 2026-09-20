/// Module: admin / a5_demo
///
///*************************** FILE INFO ****************************///
/// File Name: demo_base_repository.dart
/// Purpose: The contract the demo-data repository implements.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:dartz/dartz.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/features/admin/a5_demo/data/data_source/remote_data_source/demo_remote_data_source.dart';

abstract class DemoBaseRepository {
  /// Writes the whole sample set. Safe to call twice: the ids are fixed, so a
  /// second run refreshes the same documents.
  Future<Either<AppFailure, DemoCounts>> fill({required String adminUid});

  /// Deletes every document marked `demo: true`.
  Future<Either<AppFailure, DemoCounts>> remove();
}
