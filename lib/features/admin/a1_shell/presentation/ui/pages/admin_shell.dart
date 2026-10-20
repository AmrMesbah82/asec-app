/// Module: admin / a1_shell
///
///*************************** FILE INFO ****************************///
/// File Name: admin_shell.dart
/// Purpose: Declares `AdminShell` — what amrmesbah33@gmail.com sees.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/app_shell.dart';
import 'package:asec/features/admin/a2_members/presentation/ui/pages/members_page.dart';
import 'package:asec/features/admin/a3_dashboard/presentation/ui/pages/admin_dashboard_page.dart';
import 'package:asec/features/admin/a4_results/presentation/ui/pages/admin_results_page.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/pages/cv_directory_page.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/pages/admin_engagement_page.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/admin_quizzes_page.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/pages/settings_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/admin_videos_page.dart';
import 'package:asec/features/web/web_control_page.dart';
import 'package:asec/features/tools/t1_unit_converter/presentation/ui/pages/unit_converter_page.dart';
import 'package:asec/features/tools/t2_engineering_calc/data/calc_access.dart';
import 'package:asec/features/tools/t2_engineering_calc/presentation/ui/pages/engineering_calc_page.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    // Obx, so renaming the admin or switching the account off reaches the
    // shell without a sign-out.
    return Obx(() {
      final AppUser admin = SessionController.to.current;
      CalcAccess.remember(admin); // calculators on the offline screen too

      return AppShell(
        user: admin,
        sections: <ShellSection>[
          if (admin.can(AdminPermission.dashboard))
          ShellSection(
            icon: Icons.insights_rounded,
            label: s.dashboard,
            page: AdminDashboardPage(admin: admin),
          ),
          if (admin.can(AdminPermission.videos))
          ShellSection(
            icon: Icons.video_library_rounded,
            label: s.typeVideos,
            page: AdminVideosPage(adminUid: admin.uid),
          ),
          if (admin.can(AdminPermission.quizzes))
          ShellSection(
            icon: Icons.quiz_outlined,
            label: s.quizzes,
            page: AdminQuizzesPage(adminUid: admin.uid),
          ),
          // Courses' final exams: pass with 70% → ASEC certificate.
          if (admin.canDo(AdminAction.quizzesCertificates))
          ShellSection(
            icon: Icons.workspace_premium_rounded,
            label: s.certificateQuizzes,
            shortLabel: s.certificateShort,
            page: AdminQuizzesPage(adminUid: admin.uid, certificate: true),
          ),
          // Notifications, tips & tricks, the member Library and stars.
          if (admin.can(AdminPermission.engagement))
          ShellSection(
            icon: Icons.campaign_rounded,
            label: s.engEngagement,
            page: const AdminEngagementPage(),
          ),
          // Results sits next to the quizzes it reports on, before the
          // people pages: the admin comes here far more often than to
          // Members.
          if (admin.can(AdminPermission.results))
          ShellSection(
            icon: Icons.insights_outlined,
            label: s.results,
            page: const AdminResultsPage(),
          ),
          if (admin.can(AdminPermission.members))
          ShellSection(
            icon: Icons.groups_2_rounded,
            label: s.members,
            page: const MembersPage(),
          ),
          // The admin sees every CV with its review state; the switch that
          // lets a member write one lives on the Members page.
          if (admin.can(AdminPermission.cvs))
          ShellSection(
            icon: Icons.assignment_outlined,
            label: s.cvs,
            page: const CvDirectoryPage(isAdmin: true),
          ),
          // The asecbim website: its whole control panel (content, inbox,
          // control centre, admins, import) on the page beside the drawer.
          if (admin.can(AdminPermission.website))
          ShellSection(
            icon: Icons.language_rounded,
            label: s.permWebsite,
            page: const WebControlPage(),
          ),
          ShellSection(
            icon: Icons.calculate_rounded,
            label: s.unitConverter,
            page: const UnitConverterPage(),
          ),
          // Online only: the offline screen and the sign-in screen keep the
          // unit converter alone, so this tab goes away with the internet.
          ShellSection(
            icon: Icons.engineering_rounded,
            label: s.engineeringCalc,
            shortLabel: s.engineeringCalcShort,
            page: const EngineeringCalcPage(),
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
