/// Module: settings / se1_settings
///
///*************************** FILE INFO ****************************///
/// File Name: admins_repository.dart
/// Purpose: Declares `AdminsRepository` — the super admin's tools for other
///          admins: list them, create one (Auth account + profile), change
///          what they may do, switch them off, remove them.
/// Author: ASEC team
/// Created: 25/9/2026
///
/// The Auth account is created on the secondary "account factory" app
/// (AppFirebase.createAccount), so the super admin stays signed in.
/// Removing an admin deletes the PROFILE — without it the account cannot use
/// the app. The Auth login itself can only be deleted from the Firebase
/// console (a client may not delete somebody else's login).

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/onboarding/o2_authentication/data/models/user_model.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/user_role.dart';

class AdminsRepository {
  CollectionReference<Map<String, dynamic>> get _users =>
      AppFirebase.db.collection(FirebaseCollections.users);

  Stream<List<AppUser>> watchAdmins() => _users
      .where(FirebaseCollections.roleField, isEqualTo: 'admin')
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
          .map(UserModel.fromDoc)
          .where((AppUser u) => !u.isSuperAdmin)
          .toList()
        ..sort((AppUser a, AppUser b) => a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase())));

  Future<void> createAdmin({
    required String fullName,
    required String email,
    required String password,
    required List<AdminPermission> permissions,
  }) async {
    final String uid = await AppFirebase.createAccount(
      email: email,
      password: password,
    );
    final AppUser admin = AppUser(
      uid: uid,
      email: email.trim().toLowerCase(),
      fullName: fullName.trim(),
      role: UserRole.admin,
      permissions: permissions,
    );
    await _users.doc(uid).set(UserModel.toAdminMap(admin));
  }

  Future<void> setPermissions(String uid, List<AdminPermission> permissions) =>
      _users.doc(uid).update(<String, dynamic>{
        UserModel.permissions: <String>[
          for (final AdminPermission p in permissions) p.key,
        ],
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });

  Future<void> setActive(String uid, bool active) =>
      _users.doc(uid).update(<String, dynamic>{
        FirebaseCollections.activeField: active,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });

  Future<void> remove(String uid) => _users.doc(uid).delete();
}
