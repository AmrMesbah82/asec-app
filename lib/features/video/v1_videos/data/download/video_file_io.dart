/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_file_io.dart
/// Purpose: The phone / desktop build of video_file.dart.
/// Author: ASEC team
/// Created: 1/10/2026
///
/// WHERE THE FILES GO
/// ------------------
/// The app's private "Application Support" folder (path_provider), inside
/// `asec_videos/<uid>/`. It is NOT the phone's Downloads, Gallery or Files:
/// the student cannot open, share or copy the video outside ASEC, other apps
/// cannot see it, and deleting the app deletes it. Unlike the cache folder,
/// the system does not empty it by itself when space runs low, so a lesson
/// the student downloaded is still there on the bus.
///
/// A download is written to `<id>.mp4.part` and renamed only when complete,
/// so a cut connection never leaves a half video that looks finished.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

const bool videoDownloadsSupported = true;

Future<String> videoDownloadsDir(String uid) async {
  final Directory base = await getApplicationSupportDirectory();
  final Directory dir = Directory('${base.path}/asec_videos/$uid');
  if (!dir.existsSync()) await dir.create(recursive: true);
  return dir.path;
}

bool videoFileExists(String path) => File(path).existsSync();

Future<void> deleteVideoFile(String path) async {
  for (final String p in <String>[path, '$path.part']) {
    final File f = File(p);
    if (f.existsSync()) await f.delete();
  }
}

Future<void> deleteVideoDir(String dir) async {
  final Directory d = Directory(dir);
  if (d.existsSync()) await d.delete(recursive: true);
}

Future<void> downloadVideoFile({
  required String url,
  required String path,
  required int expectedBytes,
  required void Function(int received, int total) onProgress,
  required bool Function() cancelled,
}) async {
  final File part = File('$path.part');
  final http.Client client = http.Client();
  IOSink? sink;
  try {
    final http.StreamedResponse res =
        await client.send(http.Request('GET', Uri.parse(url)));
    final String type = res.headers['content-type'] ?? '';
    // A private Drive file, or Drive's "quota exceeded" page, answers 200
    // with an HTML page instead of the video.
    if (res.statusCode != 200 || type.startsWith('text/html')) {
      throw HttpException('HTTP ${res.statusCode} ($type)');
    }
    final int total = res.contentLength ?? expectedBytes;
    sink = part.openWrite();
    int received = 0;
    int lastReport = 0;
    await for (final List<int> chunk in res.stream) {
      if (cancelled()) throw const _Cancelled();
      sink.add(chunk);
      received += chunk.length;
      // ~ every 256 KB, so the progress ring does not rebuild per packet.
      if (received - lastReport > 256 * 1024) {
        lastReport = received;
        onProgress(received, total);
      }
    }
    await sink.flush();
    await sink.close();
    sink = null;
    if (received == 0) throw const HttpException('Empty file');
    onProgress(received, total > 0 ? total : received);
    await part.rename(path);
  } on _Cancelled {
    await sink?.close();
    sink = null;
    if (part.existsSync()) await part.delete();
    rethrow;
  } catch (_) {
    await sink?.close();
    sink = null;
    if (part.existsSync()) await part.delete();
    rethrow;
  } finally {
    client.close();
  }
}

/// Thrown out of [downloadVideoFile] when the student cancels.
class _Cancelled implements Exception {
  const _Cancelled();
}

VideoPlayerController localVideoController(String path) =>
    VideoPlayerController.file(File(path));
