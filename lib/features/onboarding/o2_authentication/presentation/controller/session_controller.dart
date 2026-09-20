/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: session_controller.dart
/// Purpose: Declares `SessionController` — who is signed in, kept live.
/// Author: ASEC team
/// Created: 19/9/2026

import 'dart:async';

import 'package:get/get.dart';

import 'package:asec/features/onboarding/o2_authentication/data/repository/auth_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/base_repository/auth_base_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';

/// The signed-in account, app-wide.
///
/// Registered permanently in `main.dart`, next to the theme controller — both
/// shells need the current user, and threading it through every constructor
/// is how a codebase ends up re-reading the same profile in four cubits.
///
/// LIVE: after sign-in it subscribes to the user's own document, so an admin
/// switching an account off takes effect without a sign-out — [onDeactivated]
/// fires and the shell returns to the sign-in screen.
class SessionController extends GetxController {
  SessionController({
    AuthBaseRepository? auth,
    UsersBaseRepository? users,
  })  : _auth = auth ?? AuthRepository(),
        _users = users ?? UsersRepository();

  static SessionController get to => Get.find<SessionController>();

  final AuthBaseRepository _auth;
  final UsersBaseRepository _users;

  final Rxn<AppUser> user = Rxn<AppUser>();

  /// Called when the live profile says the account was switched off or
  /// deleted. Set by whichever shell is showing.
  void Function()? onDeactivated;

  StreamSubscription<AppUser?>? _sub;

  AppUser get current => user.value ?? AppUser.empty;
  String get uid => current.uid;
  bool get isAdmin => current.isAdmin;

  /// Starts following [signedIn]'s profile document.
  void start(AppUser signedIn) {
    user.value = signedIn;
    _sub?.cancel();
    _sub = _users.watchUser(signedIn.uid).listen(
      (AppUser? live) {
        if (live == null || !live.active) {
          onDeactivated?.call();
          return;
        }
        user.value = live;
      },
      // A transient read error must not sign anybody out.
      onError: (Object _) {},
    );
  }

  Future<void> signOut() async {
    await _sub?.cancel();
    _sub = null;
    // `user` keeps its last value on purpose: clearing it would rebuild every
    // page still on screen during the sign-out transition with an empty user,
    // and each would open queries it is no longer allowed to run.
    onDeactivated = null;
    await _auth.signOut();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
