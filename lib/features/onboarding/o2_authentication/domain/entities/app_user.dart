/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: app_user.dart
/// Purpose: Declares `AppUser` — an account as the UI understands it.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:asec/features/onboarding/o2_authentication/domain/enums/user_role.dart';

class AppUser {
  /// Firebase Auth uid, and the id of the `users` document.
  final String uid;
  final String email;
  final String fullName;
  final String phone;
  final UserRole role;

  /// False = the admin switched the account off. It can still sign in to
  /// Firebase Auth, but the app refuses it right after.
  final bool active;

  /// The admin's switch: may this member write a CV? Off by default, so a new
  /// account sees no CV form until somebody says yes. The admin always may.
  final bool canCreateCv;

  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.fullName = '',
    this.phone = '',
    this.active = true,
    this.canCreateCv = false,
    this.createdAt,
  });

  static const AppUser empty =
      AppUser(uid: '', email: '', role: UserRole.user);

  bool get isEmpty => uid.isEmpty;
  bool get isAdmin => role.isAdmin;

  /// Whether the CV form should be offered. The admin needs no permission —
  /// the switch exists to let members in, not to keep the admin out.
  bool get mayWriteCv => isAdmin || canCreateCv;

  /// What to greet them with.
  String get displayName =>
      fullName.trim().isNotEmpty ? fullName.trim() : email.split('@').first;

  String get firstName => displayName.split(' ').first;

  /// Two letters, for places that want initials rather than a picture.
  String get initials {
    final String source = displayName;
    if (source.isEmpty) return '?';
    final List<String> parts = source
        .split(RegExp(r'[\s@._-]+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phone,
    UserRole? role,
    bool? active,
    bool? canCreateCv,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      active: active ?? this.active,
      canCreateCv: canCreateCv ?? this.canCreateCv,
      createdAt: createdAt,
    );
  }
}
