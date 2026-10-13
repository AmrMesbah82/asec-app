/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: app_user.dart
/// Purpose: Declares `AppUser` — an account as the UI understands it.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
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

  /// The admin's switch: has this member bought the engineering calculators?
  /// Off by default — the calculators are a paid extra. The admin always may.
  final bool canUseCalcs;

  final DateTime? createdAt;

  /// For an admin created by the super admin: what they may manage.
  /// Ignored for the super admin (who may do everything) and for members.
  final List<AdminPermission> permissions;

  // ── Member access (set by the admin on the Members page) ──────────────────

  /// True = every course, including ones added later. False = only [courses].
  final bool allCourses;

  /// Video categories this member may watch ('' = the "General" category).
  final List<String> courses;

  /// Platform keys the member may open the app on (android, ios, macos,
  /// windows, web). Empty = every platform.
  final List<String> platforms;

  /// The access window. Both null = permanent.
  final DateTime? accessFrom;
  final DateTime? accessUntil;

  /// Set while the admin has paused the access. On resume, the paused time
  /// is added to [accessUntil].
  final DateTime? pausedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.fullName = '',
    this.phone = '',
    this.active = true,
    this.canCreateCv = false,
    this.canUseCalcs = false,
    this.createdAt,
    this.permissions = const <AdminPermission>[],
    this.allCourses = true,
    this.courses = const <String>[],
    this.platforms = const <String>[],
    this.accessFrom,
    this.accessUntil,
    this.pausedAt,
  });

  bool get isPaused => pausedAt != null;
  bool get isPermanent => accessFrom == null && accessUntil == null;

  /// Whether this member may see [category]. Admins see everything.
  bool canSeeCourse(String category) =>
      isAdmin || allCourses || courses.contains(category.trim());

  bool allowsPlatform(String platform) =>
      isAdmin || platforms.isEmpty || platforms.contains(platform);

  static const AppUser empty =
      AppUser(uid: '', email: '', role: UserRole.user);

  bool get isEmpty => uid.isEmpty;
  bool get isAdmin => role.isAdmin;

  /// The owner account — the one email in AppConstants.adminEmail.
  bool get isSuperAdmin => isAdmin && AppConstants.isAdminEmail(email);

  /// Whether this account may manage [p]. The super admin always may.
  bool can(AdminPermission p) =>
      isSuperAdmin || (isAdmin && permissions.contains(p));

  /// Whether the CV form should be offered. The admin needs no permission —
  /// the switch exists to let members in, not to keep the admin out.
  bool get mayWriteCv => isAdmin || canCreateCv;

  /// Whether the engineering calculators are open to this account.
  bool get mayUseCalcs => isAdmin || canUseCalcs;

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
    bool? canUseCalcs,
    List<AdminPermission>? permissions,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      active: active ?? this.active,
      canCreateCv: canCreateCv ?? this.canCreateCv,
      canUseCalcs: canUseCalcs ?? this.canUseCalcs,
      createdAt: createdAt,
      permissions: permissions ?? this.permissions,
      allCourses: allCourses,
      courses: courses,
      platforms: platforms,
      accessFrom: accessFrom,
      accessUntil: accessUntil,
      pausedAt: pausedAt,
    );
  }
}
