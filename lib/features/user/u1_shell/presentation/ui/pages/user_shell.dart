/// Module: user / u1_shell
///
///*************************** FILE INFO ****************************///
/// File Name: user_shell.dart
/// Purpose: Declares `UserShell` — what a member sees: a home page, the
///          lessons, the unit converter, the quizzes, the CVs and their own
///          settings (with "My space" inside).
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/app_shell.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/pages/cv_directory_page.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/user_quizzes_page.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/pages/settings_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/user_videos_page.dart';
import 'package:asec/features/tools/t1_unit_converter/presentation/ui/pages/unit_converter_page.dart';
import 'package:asec/features/tools/t2_engineering_calc/data/calc_access.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/widgets/access_gate.dart';
import 'package:asec/features/user/u2_home/presentation/ui/pages/member_home_page.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/settings/app_features.dart';

class UserShell extends StatelessWidget {
  const UserShell({super.key});

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Obx(() {
      final AppUser user = SessionController.to.current;
      final AppFeatures f = AppFeatures.to;
      f.values.length; // tracked by Obx: a switch flipped live rebuilds the menu

      // The calculators' unlock is remembered on the device so they still
      // open on the offline screen (CalcAccess).
      CalcAccess.remember(user);

      // The admin's per-member access: paused / not started / ended /
      // wrong device keep the member out with a screen that says why.
      //
      // THE MENU IS KEPT TO THE EVERYDAY SECTIONS — Home, Videos, the unit
      // converter, quizzes, CVs, Settings. My CV, the certificate quiz,
      // downloads and the engineering calculators (once bought) live in
      // Settings → "My space" and on the home page (member_links.dart).
      return AccessGate(
        user: user,
        child: AppShell(
          user: user,
          sections: <ShellSection>[
            ShellSection(
              id: MemberSectionIds.home,
              icon: Icons.home_rounded,
              label: s.home,
              page: const MemberHomePage(),
            ),
            if (f.isOn(AppFeature.sectionVideos))
              ShellSection(
                id: MemberSectionIds.videos,
                icon: Icons.video_library_rounded,
                label: s.typeVideos,
                page: const UserVideosPage(),
              ),
            // Works offline — no Firestore behind it.
            ShellSection(
              id: MemberSectionIds.converter,
              icon: Icons.calculate_rounded,
              label: s.unitConverter,
              shortLabel: s.unitConverterShort,
              page: const UnitConverterPage(),
            ),
            if (f.isOn(AppFeature.sectionQuizzes))
              ShellSection(
                id: MemberSectionIds.quizzes,
                icon: Icons.quiz_outlined,
                label: s.quizzes,
                page: UserQuizzesPage(user: user),
              ),
            if (f.isOn(AppFeature.sectionCvDirectory))
              ShellSection(
                id: MemberSectionIds.cvs,
                icon: Icons.assignment_outlined,
                label: s.cvs,
                page: const CvDirectoryPage(),
              ),
            ShellSection(
              id: MemberSectionIds.settings,
              icon: Icons.settings_rounded,
              label: s.settings,
              page: SettingsPage(user: user),
            ),
          ],
        ),
      );
    });
  }
}
