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
  static const String category = 'category';
  static const String categoryOrder = 'category_order';
  static const String subcategory = 'subcategory';
  static const String subcategoryOrder = 'subcategory_order';

  static VideoItem fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.safeData;
    return VideoItem(
      id: doc.id,
      title: data.str(title),
      description: data.str(description),
      url: _repairUrl(data.str(url)),
      storagePath: data.str(storagePath),
      sizeBytes: data.integer(sizeBytes),
      category: data.str(category).trim(),
      categoryOrder: data.integer(categoryOrder),
      subcategory: data.str(subcategory).trim(),
      subcategoryOrder: data.integer(subcategoryOrder),
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
        category: video.category.trim(),
        categoryOrder: video.categoryOrder,
        subcategory: video.subcategory.trim(),
        subcategoryOrder: video.subcategoryOrder,
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
        // A pasted link can change on an edit without any upload.
        url: video.url,
        storagePath: video.storagePath,
        category: video.category.trim(),
        FirebaseCollections.publishedField: video.published,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      };

  // ── Dead sample links ─────────────────────────────────────────────────────
  //
  // Google made its `gtv-videos-bucket` sample videos private (every file now
  // answers 403 / OSStatus -12660), and older demo data in Firestore still
  // points at them. Each dead file is swapped for a public clip on read, so
  // those videos play again without re-filling the demo data.
  static const String _deadHost =
      'storage.googleapis.com/gtv-videos-bucket/sample/';
  static const String _clips = 'https://test-videos.co.uk/vids/';
  static const Map<String, String> _replacements = <String, String>{
    'ForBiggerBlazes': 'bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_2MB.mp4',
    'ForBiggerJoyrides': 'jellyfish/mp4/h264/720/Jellyfish_720_10s_2MB.mp4',
    'ForBiggerMeltdowns': 'sintel/mp4/h264/720/Sintel_720_10s_2MB.mp4',
    'ElephantsDream': 'bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_10MB.mp4',
    'ForBiggerEscapes': 'jellyfish/mp4/h264/720/Jellyfish_720_10s_1MB.mp4',
    'ForBiggerFun': 'sintel/mp4/h264/720/Sintel_720_10s_1MB.mp4',
    'SubaruOutbackOnStreetAndDirt': 'bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_5MB.mp4',
    'VolkswagenGTIReview': 'jellyfish/mp4/h264/720/Jellyfish_720_10s_5MB.mp4',
    'Sintel': 'sintel/mp4/h264/720/Sintel_720_10s_5MB.mp4',
    'TearsOfSteel': 'jellyfish/mp4/h264/720/Jellyfish_720_10s_10MB.mp4',
    'BigBuckBunny': 'bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
  };

  static String _repairUrl(String raw) {
    final int at = raw.indexOf(_deadHost);
    if (at < 0) return raw;
    final String name =
        raw.substring(at + _deadHost.length).replaceAll('.mp4', '');
    return '$_clips${_replacements[name] ?? _replacements['BigBuckBunny']!}';
  }
}
