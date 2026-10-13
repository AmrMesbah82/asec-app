/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: calc_access.dart
/// Purpose: Declares `CalcAccess` — whether the engineering calculators are
///          open to whoever is using the app, online AND offline.
/// Author: ASEC team
/// Created: 13/10/2026
///
/// The calculators are a paid extra: the admin unlocks them per member
/// (Members page → "Eng. calculators"). Admins always have them.
///
/// OFFLINE the live profile may not be there (the app was opened with no
/// internet), so the last answer seen online is kept on the device, per
/// account, and used until the profile can be read again.

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';

abstract final class CalcAccess {
  static final GetStorage _box = GetStorage();

  static String _key(String uid) => 'eng_calc_access_$uid';

  /// Saves [user]'s answer for offline use. Called whenever a shell draws.
  static void remember(AppUser user) {
    if (user.isEmpty) return;
    final bool allowed = user.mayUseCalcs;
    if (_box.read<bool>(_key(user.uid)) != allowed) {
      _box.write(_key(user.uid), allowed);
    }
  }

  /// True when the calculators may be shown right now.
  static bool get allowed {
    final AppUser current = Get.isRegistered<SessionController>()
        ? SessionController.to.current
        : AppUser.empty;
    if (!current.isEmpty) return current.mayUseCalcs;

    // No profile loaded (offline start): the signed-in account's last answer.
    String? uid;
    try {
      uid = AppFirebase.uid;
    } catch (_) {
      uid = null;
    }
    if (uid == null || uid.isEmpty) return false;
    return _box.read<bool>(_key(uid)) ?? false;
  }
}
