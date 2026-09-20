/// Module: core/helper/main_helper
///
///*************************** FILE INFO ****************************///
/// File Name: localized_number.dart
/// Purpose: Render a number using the active locale's numerals.
/// Author: Manger Plus team
/// Created at: 13/8/2026
///
/// Added because every count chip in the app rendered `count.toString()`, which
/// is always ASCII — so an Arabic screen showed "14" and "٠" side by side with
/// Arabic-Indic dates like "١٣ أغسطس ٢٠٢٦".
///
/// `LocalizedDigits` in `features/settings/se1_profile/data/utils` already does
/// this for strings, but `core/` must not import from `features/` — hence this
/// core-level twin. Both wrap `NumberFormat`, whose digit symbols are compiled
/// into intl, so unlike `DateFormat` this needs no async initialization.
///
/// ⚠️ Display only. Never use this on a value that will be stored, parsed or
/// compared — Arabic-Indic digits will not round-trip through `int.parse` or a
/// Firestore query.

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

abstract final class LocalizedNumber {
  const LocalizedNumber._();

  /// Function Name: [of]
  ///
  /// Purpose: [value] in the numerals of the locale currently in the tree —
  ///          `14` in English, `١٤` in Arabic.
  static String of(BuildContext context, num value) =>
      forLocale(value, Localizations.localeOf(context).languageCode);

  /// Function Name: [forLocale]
  ///
  /// Purpose: As [of], for callers that already know the locale name and have
  ///          no BuildContext to hand.
  ///
  /// FIXED 22/8/2026 — Arabic fields were still counting in Latin digits
  /// ("158 / 500" under Arabic body text). `NumberFormat.decimalPattern('ar')`
  /// is supposed to carry ZERO_DIGIT `٠`, but which numbering system CLDR
  /// hands a bare `ar` has moved between intl releases, and an unrecognised
  /// locale silently falls back to `en` rather than throwing — so the call was
  /// only ever *probably* Arabic-Indic, with no way to tell from the call site.
  ///
  /// The digits are now mapped here for any `ar…` locale tag, which cannot
  /// depend on the intl version. `NumberFormat` still does the formatting, so
  /// separators and negative signs keep coming from the locale data.
  static String forLocale(num value, String localeName) => digitsForLocale(
        (NumberFormat.decimalPattern(localeName)..turnOffGrouping())
            .format(value),
        localeName,
      );

  /// Function Name: [digits]
  ///
  /// Purpose: rewrite the ASCII digits ALREADY INSIDE [text] into the numerals
  ///          of the locale in the tree, leaving everything else untouched —
  ///          "24/8/2026" becomes "٢٤/٨/٢٠٢٦" in Arabic.
  ///
  /// ADDED 2/9/2026. [of] only covers a bare `num`, so anything pre-formatted
  /// by `DateFormat` (every date and time label in the chat lists) still came
  /// out in Latin digits next to Arabic-Indic counts. `DateFormat`'s own
  /// locale digits cannot be relied on here for the same reason spelled out
  /// below for `NumberFormat`: which numbering system CLDR hands a bare `ar`
  /// has moved between intl releases, and an unknown locale falls back to `en`
  /// silently.
  ///
  /// ⚠️ Display only, exactly like the rest of this class.
  static String digits(BuildContext context, String text) =>
      digitsForLocale(text, Localizations.localeOf(context).languageCode);

  /// Function Name: [digitsForLocale]
  ///
  /// Purpose: as [digits], for callers that already know the locale name.
  static String digitsForLocale(String text, String localeName) {
    if (!localeName.toLowerCase().startsWith('ar')) return text;

    const int arabicIndicZero = 0x0660; // ٠
    const int asciiZero = 0x30;

    return String.fromCharCodes(
      text.codeUnits.map((int unit) =>
          (unit >= asciiZero && unit <= asciiZero + 9)
              ? arabicIndicZero + (unit - asciiZero)
              : unit),
    );
  }
}
