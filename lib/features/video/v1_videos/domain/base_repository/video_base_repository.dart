/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_base_repository.dart
/// Purpose: Declares `VideoBaseRepository`.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';

/// A running upload: the task to follow for progress, and the path the object
/// will live at.
class VideoUpload {
  const VideoUpload({required this.task, required this.storagePath});

  final UploadTask task;
  final String storagePath;
}

abstract class VideoBaseRepository {
  /// Everything, unpublished included — the admin's list.
  Stream<List<VideoItem>> watchAll();

  /// What a member is allowed to read.
  Stream<List<VideoItem>> watchPublished();

  /// Starts the upload. Progress and cancellation belong to the caller: only
  /// the UI knows whether anybody is still watching.
  VideoUpload startUpload({required PlatformFile file, required String uid});

  Future<Either<AppFailure, String>> create(VideoItem video);

  /// Title, description and published — the fields that do not touch the file.
  Future<Either<AppFailure, Unit>> updateDetails(VideoItem video);

  /// Replaces the file on an existing video and deletes the old object.
  Future<Either<AppFailure, Unit>> replaceFile(
    VideoItem video, {
    required String previousStoragePath,
  });

  /// Deletes the document AND the object behind it.
  Future<Either<AppFailure, Unit>> delete(VideoItem video);
}
