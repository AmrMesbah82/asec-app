/// Module: core/helper/upload
///
///*************************** FILE INFO ****************************///
/// File Name: picked_upload_web.dart
/// Purpose: `startUpload` for the web build — the picker hands over bytes.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// The browser has no file path, so the bytes the picker read are what goes
/// up. Pick the file with `withData: true` on this platform.
UploadTask startUpload(
  Reference ref,
  PlatformFile file,
  SettableMetadata metadata,
) =>
    ref.putData(file.bytes!, metadata);
