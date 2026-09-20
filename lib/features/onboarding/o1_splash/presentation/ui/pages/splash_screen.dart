/// Module: onboarding / o1_splash
///
///*************************** FILE INFO ****************************///
/// File Name: splash_screen.dart
/// Purpose: Declares `SplashScreen` and `AppRouter` — the one place that
///          decides where an account lands.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/pages/admin_shell.dart';
import 'package:asec/features/onboarding/o2_authentication/data/repository/auth_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/user_role.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/ui/pages/sign_in_screen.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/ui/widgets/brand_mark.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/pages/user_shell.dart';

/// Where an account goes. Used by the splash after restoring a session, and by
/// the sign-in and register screens after a fresh one — ONE copy of the rule.
///
///   no session   -> SignInScreen
///   admin        -> AdminShell
///   member       -> UserShell
///
/// Both shells run on every device, so nothing here asks what kind of machine
/// this is; each screen has a layout for its width.
abstract final class AppRouter {
  const AppRouter._();

  static Widget destinationFor(BuildContext context, AppUser? user) {
    if (user == null) return const SignInScreen();

    switch (user.role) {
      case UserRole.admin:
        return const AdminShell();
      case UserRole.user:
        return const UserShell();
    }
  }

  /// Replaces the whole stack with [user]'s destination.
  ///
  /// The live session starts HERE, before the route is built, never inside a
  /// build method: starting it sets an observable, and changing an observable
  /// mid-build is a framework error.
  static void go(BuildContext context, AppUser? user) {
    if (user != null) SessionController.to.start(user);

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (BuildContext ctx, _, __) => destinationFor(ctx, user),
        transitionsBuilder:
            (_, Animation<double> animation, __, Widget child) =>
                FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
      (Route<dynamic> _) => false,
    );
  }

  /// Signs out and returns to the sign-in screen.
  static Future<void> signOut(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    await SessionController.to.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
      (Route<dynamic> _) => false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final Animation<double> _scale =
      CurvedAnimation(parent: _intro, curve: Curves.easeOutBack);

  @override
  void initState() {
    super.initState();
    _route();
  }

  /// Session restore and the minimum splash time run together; whichever is
  /// slower decides when we leave.
  Future<void> _route() async {
    final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
      AuthRepository().restoreSession(),
      Future<void>.delayed(AppConstants.splashDuration),
    ]);
    if (!mounted) return;
    AppRouter.go(context, results.first as AppUser?);
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _intro,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const BrandMark(size: 84, vertical: true, onDark: true),
                  SizedBox(height: 36.h),
                  SizedBox(
                    width: 26.r,
                    height: 26.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
