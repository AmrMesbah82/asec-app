/// Module: admin / a1_shell
///
///*************************** FILE INFO ****************************///
/// File Name: admin_shell.dart
/// Purpose: Declares `AdminShell` — what adminamr@gmail.com sees.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/app_shell.dart';
import 'package:asec/features/admin/a2_members/presentation/ui/pages/members_page.dart';
import 'package:asec/features/admin/a3_dashboard/presentation/ui/pages/admin_dashboard_page.dart';
import 'package:asec/features/admin/a4_results/presentation/ui/pages/admin_results_page.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/pages/cv_directory_page.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/admin_quizzes_page.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/pages/settings_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/admin_videos_page.dart';
import 'package:asec/generated/l10n.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    // Obx, so renaming the admin or switching the account off reaches the
    // shell without a sign-out.
    return Obx(() {
      final AppUser admin = SessionController.to.current;

      return AppShell(
        user: admin,
        sections: <ShellSection>[
          ShellSection(
            icon: Icons.insights_rounded,
            label: s.dashboard,
            page: AdminDashboardPage(admin: admin),
          ),
          ShellSection(
            icon: Icons.video_library_rounded,
            label: s.typeVideos,
            page: AdminVideosPage(adminUid: admin.uid),
          ),
          ShellSection(
            icon: Icons.quiz_outlined,
            label: s.quizzes,
            page: AdminQuizzesPage(adminUid: admin.uid),
          ),
          // Results sits next to the quizzes it reports on, before the
          // people pages: the admin comes here far more often than to
          // Members.
          ShellSection(
            icon: Icons.insights_outlined,
            label: s.results,
            page: const AdminResultsPage(),
          ),
          ShellSection(
            icon: Icons.groups_2_rounded,
            label: s.members,
            page: const MembersPage(),
          ),
          // The admin sees every CV with its review state; the switch that
          // lets a member write one lives on the Members page.
          ShellSection(
            icon: Icons.assignment_outlined,
            label: s.cvs,
            page: const CvDirectoryPage(isAdmin: true),
          ),
          ShellSection(
            icon: Icons.settings_rounded,
            label: s.settings,
            page: SettingsPage(user: admin),
          ),
        ],
      );
    });
  }
}
