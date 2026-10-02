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
import 'package:asec/features/quiz/q2_certificates/presentation/ui/pages/certificate_quizzes_page.dart';
import 'package:asec/features/settings/se1_settings/presentation/ui/pages/settings_page.dart';
import 'package:asec/features/video/v1_videos/data/download/video_downloads.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/downloads_page.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/user_videos_page.dart';
import 'package:asec/features/tools/t1_unit_converter/presentation/ui/pages/unit_converter_page.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/widgets/access_gate.dart';
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

      // The admin's per-member access: paused / not started / ended /
      // wrong device keep the member out with a screen that says why.
      return AccessGate(
        user: user,
        child: AppShell(
        user: user,
        sections: <ShellSection>[
          if (f.isOn(AppFeature.sectionVideos))
          ShellSection(
            icon: Icons.video_library_rounded,
            label: s.typeVideos,
            page: const UserVideosPage(),
          ),
          // Lessons saved inside the app to watch offline (not on the web).
          if (f.isOn(AppFeature.sectionVideos) && VideoDownloads.supported)
          ShellSection(
            icon: Icons.download_for_offline_rounded,
            label: s.downloads,
            page: const DownloadsPage(),
          ),
          if (f.isOn(AppFeature.sectionQuizzes))
          ShellSection(
            icon: Icons.quiz_outlined,
            label: s.quizzes,
            page: UserQuizzesPage(user: user),
          ),
          // Each course's final exam: pass with 70% → ASEC certificate.
          if (f.isOn(AppFeature.sectionVideos))
          ShellSection(
            icon: Icons.workspace_premium_rounded,
            label: s.certificateQuiz,
            shortLabel: s.certificateShort,
            page: CertificateQuizzesPage(user: user),
          ),
          // Everybody browses the directory. The FORM only appears for a
          // member the admin has switched on — no point showing a tab that
          // can only say no.
          if (f.isOn(AppFeature.sectionCvDirectory))
          ShellSection(
            icon: Icons.assignment_outlined,
            label: s.cvs,
            page: const CvDirectoryPage(),
          ),
          if (user.mayWriteCv && f.isOn(AppFeature.sectionMyCv))
            ShellSection(
              icon: Icons.person_outline_rounded,
              label: s.myCv,
              page: CvFormPage(user: user),
            ),
          // Works offline — no Firestore behind it.
          ShellSection(
            icon: Icons.calculate_rounded,
            label: s.unitConverter,
            page: const UnitConverterPage(),
          ),
          ShellSection(
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
