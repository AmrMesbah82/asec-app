/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: member_access.dart
/// Purpose: Declares `MemberAccess` — whether a MEMBER may use the app right
///          now, on this device: the admin's per-member settings (devices,
///          access period, pause) checked against the clock and the
///          platform the app is running on. Which COURSES they see is
///          `AppUser.canSeeCourse`.
/// Author: ASEC team
/// Created: 1/10/2026

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';

/// Why a member is kept out. [none] = they may use the app.
enum AccessBlock { none, paused, notStarted, expired, platform, otherDevice, deviceRemoved }

abstract final class MemberAccess {
  /// Every platform key the admin can choose from, in display order.
  static const List<String> allPlatforms = <String>[
    'android',
    'ios',
    'macos',
    'windows',
  ];

  static String platformLabel(String key) {
    switch (key) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iPhone / iPad';
      case 'macos':
        return 'Mac';
      case 'windows':
        return 'Windows';
      case 'web':
        return 'Web';
      default:
        return key;
    }
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

  /// Admins are never blocked; members are checked in this order: paused,
  /// not started, ended, wrong platform, wrong device.
  ///
  /// ONE DEVICE: [thisDevice] is this copy's id (DeviceIdentity.id) and
  /// [boundHereUid] the account this device was last locked to. No device
  /// on the account yet = allowed (AccessGate locks it to this one); the
  /// admin removed THIS device = kept out until the member signs in again.
  static AccessBlock check(
    AppUser user, {
    DateTime? now,
    String? thisDevice,
    String? boundHereUid,
  }) {
    if (user.isEmpty || user.isAdmin) return AccessBlock.none;
    final DateTime t = now ?? DateTime.now();
    if (user.isPaused) return AccessBlock.paused;
    if (user.accessFrom != null && t.isBefore(user.accessFrom!)) {
      return AccessBlock.notStarted;
    }
    if (user.accessUntil != null && t.isAfter(user.accessUntil!)) {
      return AccessBlock.expired;
    }
    if (!user.allowsPlatform(currentPlatform)) return AccessBlock.platform;
    if (thisDevice != null) {
      if (!user.hasDevice) {
        if (boundHereUid == user.uid) return AccessBlock.deviceRemoved;
      } else if (user.deviceId != thisDevice) {
        return AccessBlock.otherDevice;
      }
    }
    return AccessBlock.none;
  }
}
