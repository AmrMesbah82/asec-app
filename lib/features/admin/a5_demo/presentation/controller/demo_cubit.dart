/// Module: admin / a5_demo
///
///*************************** FILE INFO ****************************///
/// File Name: demo_cubit.dart
/// Purpose: Declares `DemoCubit` and `DemoState` — the two buttons' state.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/features/admin/a5_demo/data/data_source/remote_data_source/demo_remote_data_source.dart';
import 'package:asec/features/admin/a5_demo/data/repository/demo_repository.dart';
import 'package:asec/features/admin/a5_demo/domain/base_repository/demo_base_repository.dart';

enum DemoStatus { idle, filling, removing, filled, removed, failure }

class DemoState {
  final DemoStatus status;

  /// What the last run wrote or deleted. Null before the first run.
  final DemoCounts? counts;

  final AppFailure? failure;

  const DemoState({
    this.status = DemoStatus.idle,
    this.counts,
    this.failure,
  });

  bool get isBusy =>
      status == DemoStatus.filling || status == DemoStatus.removing;
}

class DemoCubit extends Cubit<DemoState> {
  DemoCubit({DemoBaseRepository? repository})
      : _repository = repository ?? DemoRepository(),
        super(const DemoState());

  final DemoBaseRepository _repository;

  Future<void> fill(String adminUid) async {
    if (state.isBusy) return;
    emit(const DemoState(status: DemoStatus.filling));

    final Either<AppFailure, DemoCounts> result =
        await _repository.fill(adminUid: adminUid);
    if (isClosed) return;

    emit(
      result.fold(
        (AppFailure failure) =>
            DemoState(status: DemoStatus.failure, failure: failure),
        (DemoCounts counts) =>
            DemoState(status: DemoStatus.filled, counts: counts),
      ),
    );
  }

  Future<void> remove() async {
    if (state.isBusy) return;
    emit(const DemoState(status: DemoStatus.removing));

    final Either<AppFailure, DemoCounts> result = await _repository.remove();
    if (isClosed) return;

    emit(
      result.fold(
        (AppFailure failure) =>
            DemoState(status: DemoStatus.failure, failure: failure),
        (DemoCounts counts) =>
            DemoState(status: DemoStatus.removed, counts: counts),
      ),
    );
  }
}
