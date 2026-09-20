/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: users_remote_data_source.dart
/// Purpose: Declares `UsersRemoteDataSource` — every read and write against
///          `users` and Firebase Auth.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/onboarding/o2_authentication/data/models/user_model.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/user_role.dart';

class UsersRemoteDataSource {
  CollectionReference<Map<String, dynamic>> get _users =>
      AppFirebase.db.collection(FirebaseCollections.users);

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<UserCredential> signIn(String email, String password) =>
      AppFirebase.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  Future<void> signOut() => AppFirebase.auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      AppFirebase.auth.sendPasswordResetEmail(email: email.trim());

  User? get currentUser => AppFirebase.auth.currentUser;

  /// Registers on the DEFAULT app, so the new account is left signed in —
  /// which is exactly what someone who just registered expects.
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final UserCredential credential =
        await AppFirebase.auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final User authUser = credential.user!;
    await authUser.updateDisplayName(fullName.trim());

    final AppUser user = AppUser(
      uid: authUser.uid,
      email: email.trim().toLowerCase(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      // THE EMAIL DECIDES, NOT THE FORM.
      role: UserRole.forEmail(email),
    );
    await _users.doc(user.uid).set(UserModel.toMap(user, isCreate: true));
    return user;
  }

  // ── Profiles ─────────────────────────────────────────────────────────────

  Future<AppUser?> fetch(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  /// The profile for [authUser], creating it if the document is missing.
  ///
  /// A missing profile is not a dead end here the way it is in an
  /// admin-provisioned app: the Auth account exists, we know the email, and
  /// the email is what decides the role — so the honest repair is to write
  /// the document rather than to refuse the sign-in. It happens when the
  /// Firestore write failed right after `createUserWithEmailAndPassword`, or
  /// when the account was made in the Firebase console.
  Future<AppUser> fetchOrCreate(User authUser) async {
    final AppUser? existing = await fetch(authUser.uid);
    if (existing != null) return existing;

    final String email = (authUser.email ?? '').toLowerCase();
    final AppUser repaired = AppUser(
      uid: authUser.uid,
      email: email,
      fullName: authUser.displayName ?? '',
      role: UserRole.forEmail(email),
    );
    await _users.doc(repaired.uid).set(UserModel.toMap(repaired, isCreate: true));
    return repaired;
  }

  Stream<AppUser?> watch(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((DocumentSnapshot<Map<String, dynamic>> doc) =>
          doc.exists ? UserModel.fromDoc(doc) : null);

  /// Every member account. Sorted on the client so the query needs no
  /// composite index.
  Stream<List<AppUser>> watchMembers() => _users
      .where(FirebaseCollections.roleField, isEqualTo: UserRole.user.key)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snap) {
        final List<AppUser> users =
            snap.docs.map(UserModel.fromDoc).toList(growable: false).toList()
              ..sort((AppUser a, AppUser b) => a.displayName
                  .toLowerCase()
                  .compareTo(b.displayName.toLowerCase()));
        return users;
      });

  Future<void> updateSelf(AppUser user) =>
      _users.doc(user.uid).update(UserModel.toSelfUpdateMap(user));

  Future<void> setCanCreateCv(String uid, bool allowed) =>
      _users.doc(uid).update(<String, dynamic>{
        FirebaseCollections.canCreateCvField: allowed,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });

  Future<void> setActive(String uid, bool active) =>
      _users.doc(uid).update(<String, dynamic>{
        FirebaseCollections.activeField: active,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      });
}
