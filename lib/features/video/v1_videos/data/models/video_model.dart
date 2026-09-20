/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_model.dart
/// Purpose: Declares `VideoModel` — the `videos/{id}` document shape.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/helper/main_helper/firestore_mapper.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';

abstract final class VideoModel {
  const VideoModel._();

  static const String title = 'title';
  static const String description = 'description';
  static const String url = 'url';
  static const String storagePath = 'storage_path';
  static const String sizeBytes = 'size_bytes';
  static const String createdBy = 'created_by';

  static VideoItem fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.safeData;
    return VideoItem(
      id: doc.id,
      title: data.str(title),
      description: data.str(description),
      url: data.str(url),
      storagePath: data.str(storagePath),
      sizeBytes: data.integer(sizeBytes),
      published: data.boolean(FirebaseCollections.publishedField, true),
      createdBy: data.str(createdBy),
      createdAt: data.date(FirebaseCollections.createdAtField),
    );
  }

  static Map<String, dynamic> toMap(VideoItem video, {bool isCreate = false}) =>
      <String, dynamic>{
        title: video.title.trim(),
        description: video.description.trim(),
        url: video.url,
        storagePath: video.storagePath,
        sizeBytes: video.sizeBytes,
        FirebaseCollections.publishedField: video.published,
        createdBy: video.createdBy,
        if (isCreate)
          FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      };

  /// What an edit that does not touch the file may change.
  static Map<String, dynamic> toDetailsMap(VideoItem video) =>
      <String, dynamic>{
        title: video.title.trim(),
        description: video.description.trim(),
        FirebaseCollections.publishedField: video.published,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      };
}
