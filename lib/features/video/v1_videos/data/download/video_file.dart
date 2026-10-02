/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_file.dart
/// Purpose: The disk side of offline lessons — where a downloaded video
///          lives, writing it there, and a player for it.
/// Author: ASEC team
/// Created: 1/10/2026
///
/// The web has no `dart:io`, so the two implementations are picked at compile
/// time (same reason as core/helper/upload/picked_upload.dart). On the web
/// downloads are simply not offered.

export 'video_file_io.dart' if (dart.library.js_interop) 'video_file_web.dart';
