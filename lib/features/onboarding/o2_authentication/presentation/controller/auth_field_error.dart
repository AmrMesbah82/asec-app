/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: auth_field_error.dart
/// Purpose: Declares `AuthFieldError` — what a form field got wrong BEFORE
///          anything reached Firebase.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/widgets.dart';

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/generated/l10n.dart';

/// Local validation only. Anything Firebase decides is an
/// `AuthFailureType` — the two are kept apart so a screen can show "this
/// email is malformed" under the field and "no connection" in the banner.
enum AuthFieldError {
  emailEmpty,
  emailInvalid,
  passwordEmpty,
  passwordShort,
  passwordsDiffer,
  nameEmpty;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static AuthFieldError? forEmail(String value) {
    final String email = value.trim();
    if (email.isEmpty) return AuthFieldError.emailEmpty;
    if (!_emailPattern.hasMatch(email)) return AuthFieldError.emailInvalid;
    return null;
  }

  static AuthFieldError? forNewPassword(String value) {
    if (value.isEmpty) return AuthFieldError.passwordEmpty;
    if (value.length < AppConstants.minPasswordLength) {
      return AuthFieldError.passwordShort;
    }
    return null;
  }

  static AuthFieldError? forName(String value) =>
      value.trim().isEmpty ? AuthFieldError.nameEmpty : null;

  String message(BuildContext context) {
    final S s = S.of(context);
    switch (this) {
      case AuthFieldError.emailEmpty:
        return s.enterEmail;
      case AuthFieldError.emailInvalid:
        return s.errInvalidEmail;
      case AuthFieldError.passwordEmpty:
        return s.enterPassword;
      case AuthFieldError.passwordShort:
        return s.errWeakPassword;
      case AuthFieldError.passwordsDiffer:
        return s.errPasswordsDiffer;
      case AuthFieldError.nameEmpty:
        return s.enterName;
    }
  }
}
