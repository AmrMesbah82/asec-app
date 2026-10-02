/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_file_web.dart
/// Purpose: The web build of video_file.dart — no offline lessons in a
///          browser.
/// Author: ASEC team
/// Created: 1/10/2026

import 'package:video_player/video_player.dart';

const bool videoDownloadsSupported = false;

Future<String> videoDownloadsDir(String uid) async =>
    throw UnsupportedError('Downloads are not available on the web');

bool videoFileExists(String path) => false;

Future<void> deleteVideoFile(String path) async {}

Future<void> deleteVideoDir(String dir) async {}

Future<void> downloadVideoFile({
  required String url,
  required String path,
  required int expectedBytes,
  required void Function(int received, int total) onProgress,
  required bool Function() cancelled,
}) async =>
    throw UnsupportedError('Downloads are not available on the web');

VideoPlayerController localVideoController(String path) =>
    throw UnsupportedError('Downloads are not available on the web');
