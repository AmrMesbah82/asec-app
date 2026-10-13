/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: file_saver.dart
/// Purpose: `saveBytesToDevice` — saves a file the user exported (PDF /
///          Excel) with the system "Save as" dialog: the user types the
///          file name and picks the folder, starting in Downloads.
/// Author: ASEC team
/// Created: 4/10/2026
///
///   Android  — the system "Save to" screen (name field + folders), opens in
///              Download.
///   iOS      — the Files "Save" sheet (pick a folder). iOS has no name field
///              there, so the page asks for the name first.
///   macOS / Windows / Linux — the normal Save dialog, opens in Downloads.
///   Web      — a normal browser download.
///
/// Returns where the file went (a path or the file name), or null if the
/// user cancelled.
export 'file_saver_io.dart' if (dart.library.js_interop) 'file_saver_web.dart';
