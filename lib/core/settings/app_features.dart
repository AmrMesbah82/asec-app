/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: app_features.dart
/// Purpose: Declares `AppFeature` (every switch the super admin controls from
///          Settings → Control centre) and `AppFeatures`, the live store that
///          reads them from Firestore `settings/app` and tells every screen
///          whether a part of the app is on.
/// Author: ASEC team
/// Created: 25/9/2026
///
/// ONE DOCUMENT, READ LIVE. Flipping a switch reaches every open app within
/// a second — no restart. A missing field means ON (the default below), so an
/// empty or unreadable document leaves the app exactly as it was.
///
/// Rules: everybody may READ `settings/app` (the sign-in screen needs the
/// registration switch before anybody is signed in); only the super admin
/// may write it.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:asec/core/network/app_firebase.dart';

enum AppFeatureGroup { sections, videos, general, dashboard }

enum AppFeature {
  // ── What members see in the side menu ──
  sectionVideos('section_videos', AppFeatureGroup.sections, Icons.video_library_rounded),
  sectionQuizzes('section_quizzes', AppFeatureGroup.sections, Icons.quiz_outlined),
  sectionCvDirectory('section_cv_directory', AppFeatureGroup.sections, Icons.assignment_outlined),
  sectionMyCv('section_my_cv', AppFeatureGroup.sections, Icons.person_outline_rounded),

  // ── Video lessons ──
  videoSequential('video_sequential', AppFeatureGroup.videos, Icons.lock_rounded),
  videoBlockSkip('video_block_skip', AppFeatureGroup.videos, Icons.fast_forward_rounded),
  videoAutoplay('video_autoplay', AppFeatureGroup.videos, Icons.play_circle_outline_rounded),
  videoUpNext('video_up_next', AppFeatureGroup.videos, Icons.playlist_play_rounded),
  videoOptionsBar('video_options_bar', AppFeatureGroup.videos, Icons.tune_rounded),
  videoSpeed('video_speed', AppFeatureGroup.videos, Icons.speed_rounded),
  videoResume('video_resume', AppFeatureGroup.videos, Icons.history_rounded),
  videoSearch('video_search', AppFeatureGroup.videos, Icons.search_rounded),
  videoCourseProgress('video_course_progress', AppFeatureGroup.videos, Icons.stacked_line_chart_rounded),

  // ── Whole app ──
  animations('animations', AppFeatureGroup.general, Icons.animation_rounded),
  registration('registration', AppFeatureGroup.general, Icons.person_add_alt_1_rounded),
  /// ON = screenshots and screen recordings of the app are blocked
  /// (core/settings/screen_protection.dart → native code on each platform).
  screenProtection('screen_protection', AppFeatureGroup.general, Icons.lock_outline_rounded),

  // ── Admin dashboard ──
  dashboardCharts('dashboard_charts', AppFeatureGroup.dashboard, Icons.bar_chart_rounded),
  dashboardTable('dashboard_table', AppFeatureGroup.dashboard, Icons.table_rows_rounded);

  const AppFeature(this.key, this.group, this.icon);

  final String key;
  final AppFeatureGroup group;
  final IconData icon;
}

class AppFeatures extends GetxController {
  static AppFeatures get to => Get.isRegistered<AppFeatures>()
      ? Get.find<AppFeatures>()
      : Get.put(AppFeatures(), permanent: true);

  static DocumentReference<Map<String, dynamic>> get _doc =>
      AppFirebase.db.collection('settings').doc('app');

  /// key → on/off, straight from the document. Missing = on.
  final RxMap<String, bool> values = <String, bool>{}.obs;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    listen();
  }

  /// (Re)subscribes. Safe to call again after sign-in, when the first
  /// attempt may have been refused.
  void listen() {
    _sub?.cancel();
    try {
      _sub = _doc.snapshots().listen(
        (DocumentSnapshot<Map<String, dynamic>> snap) {
          final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
          values.assignAll(<String, bool>{
            for (final MapEntry<String, dynamic> e in data.entries)
              if (e.value is bool) e.key: e.value as bool,
          });
        },
        onError: (Object _) {},
      );
    } catch (_) {
      // Firebase not configured — every feature stays on.
    }
  }

  bool isOn(AppFeature f) => values[f.key] ?? true;

  /// Reactive read for use inside `Obx`.
  static bool on(AppFeature f) => to.isOn(f);

  Future<void> set(AppFeature f, bool value) async {
    values[f.key] = value; // optimistic
    await _doc.set(<String, dynamic>{f.key: value}, SetOptions(merge: true));
  }

  Future<void> resetAll() async {
    values.clear();
    await _doc.set(<String, dynamic>{
      for (final AppFeature f in AppFeature.values) f.key: true,
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
