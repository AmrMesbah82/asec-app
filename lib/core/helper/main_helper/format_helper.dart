/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: format_helper.dart
/// Description: Declares `FormatHelper`.
/// Author: Amr Mesbah
/// Created at: 06/10/2026
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.
/// Updated: 16/10/2026 - Brought into ASEC: EVERY Text in the app passes its
///          string through [FormatHelper.capitalize]. Emails and links are
///          left exactly as written.

// Date: 23/10/2024
// Last update: 31/03/2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

List<String> abbreviation = [
  "it",
  "hr",
  'utils ux',
  'log',
  'qa',
  'pr',
  'dev',
  'ceo',
  "grc",
  "mena",
  "ksa",
  "uae",
  "coo",
  "cfo",
  "cdo",
  "cso",
  "cbo",
  "cmo",
  "cto",
  "cno",
  "cco",
  "chro",
  "cxo"
];

abstract class FormatHelper {
  /// Picks the locale-appropriate name, falling back to the English one when
  /// the locale is English or no Arabic value exists.
  /// (Moved here from StringFormatter in the deleted additional_info_content.dart.)
  static String localizedString({
    required String englishName,
    required String? arabicName,
  }) {
    if (Get.locale.toString().contains('en') || arabicName == null) {
      return capitalize(englishName);
    }
    return arabicName;
  }

  static String capitalize(String input) {
    input.toLowerCase();
    input = applyAbbreviation(input);

    if (input.isEmpty) {
      return "";
    }

    List<String> words = input.split(" ");
    words = words.map((word) {
      if (word.isNotEmpty) {
        // An email or a link stays exactly as it is.
        if (word.contains('@') || word.contains('://')) return word;
        return word[0].toUpperCase() + word.substring(1);
      } else {
        return "";
      }
    }).toList();
    return words.join(" ");
  }

  static String applyAbbreviation(String input) {
    for (String abbreviation in abbreviation) {
      RegExp regex =
      RegExp(r'\b' + abbreviation + r'\b', caseSensitive: false);
      if (regex.hasMatch(input)) {
        input = input.replaceAllMapped(
            regex, (match) => abbreviation.toUpperCase());
      }
    }
    return input;
  }

  /// Turns an email (or a raw user id) into something readable:
  ///
  ///   amr.mesbah@knowticed.com  -> Amr Mesbah
  ///   hr_team@knowticed.com     -> HR Team
  ///   sara-ali99@x.com          -> Sara Ali
  ///
  /// Used as the fallback when an employee lookup fails and all we have is the
  /// address the record was created with. The domain is dropped, separators
  /// (. _ - +) become spaces, trailing digits are stripped, and the result runs
  /// through [capitalize] so known abbreviations (IT, HR, GRC, CEO…) stay
  /// upper-case. Returns '' for null/empty input so callers can fall back.
  static String formatEmailToName(String? email) {
    final String raw = (email ?? '').trim();
    if (raw.isEmpty) return '';

    final String local = raw.contains('@') ? raw.split('@').first : raw;

    final String spaced = local
        .replaceAll(RegExp(r'[._\-+]+'), ' ')
        .replaceAll(RegExp(r'\d+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Nothing left to show (e.g. "123@x.com") — fall back to the local part.
    if (spaced.isEmpty) return capitalize(local);

    return capitalize(spaced);
  }

  /// ✅ Formats a date as "31 Mar 2026"
  /// Supports: DateTime, Firestore Timestamp, ISO String, milliseconds
  static String formatDate(dynamic rawDate, String locale) {
    if (rawDate == null) return '-';

    DateTime? date;

    if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      if (rawDate.isEmpty || rawDate == 'null') return '-';
      date = DateTime.tryParse(rawDate);
    } else if (rawDate is int) {
      date = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else if (rawDate is Map) {
      // Handle Firestore Timestamp as map: {_seconds: ..., _nanoseconds: ...}
      final seconds = rawDate['_seconds'] ?? rawDate['seconds'];
      if (seconds != null && seconds is int) {
        date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }

    if (date == null) return '-';

    // ✅ Output: "31 Mar 2026" (English) or "31 مار 2026" (Arabic)
    return DateFormat('dd MMM yyyy', locale).format(date);
  }
}
