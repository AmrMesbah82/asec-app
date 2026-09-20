/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: user_model.dart
/// Purpose: Declares `UserModel` — the `users/{uid}` document shape.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/helper/main_helper/firestore_mapper.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/user_role.dart';

/// Field names here MUST match the `onlyKeys` lists in firestore.rules — a
/// client that writes `full_name` against rules expecting `name` has every
/// save refused, and the error says nothing useful.
abstract final class UserModel {
  const UserModel._();

  static const String fullName = 'full_name';
  static const String email = 'email';
  static const String phone = 'phone';

  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.safeData;

    return AppUser(
      uid: doc.id,
      email: data.str(email),
      fullName: data.str(fullName),
      phone: data.str(phone),
      role: UserRole.fromKey(data.str(FirebaseCollections.roleField)),
      active: data.boolean(FirebaseCollections.activeField, true),
      canCreateCv: data.boolean(FirebaseCollections.canCreateCvField),
      createdAt: data.date(FirebaseCollections.createdAtField),
    );
  }

  /// The whole profile. Used on register, so no field is ever half-written.
  static Map<String, dynamic> toMap(AppUser user, {bool isCreate = false}) {
    return <String, dynamic>{
      email: user.email.trim().toLowerCase(),
      fullName: user.fullName.trim(),
      phone: user.phone.trim(),
      FirebaseCollections.roleField: user.role.key,
      FirebaseCollections.activeField: user.active,
      FirebaseCollections.canCreateCvField: user.canCreateCv,
      if (isCreate)
        FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
      FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
    };
  }

  /// What a user may change about themselves: name and phone, nothing else.
  /// Not the role — that is the whole point of keeping this map small.
  static Map<String, dynamic> toSelfUpdateMap(AppUser user) =>
      <String, dynamic>{
        fullName: user.fullName.trim(),
        phone: user.phone.trim(),
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      };
}
