/// Module: settings / se1_settings
///
///*************************** FILE INFO ****************************///
/// File Name: settings_page.dart
/// Purpose: Declares `SettingsPage` — appearance, language, haptics, the
///          account, and the way out.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/112-powered_by_footer.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/haptic_controller.dart';
import 'package:asec/core/theme/theme_controller.dart';
import 'package:asec/features/admin/a5_demo/presentation/ui/widgets/demo_data_card.dart';
import 'package:asec/features/onboarding/o1_splash/presentation/ui/pages/splash_screen.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/generated/l10n.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.user});

  final AppUser user;

  Future<void> _confirmSignOut(BuildContext context) async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.signOutQuestion,
      subtitle: s.signOutBody,
      confirmLabel: s.signOut,
      cancelLabel: s.cancel,
      onConfirm: () => AppRouter.signOut(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final ThemeController theme = ThemeController.to;
    final HapticController haptics = Get.find<HapticController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 640.w),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.h,
              vertical: 16.h,
            ),
            children: <Widget>[
              // ── Who is signed in ─────────────────────────────────────────
              AppCard(
                child: Row(
                  children: <Widget>[
                    AppAvatar(name: user.displayName, size: 52),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            user.displayName,
                            style: StyleText.fontSize16Weight600,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            user.email,
                            style: StyleText.fontSize13Weight400
                                .copyWith(color: AppColors.secondaryText),
                          ),
                          if (user.createdAt != null) ...<Widget>[
                            SizedBox(height: 2.h),
                            Text(
                              s.memberSince(
                                AppDates.day(context, user.createdAt),
                              ),
                              style: StyleText.fontSize12Weight400
                                  .copyWith(color: AppColors.secondaryText),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        user.role.label(context),
                        style: StyleText.fontSize11Weight600
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // ── Appearance ───────────────────────────────────────────────
              AppCard(
                title: s.appearance,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Each tile gets a transparent Material of its own:
                    // ListTile paints its ink on the nearest Material
                    // ancestor, and the card's coloured box sits in between.
                    Obx(
                      () => _SettingsTile(
                        icon: Icons.dark_mode_rounded,
                        title: s.darkMode,
                        trailing: Switch.adaptive(
                          value: theme.isDarkMode.value,
                          activeTrackColor: AppColors.primary,
                          onChanged: theme.setDarkMode,
                        ),
                      ),
                    ),
                    Obx(
                      () => _SettingsTile(
                        icon: Icons.translate_rounded,
                        title: s.language,
                        onTap: theme.toggleLanguage,
                        trailing: Text(
                          theme.languageCode.value == 'ar'
                              ? 'العربية'
                              : 'English',
                          style: StyleText.fontSize13Weight600
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                    Obx(
                      () => _SettingsTile(
                        icon: Icons.vibration_rounded,
                        title: s.haptics,
                        trailing: Switch.adaptive(
                          value: haptics.isHapticEnabled.value,
                          activeTrackColor: AppColors.primary,
                          onChanged: haptics.toggleHapticFeedback,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // ── Branding (admin only — it changes the app for everybody
              //    on THIS device, so it is not hidden behind a rule) ───────
              if (user.isAdmin)
                AppCard(
                  title: s.branding,
                  caption: s.brandingLocalHint,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Obx(
                        () => Row(
                          children: <Widget>[
                            _Swatch(color: theme.primaryColor.value),
                            SizedBox(width: 8.w),
                            _Swatch(color: theme.secondaryColor.value),
                            const Spacer(),
                            AppButton(
                              label: s.resetColors,
                              icon: Icons.refresh_rounded,
                              kind: AppButtonKind.subtle,
                              dense: true,
                              onPressed: theme.resetBrandingColors,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (user.isAdmin) SizedBox(height: 16.h),

              // ── Demo data (admin only) ───────────────────────────────────
              //
              // Here rather than on the dashboard because it is a tool for
              // LOOKING at the app, and the dashboard is the screen its
              // numbers change most — a button that rewrites the chart you are
              // reading does not belong on top of that chart.
              if (user.isAdmin) ...<Widget>[
                DemoDataCard(adminUid: user.uid),
                SizedBox(height: 16.h),
              ],


              AppButton(
                label: s.signOut,
                icon: Icons.logout_rounded,
                kind: AppButtonKind.danger,
                expand: true,
                onPressed: () => _confirmSignOut(context),
              ),
              SizedBox(height: 24.h),
              const PoweredByFooter(),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in a settings card: icon, label, and whatever control belongs on
/// the end. The Material is not decoration — see the comment at the call site.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: AppIcon(icon),
        title: Text(title, style: StyleText.fontSize14Weight500),
        trailing: trailing,
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderGrey),
        ),
      );
}
