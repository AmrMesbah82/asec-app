/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: screen_protection.dart
/// Purpose: Declares `ScreenProtection` — turns the native screenshot /
///          screen-recording block on or off, following the super admin's
///          Control centre switch `AppFeature.screenProtection`.
/// Author: ASEC team
/// Created: 26/9/2026
///
/// ONE CHANNEL, FOUR PLATFORMS: `asec/screen_protection`, method
/// `setEnabled(bool)`, answered by
///   * Android — MainActivity.kt        FLAG_SECURE on / off
///   * iOS     — SceneDelegate.swift    secure layer + recording cover
///   * macOS   — MainFlutterWindow.swift sharingType .none / .readOnly
///   * Windows — flutter_window.cpp     WDA_EXCLUDEFROMCAPTURE / WDA_NONE
/// Every platform STARTS protected, so nothing is captured before the
/// setting has loaded; a switch left off in Firestore lifts it a moment
/// later. The web cannot block screenshots, so there it does nothing.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:asec/core/settings/app_features.dart';

abstract final class ScreenProtection {
  static const MethodChannel _channel = MethodChannel('asec/screen_protection');

  static bool? _applied;

  /// Applies the switch now and every time `settings/app` changes.
  static void start() {
    final AppFeatures features = AppFeatures.to;
    apply(features.isOn(AppFeature.screenProtection));
    ever(features.values, (_) => apply(features.isOn(AppFeature.screenProtection)));
  }

  static Future<void> apply(bool on) async {
    if (kIsWeb || _applied == on) return;
    _applied = on;
    try {
      await _channel.invokeMethod<void>('setEnabled', on);
    } on MissingPluginException {
      // Linux, or a platform without the native side — nothing to do.
    } catch (e) {
      debugPrint('ScreenProtection.apply($on) failed: $e');
    }
  }
}
