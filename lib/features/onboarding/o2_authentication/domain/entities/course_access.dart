/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: course_access.dart
/// Purpose: Declares `CourseAccess` — the admin's settings for ONE course of
///          ONE member: from when, until when, and on which platforms the
///          course opens. Set on Members → Edit access, next to each course
///          ticked.
/// Author: ASEC team
/// Created: 20/10/2026
///
/// A course with no settings opens like before: whenever the member's own
/// access is open, on the member's platforms.

import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CourseAccess {
  const CourseAccess({this.from, this.until, this.platforms = defaultPlatforms});

  /// THE DEFAULT: phones and tablets only — not Mac, not Windows. Used for
  /// a member (or a course) the admin has not set platforms for.
  static const List<String> defaultPlatforms = <String>['android', 'ios'];

  /// Null = from the start / with no end.
  final DateTime? from;
  final DateTime? until;

  /// Platform keys the course opens on. Empty = [defaultPlatforms].
  final List<String> platforms;

  List<String> get effectivePlatforms => platforms.isEmpty ? defaultPlatforms : platforms;

  bool openAt(DateTime t) =>
      (from == null || !t.isBefore(from!)) && (until == null || t.isBefore(until!));

  bool allows(String platform) => effectivePlatforms.contains(platform);

  /// Open right now, on this copy of the app.
  bool get openHere => openAt(DateTime.now()) && allows(currentPlatform);

  CourseAccess copyWith({
    DateTime? from,
    DateTime? until,
    List<String>? platforms,
    bool clearFrom = false,
    bool clearUntil = false,
  }) =>
      CourseAccess(
        from: clearFrom ? null : (from ?? this.from),
        until: clearUntil ? null : (until ?? this.until),
        platforms: platforms ?? this.platforms,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'from': from == null ? null : Timestamp.fromDate(from!),
        'until': until == null ? null : Timestamp.fromDate(until!),
        'platforms': platforms,
      };

  static CourseAccess fromMap(Object? raw) {
    if (raw is! Map) return const CourseAccess();
    DateTime? date(Object? v) => v is Timestamp ? v.toDate() : (v is DateTime ? v : null);
    final Object? p = raw['platforms'];
    return CourseAccess(
      from: date(raw['from']),
      until: date(raw['until']),
      platforms: p is List ? p.whereType<String>().toList() : defaultPlatforms,
    );
  }

  /// The platform this copy of the app is running on.
  static String get currentPlatform {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }
}
