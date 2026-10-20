/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: device_identity.dart
/// Purpose: Declares `DeviceIdentity` — a random id for THIS copy of the app,
///          for the one-device rule: a member's account is locked to the
///          first device it is used on (`users/{uid}.device_id`), and only
///          the admin can free it (Members → Edit access → Remove device).
/// Author: ASEC team
/// Created: 15/10/2026
///
/// The id is made once and kept on the device (GetStorage). Uninstalling the
/// app or clearing its data makes a new one — to the account that is a new
/// device, so the admin has to remove the old one.

import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';

abstract final class DeviceIdentity {
  static const String _idKey = 'asec_device_id';

  /// The uid whose account this device was locked to. Lets the app tell
  /// "the admin removed THIS device" (stay out) from "no device yet" (take
  /// the slot). Cleared on every sign-in, which is the member saying "use
  /// this device".
  /// v2: the first version could save this from an unconfirmed write, which
  /// wrongly showed "This device was removed"; those old values are ignored.
  static const String _boundKey = 'asec_device_bound_uid_v2';

  static GetStorage get _box => GetStorage();

  static String? _cached;

  /// This device's id — 32 random hex characters, made on first use.
  static String get id {
    final String? cached = _cached;
    if (cached != null) return cached;
    String? stored;
    try {
      stored = _box.read<String>(_idKey);
    } catch (_) {}
    if (stored == null || stored.length < 16) {
      final Random r = Random.secure();
      stored = List<String>.generate(
        16,
        (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      try {
        _box.write(_idKey, stored);
      } catch (_) {}
    }
    return _cached = stored;
  }

  /// What the admin sees: "Mac · amrs-macbook-air", "Android", …
  static String get name {
    final String platform = MemberAccess.platformLabel(MemberAccess.currentPlatform);
    if (kIsWeb) return platform;
    try {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final String host = Platform.localHostname.replaceFirst(RegExp(r'\.local$'), '');
        if (host.isNotEmpty) return '$platform · $host';
      }
    } catch (_) {}
    return platform;
  }

  static String? get boundUid {
    try {
      return _box.read<String>(_boundKey);
    } catch (_) {
      return null;
    }
  }

  static void markBound(String uid) {
    if (boundUid == uid) return;
    try {
      _box.write(_boundKey, uid);
    } catch (_) {}
  }

  static void forgetBinding() {
    try {
      _box.remove(_boundKey);
    } catch (_) {}
  }
}
