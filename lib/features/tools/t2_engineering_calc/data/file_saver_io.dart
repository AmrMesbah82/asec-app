/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: file_saver_io.dart
/// Purpose: `saveBytesToDevice` for Android, iOS, macOS, Windows and Linux
///          (see file_saver.dart). Uses file_picker's save dialog.
/// Author: ASEC team
/// Created: 4/10/2026

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Android's public "Download" folder, as the Storage Access Framework names
/// it — where the "Save to" screen opens.
const String _androidDownloads =
    'content://com.android.externalstorage.documents/document/primary%3ADownload';

/// [build] makes the file. On desktop it runs AFTER the Save dialog closes,
/// so the dialog appears at once; phones need the bytes before the dialog.
Future<String?> saveBytesToDevice({
  required Future<Uint8List> Function() build,
  required String fileName,
  required String extension,
  required String mimeType,
  required String dialogTitle,
}) async {
  // Phones: the plugin writes the bytes itself into the place the user picks.
  if (Platform.isAndroid || Platform.isIOS) {
    final Uint8List bytes = await build();
    final String? saved = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: bytes,
      type: Platform.isAndroid ? FileType.custom : FileType.any,
      allowedExtensions: Platform.isAndroid ? <String>[extension] : null,
      initialDirectory: Platform.isAndroid ? _androidDownloads : null,
    );
    return saved == null ? null : fileName;
  }

  // Desktop: the dialog only returns a path — the app writes the file.
  String? downloads;
  try {
    downloads = (await getDownloadsDirectory())?.path;
  } catch (_) {
    downloads = null;
  }
  String? path = await FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    initialDirectory: downloads,
    type: FileType.custom,
    allowedExtensions: <String>[extension],
    lockParentWindow: true,
  );
  if (path == null || path.isEmpty) return null;
  if (!path.toLowerCase().endsWith('.$extension')) path = '$path.$extension';
  final Uint8List bytes = await build();
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}
