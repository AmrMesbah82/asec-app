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

  /// The category (Drive sub-folder) the video belongs to, e.g.
  /// "GENERAL NOTES". Empty = no category (shown under "General").
  final String category;

  /// Position of [category] among the categories (folder order), so the
  /// category list keeps the Drive folder's order.
  final int categoryOrder;

  /// The sub-folder inside [category] the video sits in, e.g.
  /// "Introduction-01" inside "AutoCAD". Empty = straight in the category
  /// folder. A category with more than one sub-folder shows them as a second
  /// level of folders in the app.
  final String subcategory;

  /// Position of [subcategory] inside its category (folder order).
  final int subcategoryOrder;

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
    this.category = '',
    this.categoryOrder = 0,
    this.subcategory = '',
    this.subcategoryOrder = 0,
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
    String? category,
    int? categoryOrder,
    String? subcategory,
    int? subcategoryOrder,
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
      category: category ?? this.category,
      categoryOrder: categoryOrder ?? this.categoryOrder,
      subcategory: subcategory ?? this.subcategory,
      subcategoryOrder: subcategoryOrder ?? this.subcategoryOrder,
      published: published ?? this.published,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
    );
  }
}
