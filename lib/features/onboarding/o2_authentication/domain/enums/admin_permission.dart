/// Module: onboarding / o2_authentication
///
///*************************** FILE INFO ****************************///
/// File Name: admin_permission.dart
/// Purpose: Declares `AdminPermission` — what an admin created by the super
///          admin is allowed to do. Stored as a string list `permissions` on
///          `users/{uid}`; firestore.rules checks the same strings.
/// Author: ASEC team
/// Created: 25/9/2026
///
/// The SUPER admin (AppConstants.adminEmail) has every permission and is the
/// only one who can create admins, change their permissions, use the
/// control centre and the demo data.

import 'package:flutter/material.dart';

import 'package:asec/generated/l10n.dart';

enum AdminPermission {
  dashboard('dashboard', Icons.insights_rounded),
  videos('videos', Icons.video_library_rounded),
  quizzes('quizzes', Icons.quiz_outlined),
  results('results', Icons.insights_outlined),
  members('members', Icons.groups_2_rounded),
  cvs('cvs', Icons.assignment_outlined),

  /// Opens the asecbim website control panel — the "Website" drawer tab
  /// (lib/features/web) and /admin on the site. Checked by firestore.rules
  /// `can('website')` on every site_* collection.
  website('website', Icons.language_rounded);

  const AdminPermission(this.key, this.icon);

  final String key;
  final IconData icon;

  static List<AdminPermission> fromKeys(Iterable<String> keys) => <AdminPermission>[
        for (final AdminPermission p in AdminPermission.values)
          if (keys.contains(p.key)) p,
      ];

  String label(BuildContext context) {
    final S s = S.of(context);
    switch (this) {
      case AdminPermission.dashboard:
        return s.dashboard;
      case AdminPermission.videos:
        return s.permVideos;
      case AdminPermission.quizzes:
        return s.permQuizzes;
      case AdminPermission.results:
        return s.permResults;
      case AdminPermission.members:
        return s.permMembers;
      case AdminPermission.cvs:
        return s.permCvs;
      case AdminPermission.website:
        return s.permWebsite;
    }
  }
}
