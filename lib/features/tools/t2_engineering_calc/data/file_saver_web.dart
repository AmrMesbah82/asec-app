/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: file_saver_web.dart
/// Purpose: `saveBytesToDevice` for the web (see file_saver.dart): a normal
///          browser download. The browser decides where it goes (Downloads,
///          or its "Save as" window if the user turned that on).
/// Author: ASEC team
/// Created: 4/10/2026

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String?> saveBytesToDevice({
  required Future<Uint8List> Function() build,
  required String fileName,
  required String extension,
  required String mimeType,
  required String dialogTitle,
}) async {
  final Uint8List bytes = await build();
  final web.Blob blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement a = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.appendChild(a);
  a.click();
  a.remove();
  Timer(const Duration(seconds: 2), () => web.URL.revokeObjectURL(url));
  return fileName;
}
