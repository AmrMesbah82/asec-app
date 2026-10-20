/// Who is signed in to the panel, and what they may do.
///
/// Same accounts as the ASEC app (one Firebase Auth):
///   * the SUPER admin — `amrmesbah33@gmail.com` — everything, including the
///     app's control centre and the admins list;
///   * an ADMIN the super admin created in the app (`users/{uid}`:
///     role 'admin', active, and `website` in `permissions`) — the website
///     content and its inbox;
///   * anybody else is refused, even with a valid password.
///
/// firestore.rules enforce the same three cases; this class only decides
/// what the panel shows.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/features/web/data/site_repo.dart';

/// Keep in step with `AppConstants.adminEmail` in the ASEC app and
/// `isSuper()` in firestore.rules / storage.rules.
const String kSuperAdminEmail = 'amrmesbah33@gmail.com';

/// The permission string on `users/{uid}.permissions` that opens the panel.
const String kWebsitePermission = 'website';

enum AdminState { loading, signedOut, denied, staff, superAdmin }

class AdminSession extends ChangeNotifier {
  AdminSession._() {
    _sub = FirebaseAuth.instance.authStateChanges().listen(_onUser);
  }

  static final AdminSession instance = AdminSession._();

  StreamSubscription<User?>? _sub;
  AdminState state = AdminState.loading;
  User? user;
  String name = '';
  String? deniedReason;

  bool get isStaff => state == AdminState.staff || state == AdminState.superAdmin;
  bool get isSuper => state == AdminState.superAdmin;
  bool get isResolved => state != AdminState.loading;

  /// The signed-in admin's raw `permissions` strings (see AdminPerms).
  Set<String> keys = <String>{};

  /// Website → [id] ('content', 'inbox' or 'settings').
  bool canWeb(String id) {
    if (isSuper) return true;
    if (!isStaff) return false;
    for (final AdminAction a in AdminPermission.website.actions) {
      if (a.id == id) return AdminPerms.canDo(keys, a);
    }
    return false;
  }

  Future<void> _onUser(User? u) async {
    user = u;
    deniedReason = null;
    keys = <String>{};
    if (u == null) {
      state = AdminState.signedOut;
      name = '';
      notifyListeners();
      return;
    }
    state = AdminState.loading;
    notifyListeners();
    final String email = (u.email ?? '').toLowerCase();
    if (email == kSuperAdminEmail) {
      state = AdminState.superAdmin;
      name = u.displayName ?? 'Super admin';
      notifyListeners();
      return;
    }
    try {
      final DocumentSnapshot<Map<String, dynamic>> snap =
          await SiteRepo.db.collection(Coll.users).doc(u.uid).get();
      final Map<String, dynamic> d = snap.data() ?? <String, dynamic>{};
      final List<dynamic> perms = d['permissions'] is List ? d['permissions'] as List<dynamic> : <dynamic>[];
      name = '${d['full_name'] ?? u.email ?? ''}';
      keys = <String>{...perms.map((dynamic e) => '$e')};
      if (d['role'] == 'admin' && d['active'] == true && perms.contains(kWebsitePermission)) {
        state = AdminState.staff;
      } else {
        state = AdminState.denied;
        deniedReason = d['role'] == 'admin'
            ? 'no_permission'
            : 'not_admin';
      }
    } catch (_) {
      state = AdminState.denied;
      deniedReason = 'not_admin';
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) =>
      FirebaseAuth.instance.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  Future<void> resetPassword(String email) =>
      FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
