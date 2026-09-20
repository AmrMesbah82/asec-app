/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_repository.dart
/// Purpose: Declares `CvRepository`.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/core/network/guard.dart';
import 'package:asec/features/cv/c1_cv/data/data_source/remote_data_source/cv_remote_data_source.dart';
import 'package:asec/features/cv/c1_cv/domain/base_repository/cv_base_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/cv/c1_cv/domain/enums/cv_status.dart';

class CvRepository implements CvBaseRepository {
  CvRepository({CvRemoteDataSource? remote})
      : _remote = remote ?? CvRemoteDataSource();

  final CvRemoteDataSource _remote;

  @override
  Stream<List<CvProfile>> watchAll() => _remote.watchAll();

  @override
  Stream<CvProfile?> watchCv(String uid) => _remote.watchCv(uid);

  @override
  Future<CvProfile?> fetch(String uid) => _remote.fetch(uid);

  @override
  Future<Either<AppFailure, Unit>> save(CvProfile cv, {required bool isNew}) =>
      guardUnit(() => _remote.save(cv, isNew: isNew));

  @override
  Future<Either<AppFailure, Unit>> setStatus(String uid, CvStatus status) =>
      guardUnit(() => _remote.setStatus(uid, status));

  @override
  Future<Either<AppFailure, Unit>> delete(CvProfile cv) =>
      guardUnit(() => _remote.delete(cv));

  @override
  CvUpload startPhotoUpload({
    required PlatformFile file,
    required String uid,
  }) =>
      _remote.startPhotoUpload(file: file, uid: uid);

  @override
  CvUpload startFileUpload({
    required PlatformFile file,
    required String uid,
  }) =>
      _remote.startFileUpload(file: file, uid: uid);

  @override
  Future<void> deleteObject(String path) => _remote.deleteObject(path);
}
