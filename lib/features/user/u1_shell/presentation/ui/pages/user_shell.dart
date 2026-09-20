/// Module: user / u1_shell
///
///*************************** FILE INFO ****************************///
/// File Name: user_shell.dart
/// Purpose: Declares `UserShell` — what a member sees: the lessons, the
///          quizzes and their own settings.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/app_shell.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/pages/cv_directory_page.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/pages/cv_form_page.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/user_quizzes_page.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/pages/settings_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/user_videos_page.dart';
import 'package:asec/generated/l10n.dart';

class UserShell extends StatelessWidget {
  const UserShell({super.key});

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Obx(() {
      final AppUser user = SessionController.to.current;

      return AppShell(
        user: user,
        sections: <ShellSection>[
          ShellSection(
            icon: Icons.video_library_rounded,
            label: s.typeVideos,
            page: const UserVideosPage(),
          ),
          ShellSection(
            icon: Icons.quiz_outlined,
            label: s.quizzes,
            page: UserQuizzesPage(user: user),
          ),
          // Everybody browses the directory. The FORM only appears for a
          // member the admin has switched on — no point showing a tab that
          // can only say no.
          ShellSection(
            icon: Icons.assignment_outlined,
            label: s.cvs,
            page: const CvDirectoryPage(),
          ),
          if (user.mayWriteCv)
            ShellSection(
              icon: Icons.person_outline_rounded,
              label: s.myCv,
              page: CvFormPage(user: user),
            ),
          ShellSection(
            icon: Icons.settings_rounded,
            label: s.settings,
            page: SettingsPage(user: user),
          ),
        ],
      );
    });
  }
}
