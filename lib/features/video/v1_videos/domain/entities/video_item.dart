/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_item.dart
/// Purpose: Declares `VideoItem` — one lesson video.
/// Author: ASEC team
/// Created: 19/9/2026

class VideoItem {
  final String id;
  final String title;
  final String description;

  /// The Cloud Storage download URL the player opens.
  final String url;

  /// The object's path inside the bucket, kept so deleting the document can
  /// delete the file too. Without it the bucket fills with orphans nobody can
  /// name.
  final String storagePath;

  final int sizeBytes;
  final bool published;
  final String createdBy;
  final DateTime? createdAt;

  const VideoItem({
    required this.id,
    required this.title,
    this.description = '',
    this.url = '',
    this.storagePath = '',
    this.sizeBytes = 0,
    this.published = true,
    this.createdBy = '',
    this.createdAt,
  });

  static const VideoItem empty = VideoItem(id: '', title: '');

  bool get hasFile => url.isNotEmpty;

  /// Megabytes, one decimal — what the card shows.
  String get sizeMb => (sizeBytes / (1024 * 1024)).toStringAsFixed(1);

  VideoItem copyWith({
    String? id,
    String? title,
    String? description,
    String? url,
    String? storagePath,
    int? sizeBytes,
    bool? published,
    String? createdBy,
  }) {
    return VideoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      storagePath: storagePath ?? this.storagePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      published: published ?? this.published,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
    );
  }
}
