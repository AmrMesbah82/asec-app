/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_base_repository.dart
/// Purpose: Declares `CvBaseRepository`.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/cv/c1_cv/domain/enums/cv_status.dart';

/// A running upload — the photo or the CV document: the task to follow, where
/// the object lands, and the name the member picked it with.
class CvUpload {
  const CvUpload({
    required this.task,
    required this.storagePath,
    required this.fileName,
  });

  final UploadTask task;
  final String storagePath;
  final String fileName;
}

abstract class CvBaseRepository {
  /// Every CV — the directory every member browses.
  Stream<List<CvProfile>> watchAll();

  /// One member's CV, live, so the form reflects an admin status change
  /// without a reload.
  Stream<CvProfile?> watchCv(String uid);

  Future<CvProfile?> fetch(String uid);

  /// Creates or replaces the owner's own CV.
  Future<Either<AppFailure, Unit>> save(CvProfile cv, {required bool isNew});

  /// Admin only.
  Future<Either<AppFailure, Unit>> setStatus(String uid, CvStatus status);

  Future<Either<AppFailure, Unit>> delete(CvProfile cv);

  CvUpload startPhotoUpload({
    required PlatformFile file,
    required String uid,
  });

  /// The CV document itself — a real file in this app's Storage, not a link
  /// to somebody else's drive.
  CvUpload startFileUpload({
    required PlatformFile file,
    required String uid,
  });

  /// Drops one Storage object (the old photo or the replaced CV file).
  Future<void> deleteObject(String path);
}
