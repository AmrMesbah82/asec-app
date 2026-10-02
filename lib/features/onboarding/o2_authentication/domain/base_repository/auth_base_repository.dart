/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: auth_base_repository.dart
/// Purpose: Declares `AuthBaseRepository` and `UsersBaseRepository`.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:dartz/dartz.dart';

import 'package:asec/core/network/app_failure.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/auth_failure_type.dart';

/// Signing in, registering and signing out — the current session.
abstract class AuthBaseRepository {
  Future<Either<AuthFailureType, AppUser>> signIn({
    required String email,
    required String password,
  });

  /// Creates the Auth account AND the `users/{uid}` profile. The role comes
  /// from the email, never from the form.
  Future<Either<AuthFailureType, AppUser>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  /// The signed-in user with their profile, or null. Never throws.
  Future<AppUser?> restoreSession();

  Future<Either<AuthFailureType, Unit>> sendPasswordReset(String email);

  Future<void> signOut();

  /// Deletes the signed-in account (profile, CV and Auth user) after
  /// re-checking [password]. On success nobody is signed in any more.
  Future<Either<AuthFailureType, Unit>> deleteAccount(String password);
}

/// Everybody's profiles — what the admin looks at, and what a member may
/// change about themselves.
abstract class UsersBaseRepository {
  Stream<List<AppUser>> watchMembers();

  Stream<AppUser?> watchUser(String uid);

  Future<Either<AppFailure, Unit>> updateSelf(AppUser user);

  Future<Either<AppFailure, Unit>> setActive(String uid, bool active);

  /// The admin's CV switch for one member.
  Future<Either<AppFailure, Unit>> setCanCreateCv(String uid, bool allowed);

  /// Courses, devices and access period for one member.
  Future<Either<AppFailure, Unit>> setAccess(String uid, Map<String, dynamic> access);

  Future<Either<AppFailure, Unit>> pauseAccess(String uid);

  /// Resumes and adds the paused time to the end date.
  Future<Either<AppFailure, Unit>> resumeAccess(AppUser member);
}
