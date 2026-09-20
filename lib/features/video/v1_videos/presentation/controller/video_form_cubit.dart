/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_form_cubit.dart
/// Purpose: Declares `VideoFormCubit` and `VideoFormState` — picking a file,
///          uploading it, and saving the video.
/// Author: ASEC team
/// Created: 19/9/2026

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/core/network/app_failure.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/base_repository/video_base_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';

enum VideoFormStatus { editing, uploading, saving, saved, failure }

enum VideoFormError { titleEmpty, noFile, tooLarge }

class VideoFormState {
  final VideoItem video;

  /// The file chosen in this sitting. Null on an edit that keeps the old one.
  final PlatformFile? file;

  /// 0..1 while [VideoFormStatus.uploading].
  final double progress;

  final VideoFormStatus status;
  final VideoFormError? formError;
  final AppFailure? failure;

  const VideoFormState({
    required this.video,
    this.file,
    this.progress = 0,
    this.status = VideoFormStatus.editing,
    this.formError,
    this.failure,
  });

  bool get isBusy =>
      status == VideoFormStatus.uploading || status == VideoFormStatus.saving;

  /// The name to show in the file row: the new pick, else the stored object.
  String get fileLabel =>
      file?.name ??
      (video.storagePath.isEmpty
          ? ''
          : video.storagePath.split('/').last);

  VideoFormState copyWith({
    VideoItem? video,
    PlatformFile? file,
    double? progress,
    VideoFormStatus? status,
    VideoFormError? formError,
    AppFailure? failure,
    bool clearErrors = false,
  }) {
    return VideoFormState(
      video: video ?? this.video,
      file: file ?? this.file,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      formError: clearErrors ? null : (formError ?? this.formError),
      failure: clearErrors ? null : (failure ?? this.failure),
    );
  }
}

class VideoFormCubit extends Cubit<VideoFormState> {
  VideoFormCubit({
    VideoItem? existing,
    required this.adminUid,
    VideoBaseRepository? repository,
  })  : _repository = repository ?? VideoRepository(),
        _isNew = existing == null,
        super(VideoFormState(
          video: existing ?? VideoItem(id: '', title: '', createdBy: adminUid),
        ));

  final VideoBaseRepository _repository;
  final String adminUid;

  /// Not final — see the quiz editor: after a create there is an id, and the
  /// next Save has to update.
  bool _isNew;

  bool get isNew => _isNew;

  UploadTask? _task;
  StreamSubscription<TaskSnapshot>? _progressSub;

  static int get _maxBytes => AppConstants.maxUploadMb * 1024 * 1024;

  // ── Fields ───────────────────────────────────────────────────────────────

  void setTitle(String value) => emit(state.copyWith(
        video: state.video.copyWith(title: value),
        clearErrors: true,
      ));

  void setDescription(String value) =>
      emit(state.copyWith(video: state.video.copyWith(description: value)));

  void setPublished(bool value) =>
      emit(state.copyWith(video: state.video.copyWith(published: value)));

  Future<void> pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      // The browser has no path, so it needs the bytes; a device streams from
      // disk instead and must NOT read a 300MB file into memory.
      withData: kIsWeb,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return;

    final PlatformFile file = result.files.first;
    if (file.size > _maxBytes) {
      emit(state.copyWith(formError: VideoFormError.tooLarge));
      return;
    }
    emit(VideoFormState(
      video: state.video,
      file: file,
      status: VideoFormStatus.editing,
    ));
  }

  void clearFile() => emit(VideoFormState(
        video: state.video,
        status: VideoFormStatus.editing,
      ));

  // ── Save ─────────────────────────────────────────────────────────────────

  VideoFormError? _validate() {
    if (state.video.title.trim().isEmpty) return VideoFormError.titleEmpty;
    if (_isNew && state.file == null) return VideoFormError.noFile;
    if ((state.file?.size ?? 0) > _maxBytes) return VideoFormError.tooLarge;
    return null;
  }

  Future<void> save() async {
    if (state.isBusy) return;

    final VideoFormError? error = _validate();
    if (error != null) {
      emit(state.copyWith(
        status: VideoFormStatus.editing,
        formError: error,
      ));
      return;
    }

    // Nothing new to upload: just the details.
    if (state.file == null) {
      emit(state.copyWith(status: VideoFormStatus.saving, clearErrors: true));
      final Either<AppFailure, Unit> result =
          await _repository.updateDetails(state.video);
      if (isClosed) return;
      result.fold(
        (AppFailure f) => emit(state.copyWith(
          status: VideoFormStatus.failure,
          failure: f,
        )),
        (_) => emit(state.copyWith(status: VideoFormStatus.saved)),
      );
      return;
    }

    emit(state.copyWith(
      status: VideoFormStatus.uploading,
      progress: 0,
      clearErrors: true,
    ));

    final String previousPath = state.video.storagePath;
    try {
      final VideoUpload upload = _repository.startUpload(
        file: state.file!,
        uid: adminUid,
      );
      _task = upload.task;
      _progressSub = upload.task.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          if (isClosed || snapshot.totalBytes <= 0) return;
          emit(state.copyWith(
            progress: snapshot.bytesTransferred / snapshot.totalBytes,
          ));
        },
        onError: (Object _) {},
      );

      final TaskSnapshot done = await upload.task;
      final String url = await done.ref.getDownloadURL();
      await _progressSub?.cancel();
      _progressSub = null;
      _task = null;
      if (isClosed) return;

      final VideoItem video = state.video.copyWith(
        url: url,
        storagePath: upload.storagePath,
        sizeBytes: state.file!.size,
        createdBy: adminUid,
      );

      emit(state.copyWith(status: VideoFormStatus.saving, video: video));

      void fail(AppFailure f) => emit(state.copyWith(
            status: VideoFormStatus.failure,
            failure: f,
          ));

      if (_isNew) {
        final Either<AppFailure, String> result =
            await _repository.create(video);
        if (isClosed) return;
        result.fold(fail, (String id) {
          _isNew = false;
          emit(state.copyWith(
            status: VideoFormStatus.saved,
            video: video.copyWith(id: id),
          ));
        });
        return;
      }

      final Either<AppFailure, Unit> result = await _repository.replaceFile(
        video,
        previousStoragePath: previousPath,
      );
      if (isClosed) return;
      result.fold(fail, (_) => emit(state.copyWith(
            status: VideoFormStatus.saved,
            video: video,
          )));
    } catch (error) {
      if (isClosed) return;
      // Cancelling is not a failure: `cancelUpload` has already put the form
      // back to editing, and the task throws `canceled` on the way out.
      if (error is FirebaseException && error.code == 'canceled') return;
      emit(state.copyWith(
        status: VideoFormStatus.failure,
        failure: AppFailure.from(error),
      ));
    }
  }

  /// Stops the transfer. Firebase Storage leaves no partial object behind, so
  /// there is nothing to clean up afterwards.
  Future<void> cancelUpload() async {
    await _task?.cancel();
    await _progressSub?.cancel();
    _task = null;
    _progressSub = null;
    if (isClosed) return;
    emit(state.copyWith(status: VideoFormStatus.editing, progress: 0));
  }

  @override
  Future<void> close() {
    _progressSub?.cancel();
    return super.close();
  }
}
