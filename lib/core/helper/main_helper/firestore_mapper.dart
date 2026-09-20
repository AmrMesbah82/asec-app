/// Module: core/helper
///
///*************************** FILE INFO ****************************///
/// File Name: firestore_mapper.dart
/// Purpose: Declares `FirestoreMap` — safe reads off a Firestore document map.
/// Author: Manger Plus team
/// Updated: 3/9/2026 - Initial version.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Typed accessors for the untyped `Map<String, dynamic>` a Firestore document
/// hands back.
///
/// Firestore has no schema. A field that has always been a number arrives as a
/// String the day someone edits it in the console, and `map['x'] as double`
/// then throws inside a build. Every model in this app reads through these
/// helpers so a bad field degrades to a default instead of taking the screen
/// down.
extension FirestoreMap on Map<String, dynamic> {
  String str(String key, [String fallback = '']) {
    final value = this[key];
    if (value == null) return fallback;
    return value.toString();
  }

  bool boolean(String key, [bool fallback = false]) {
    final value = this[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  int integer(String key, [int fallback = 0]) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  double decimal(String key, [double fallback = 0]) {
    final value = this[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Accepts a [Timestamp], an ISO-8601 string, or epoch milliseconds — all
  /// three turn up in practice, the last two from console edits and imports.
  DateTime? date(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  DateTime dateOr(String key, DateTime fallback) => date(key) ?? fallback;

  List<String> stringList(String key) {
    final value = this[key];
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  Map<String, dynamic> nested(String key) {
    final value = this[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}

/// The same accessors straight off a document snapshot, plus its id.
extension FirestoreDoc on DocumentSnapshot<Map<String, dynamic>> {
  /// Empty map for a document that does not exist, so callers never null-check
  /// `data()` before mapping.
  Map<String, dynamic> get safeData => data() ?? const {};
}
