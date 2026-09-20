/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_repository.dart
/// Purpose: Declares `VideoRepository`.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/core/network/guard.dart';
import 'package:asec/features/video/v1_videos/data/data_source/remote_data_source/video_remote_data_source.dart';
import 'package:asec/features/video/v1_videos/domain/base_repository/video_base_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';

class VideoRepository implements VideoBaseRepository {
  VideoRepository({VideoRemoteDataSource? remote})
      : _remote = remote ?? VideoRemoteDataSource();

  final VideoRemoteDataSource _remote;

  @override
  Stream<List<VideoItem>> watchAll() => _remote.watchAll();

  @override
  Stream<List<VideoItem>> watchPublished() => _remote.watchPublished();

  @override
  VideoUpload startUpload({
    required PlatformFile file,
    required String uid,
  }) =>
      _remote.startUpload(file: file, uid: uid);

  @override
  Future<Either<AppFailure, String>> create(VideoItem video) =>
      guard(() => _remote.create(video));

  @override
  Future<Either<AppFailure, Unit>> updateDetails(VideoItem video) =>
      guardUnit(() => _remote.updateDetails(video));

  @override
  Future<Either<AppFailure, Unit>> replaceFile(
    VideoItem video, {
    required String previousStoragePath,
  }) =>
      guardUnit(() => _remote.replaceFile(
            video,
            previousStoragePath: previousStoragePath,
          ));

  @override
  Future<Either<AppFailure, Unit>> delete(VideoItem video) =>
      guardUnit(() => _remote.delete(video));
}
