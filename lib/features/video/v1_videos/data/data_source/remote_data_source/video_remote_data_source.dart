/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_remote_data_source.dart
/// Purpose: Declares `VideoRemoteDataSource` — `videos` in Firestore and the
///          objects behind it in Cloud Storage.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:asec/core/constants/firebase_collections.dart';
// Prefixed: this class has a `startUpload` of its own, and an unprefixed
// import would be shadowed by it at every call site inside the class.
import 'package:asec/core/helper/upload/picked_upload.dart' as picked;
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/video/v1_videos/data/models/video_model.dart';
import 'package:asec/features/video/v1_videos/domain/base_repository/video_base_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';

class VideoRemoteDataSource {
  CollectionReference<Map<String, dynamic>> get _videos =>
      AppFirebase.db.collection(FirebaseCollections.videos);

  Stream<List<VideoItem>> watchAll() => _videos
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snap) =>
          _newestFirst(snap.docs.map(VideoModel.fromDoc)));

  Stream<List<VideoItem>> watchPublished() => _videos
      .where(FirebaseCollections.publishedField, isEqualTo: true)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snap) =>
          _newestFirst(snap.docs.map(VideoModel.fromDoc)));

  /// `videos/{uid}/{timestamp}_{name}` — the uid in the path is what the
  /// Storage rules match on, and the timestamp keeps two files of the same
  /// name apart.
  VideoUpload startUpload({
    required PlatformFile file,
    required String uid,
  }) {
    final String safeName = file.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final String path =
        '${FirebaseCollections.storageVideos}/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    final Reference ref = AppFirebase.storage.ref(path);
    final UploadTask task = picked.startUpload(
      ref,
      file,
      SettableMetadata(contentType: _contentTypeFor(file.name)),
    );
    return VideoUpload(task: task, storagePath: path);
  }

  static String _contentTypeFor(String name) {
    final String ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4':
      case 'm4v':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      default:
        // The picker was opened with FileType.video, so an unfamiliar
        // extension is still a video — and the Storage rules only accept
        // `video/*`, so octet-stream would have the upload refused.
        return 'video/mp4';
    }
  }

  Future<String> create(VideoItem video) async {
    final DocumentReference<Map<String, dynamic>> ref =
        await _videos.add(VideoModel.toMap(video, isCreate: true));
    return ref.id;
  }

  Future<void> updateDetails(VideoItem video) =>
      _videos.doc(video.id).update(VideoModel.toDetailsMap(video));

  /// Points the document at the new object first, THEN removes the old one:
  /// a failure in between leaves a stray file, never a video that plays
  /// nothing.
  Future<void> replaceFile(
    VideoItem video, {
    required String previousStoragePath,
  }) async {
    await _videos.doc(video.id).update(VideoModel.toMap(video));
    await _deleteObject(previousStoragePath);
  }

  Future<void> delete(VideoItem video) async {
    await _videos.doc(video.id).delete();
    await _deleteObject(video.storagePath);
  }

  /// A file that is already gone is not an error worth failing a delete over.
  Future<void> _deleteObject(String path) async {
    if (path.isEmpty) return;
    try {
      await AppFirebase.storage.ref(path).delete();
    } on FirebaseException catch (_) {
      // object-not-found, or no permission to a file from another project.
    }
  }

  List<VideoItem> _newestFirst(Iterable<VideoItem> videos) {
    final List<VideoItem> list = videos.toList()
      ..sort((VideoItem a, VideoItem b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }
}
