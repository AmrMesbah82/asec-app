/// Module: core/helper/upload
///
///*************************** FILE INFO ****************************///
/// File Name: picked_upload.dart
/// Purpose: `startUpload` — hands a file_picker result to Cloud Storage on
///          whichever platform this build is.
/// Author: ASEC team
/// Created: 19/9/2026
///
/// WHY A CONDITIONAL EXPORT
/// ------------------------
/// A phone, a Mac and a Windows box give file_picker a PATH, and
/// `ref.putFile(File(path))` streams it from disk — which is the only sane
/// way to move a 300MB video. The web gives BYTES and has no `dart:io` at
/// all, so importing `dart:io` anywhere on the way to this call breaks the
/// web build. The two implementations are therefore kept apart and picked at
/// compile time.

export 'picked_upload_io.dart' if (dart.library.js_interop) 'picked_upload_web.dart';
