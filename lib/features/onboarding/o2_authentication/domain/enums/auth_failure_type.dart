/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: auth_failure_type.dart
/// Purpose: Declares `AuthFailureType` — every way signing in or registering
///          can fail.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/widgets.dart';

import 'package:asec/generated/l10n.dart';

/// A closed set, so the UI keeps control of the wording and can put an error
/// under the right field.
enum AuthFailureType {
  wrongCredentials,
  invalidEmail,
  emailInUse,
  weakPassword,
  userDisabled,
  tooManyRequests,
  network,

  /// The admin switched this account off.
  accountInactive,

  /// macOS only: Firebase Auth could not reach the Keychain, so it refused a
  /// sign-in that had otherwise WORKED. It means the app is missing the
  /// `keychain-access-groups` entitlement or is not signed with a team — not
  /// that the password was wrong, which is why it gets its own message.
  keychain,

  /// Auth worked, then Firestore did not answer — usually no database created
  /// in the project yet.
  firestoreUnavailable,

  /// Firestore answered and the rules said no — usually rules not deployed.
  rulesDenied,

  notConfigured,
  unknown;

  static AuthFailureType fromCode(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return AuthFailureType.wrongCredentials;
      case 'invalid-email':
        return AuthFailureType.invalidEmail;
      case 'email-already-in-use':
        return AuthFailureType.emailInUse;
      case 'weak-password':
        return AuthFailureType.weakPassword;
      case 'user-disabled':
        return AuthFailureType.userDisabled;
      case 'too-many-requests':
        return AuthFailureType.tooManyRequests;
      case 'network-request-failed':
      case 'unavailable':
        return AuthFailureType.network;
      case 'permission-denied':
        return AuthFailureType.rulesDenied;
      case 'keychain-error':
        return AuthFailureType.keychain;
      default:
        return AuthFailureType.unknown;
    }
  }

  bool get isEmailError =>
      this == AuthFailureType.invalidEmail ||
      this == AuthFailureType.emailInUse;

  bool get isPasswordError =>
      this == AuthFailureType.wrongCredentials ||
      this == AuthFailureType.weakPassword;

  String message(BuildContext context) {
    final S s = S.of(context);
    switch (this) {
      case AuthFailureType.wrongCredentials:
        return s.errWrongCredentials;
      case AuthFailureType.invalidEmail:
        return s.errInvalidEmail;
      case AuthFailureType.emailInUse:
        return s.errEmailInUse;
      case AuthFailureType.weakPassword:
        return s.errWeakPassword;
      case AuthFailureType.userDisabled:
        return s.errUserDisabled;
      case AuthFailureType.tooManyRequests:
        return s.errTooManyRequests;
      case AuthFailureType.network:
        return s.errNetwork;
      case AuthFailureType.accountInactive:
        return s.errAccountInactive;
      case AuthFailureType.keychain:
        return s.errKeychain;
      case AuthFailureType.firestoreUnavailable:
        return s.errFirestoreUnavailable;
      case AuthFailureType.rulesDenied:
        return s.errRulesDenied;
      case AuthFailureType.notConfigured:
        return s.errNotConfigured;
      case AuthFailureType.unknown:
        return s.errUnknown;
    }
  }
}
