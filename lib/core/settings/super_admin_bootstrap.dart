/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: super_admin_bootstrap.dart
/// Purpose: Declares `SuperAdminBootstrap` — creates the super admin account
///          (AppConstants.adminEmail) automatically the first time the app
///          opens, so it does not have to be registered by hand.
/// Author: ASEC team
/// Created: 1/10/2026
///
/// THE PASSWORD IS NOT IN THE CODE. A password written in the source ends up
/// inside every copy of the app, where anyone can pull it out. It is passed
/// at RUN time instead:
///
///   flutter run -d macos --dart-define=SUPER_ADMIN_PASSWORD=your-password
///
/// Without that flag this does nothing, and it only ever runs in a debug
/// build on the developer's machine — a release build never creates
/// accounts. Once the account exists ("email already in use") it marks
/// itself done and never tries again on this device.
///
/// Needs the new firestore.rules deployed first (`firebase deploy --only
/// firestore:rules`), because the rules decide which email may hold the
/// admin role. Cloud Storage is not needed.

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/onboarding/o2_authentication/data/repository/auth_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/auth_failure_type.dart';

abstract final class SuperAdminBootstrap {
  static const String _password = String.fromEnvironment('SUPER_ADMIN_PASSWORD');
  static const String _doneKey = 'super_admin_bootstrapped_v1';

  /// Call once from `main`, after Firebase has started. Never throws.
  static Future<void> run() async {
    if (!kDebugMode || _password.isEmpty || AppFirebase.notConfigured) return;
    final GetStorage box = GetStorage();
    if (box.read<bool>(_doneKey) == true) return;

    try {
      final result = await AuthRepository().register(
        fullName: 'Amr Mesbah',
        email: AppConstants.adminEmail,
        phone: '',
        password: _password,
      );
      result.fold(
        (AuthFailureType failure) {
          if (failure == AuthFailureType.emailInUse) {
            debugPrint('SUPER ADMIN: ${AppConstants.adminEmail} already exists.');
            box.write(_doneKey, true);
          } else {
            debugPrint('SUPER ADMIN: could not create the account — $failure');
          }
        },
        (_) {
          debugPrint('SUPER ADMIN: created ${AppConstants.adminEmail} and signed in.');
          box.write(_doneKey, true);
        },
      );
    } catch (e) {
      debugPrint('SUPER ADMIN: failed — $e');
    }
  }
}
