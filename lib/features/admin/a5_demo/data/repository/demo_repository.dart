/// Module: admin / a5_demo
///
///*************************** FILE INFO ****************************///
/// File Name: demo_repository.dart
/// Purpose: Declares `DemoRepository`.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:dartz/dartz.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/core/network/guard.dart';
import 'package:asec/features/admin/a5_demo/data/data_source/remote_data_source/demo_remote_data_source.dart';
import 'package:asec/features/admin/a5_demo/domain/base_repository/demo_base_repository.dart';

class DemoRepository implements DemoBaseRepository {
  DemoRepository({DemoRemoteDataSource? remote})
      : _remote = remote ?? DemoRemoteDataSource();

  final DemoRemoteDataSource _remote;

  @override
  Future<Either<AppFailure, DemoCounts>> fill({required String adminUid}) =>
      guard(() => _remote.fill(adminUid: adminUid));

  @override
  Future<Either<AppFailure, DemoCounts>> remove() => guard(_remote.remove);
}
