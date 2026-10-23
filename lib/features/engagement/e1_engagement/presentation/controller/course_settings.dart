/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: course_settings.dart
/// Purpose: Declares `CourseSettings` — the admin's per-course switches read
///          live from `course_settings`: must a member finish each video
///          before the next one opens (sequential), and the line shown under
///          the course's title (subtitle), course by course.
/// Author: ASEC team
/// Created: 15/10/2026
///
/// A course the admin never set follows the app-wide switch in the control
/// centre (AppFeature.videoSequential), so nothing changes until the admin
/// flips a course.

import 'dart:async';

import 'package:get/get.dart';

import 'package:asec/core/settings/app_features.dart';
import 'package:asec/features/engagement/e1_engagement/data/repository/engagement_repository.dart';

class CourseSettings extends GetxController {
  static CourseSettings get to => Get.isRegistered<CourseSettings>()
      ? Get.find<CourseSettings>()
      : Get.put(CourseSettings(), permanent: true);

  final EngagementRepository _repository = EngagementRepository();

  /// course name → sequential, only for the courses the admin set.
  final RxMap<String, bool> sequential = <String, bool>{}.obs;

  /// course name → the line under its title, only for courses that have one.
  final RxMap<String, String> subtitles = <String, String>{}.obs;

  StreamSubscription<Map<String, bool>>? _sub;
  StreamSubscription<Map<String, String>>? _subtitleSub;

  @override
  void onInit() {
    super.onInit();
    listen();
  }

  /// (Re)subscribes — safe to call again after sign-in.
  void listen() {
    _sub?.cancel();
    _subtitleSub?.cancel();
    try {
      _sub = _repository.watchCourseSequential().listen(
            sequential.assignAll,
            onError: (Object _) {},
          );
      _subtitleSub = _repository.watchCourseSubtitles().listen(
            subtitles.assignAll,
            onError: (Object _) {},
          );
    } catch (_) {
      // Firebase not configured — every course follows the global switch.
    }
  }

  /// Reactive inside `Obx`.
  bool isSequential(String course) =>
      sequential[course.trim()] ?? AppFeatures.to.isOn(AppFeature.videoSequential);

  /// Reactive inside `Obx`. '' = no subtitle.
  String subtitle(String course) => subtitles[course.trim()] ?? '';

  Future<void> setSubtitle(String course, String value) async {
    final String key = course.trim();
    if (value.trim().isEmpty) {
      subtitles.remove(key);
    } else {
      subtitles[key] = value.trim(); // optimistic
    }
    await _repository.setCourseSubtitle(course, value);
  }

  Future<void> setSequential(String course, bool value) async {
    sequential[course.trim()] = value; // optimistic
    await _repository.setCourseSequential(course, value);
  }

  @override
  void onClose() {
    _sub?.cancel();
    _subtitleSub?.cancel();
    super.onClose();
  }
}
