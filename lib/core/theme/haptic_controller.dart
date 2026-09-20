/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: haptic_controller.dart
/// Purpose: Declares `HapticController`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';


final storage = GetStorage();

class HapticController extends GetxController {
  // Define a variable to hold the haptic feedback status
  RxBool isHapticEnabled =
      storage.read('haptic') == true ? true.obs : false.obs;

  // Method to toggle the haptic feedback status
  void toggleHapticFeedback(bool value) {
    isHapticEnabled.value = value;
    storage.write('haptic', value);
    update();
  }

  Future<void> triggerHapticFeedback({
    VibrateType vibration = VibrateType.lightImpact,
    Function() hapticFeedback = HapticFeedback.mediumImpact,
  }) async {
    if (isHapticEnabled.value) {
      hapticFeedback();
    }
  }

  // ── Semantic convenience triggers (moved from the retired AppHaptics) ──
  //   low()    → widgets & cards, skip/cancel in dialogs, top page navigation
  //   medium() → yellow buttons: assign, add, create, discard, edit
  //   high()   → destructive: remove, delete, cancel, reject, log out, confirms
  // Routed through the singleton controller so the global toggle still applies.
  static HapticController get _instance => Get.isRegistered<HapticController>()
      ? Get.find<HapticController>()
      : Get.put(HapticController());

  static void low() => _instance.triggerHapticFeedback(
        vibration: VibrateType.lightImpact,
        hapticFeedback: HapticFeedback.lightImpact,
      );

  static void medium() => _instance.triggerHapticFeedback(
        vibration: VibrateType.mediumImpact,
        hapticFeedback: HapticFeedback.mediumImpact,
      );

  static void high() => _instance.triggerHapticFeedback(
        vibration: VibrateType.heavyImpact,
        hapticFeedback: HapticFeedback.heavyImpact,
      );
}

/// Haptic strength used by [HapticController.triggerHapticFeedback].
/// Relocated from lib/core/enums/enum.dart, which was retired.
enum VibrateType {
  lightImpact,
  mediumImpact,
  heavyImpact,
}
