/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: user_role.dart
/// Purpose: Declares `UserRole` — the two kinds of account in ASEC.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/widgets.dart';

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/generated/l10n.dart';

/// Stored as the `role` string on `users/{uid}`.
///
/// THE ROLE IS NOT A CHOICE. It follows the email: `AppConstants.adminEmail`
/// is the admin, everybody else is a member. The check here is for the UI;
/// `firestore.rules` is the real boundary.
enum UserRole {
  /// Uploads the videos, writes the quizzes, reads every attempt.
  admin('admin'),

  /// Watches the videos and takes the quizzes.
  user('user');

  const UserRole(this.key);

  final String key;

  static UserRole fromKey(String? key) {
    for (final UserRole role in UserRole.values) {
      if (role.key == key) return role;
    }
    // Unknown or missing is the least privileged, never the most.
    return UserRole.user;
  }

  /// The role an email is entitled to. Mirrors `isAdminEmail()` in the rules.
  static UserRole forEmail(String email) =>
      AppConstants.isAdminEmail(email) ? UserRole.admin : UserRole.user;

  bool get isAdmin => this == UserRole.admin;
  bool get isUser => this == UserRole.user;

  /// BOTH ROLES RUN EVERYWHERE — phone, tablet, desktop, macOS and the web.
  /// Every screen in this app has a layout for each width, so nothing is
  /// gated on the device; this getter exists so the router reads as a rule
  /// rather than as a missing check.
  bool canUseOn(BuildContext context) => true;

  String label(BuildContext context) {
    final S s = S.of(context);
    switch (this) {
      case UserRole.admin:
        return s.roleAdminBadge;
      case UserRole.user:
        return s.roleUser;
    }
  }
}
