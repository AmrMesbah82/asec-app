/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: course_settings.dart
/// Purpose: Declares `CourseSettings` — the admin's per-course switches read
///          live from `course_settings`: must a member finish each video
///          before the next one opens (sequential), course by course.
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

  StreamSubscription<Map<String, bool>>? _sub;

  @override
  void onInit() {
    super.onInit();
    listen();
  }

  /// (Re)subscribes — safe to call again after sign-in.
  void listen() {
    _sub?.cancel();
    try {
      _sub = _repository.watchCourseSequential().listen(
            sequential.assignAll,
            onError: (Object _) {},
          );
    } catch (_) {
      // Firebase not configured — every course follows the global switch.
    }
  }

  /// Reactive inside `Obx`.
  bool isSequential(String course) =>
      sequential[course.trim()] ?? AppFeatures.to.isOn(AppFeature.videoSequential);

  Future<void> setSequential(String course, bool value) async {
    sequential[course.trim()] = value; // optimistic
    await _repository.setCourseSequential(course, value);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
