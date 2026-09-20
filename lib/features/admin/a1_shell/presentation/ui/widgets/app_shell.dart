/// Module: admin / a1_shell
///
///*************************** FILE INFO ****************************///
/// File Name: app_shell.dart
/// Purpose: Declares `AppShell` and `ShellSection` — one navigation frame that
///          is a side rail on a desktop, a narrow icon rail on a tablet and a
///          bottom bar on a phone.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/helper/main_helper/platform_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/theme_controller.dart';
import 'package:asec/features/onboarding/o1_splash/presentation/ui/pages/splash_screen.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/ui/widgets/brand_mark.dart';
import 'package:asec/generated/l10n.dart';

class ShellSection {
  const ShellSection({
    required this.icon,
    required this.label,
    required this.page,
  });

  final IconData icon;
  final String label;
  final Widget page;
}

/// ONE FRAME, THREE SHAPES — and the WIDTH picks, never the platform. A macOS
/// window dragged narrow gets the phone's bottom bar, because at 500pt a
/// 240-wide rail is half the screen.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.sections, required this.user});

  final List<ShellSection> sections;
  final AppUser user;

  /// From here the rail shows its labels.
  static const double railLabelWidth = PlatformHelper.desktopLayoutWidth;

  /// From here there is a rail at all; below it, a bottom bar.
  static const double railWidth = PlatformHelper.tabletBreakpoint;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // The admin can switch an account off, including while its owner is
    // looking at it. The session controller notices and the shell leaves.
    SessionController.to.onDeactivated = _forceSignOut;
  }

  @override
  void dispose() {
    SessionController.to.onDeactivated = null;
    super.dispose();
  }

  Future<void> _forceSignOut() async {
    if (!mounted) return;
    await AppRouter.signOut(context);
  }

  Future<void> _confirmSignOut() async {
    final S s = S.of(context);
    final BuildContext pageContext = context;
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.signOutQuestion,
      subtitle: s.signOutBody,
      confirmLabel: s.signOut,
      cancelLabel: s.cancel,
      onConfirm: () => AppRouter.signOut(pageContext),
    );
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool hasRail = width >= AppShell.railWidth;
    final bool showLabels = width >= AppShell.railLabelWidth;

    // THE SECTION LIST CAN SHRINK UNDER US. The member's "My CV" tab appears
    // and disappears with the admin's switch, live — and an index left
    // pointing past the end would take an IndexedStack down with it.
    final int index = _index.clamp(0, widget.sections.length - 1);

    final Widget body = IndexedStack(
      index: index,
      children: <Widget>[
        for (final ShellSection s in widget.sections) s.page,
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: hasRail ? AppPadding.h : 16,
        // NO TITLE HERE. Every page draws its own, bigger, with the line
        // that says what the page is for — two titles on one screen is one
        // too many. The bar keeps the controls.
        title: const SizedBox.shrink(),
        actions: <Widget>[
          const _ThemeAction(),
          const _LanguageAction(),
          _UserMenu(user: widget.user, onSignOut: _confirmSignOut),
          SizedBox(width: 6.w),
        ],
      ),
      body: hasRail
          ? Row(
              children: <Widget>[
                _Rail(
                  sections: widget.sections,
                  index: index,
                  showLabels: showLabels,
                  onSelected: _select,
                ),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: hasRail
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: _select,
              backgroundColor: AppColors.card,
              destinations: <Widget>[
                for (final ShellSection s in widget.sections)
                  NavigationDestination(
                    icon: AppIcon(s.icon),
                    label: s.label,
                  ),
              ],
            ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.sections,
    required this.index,
    required this.showLabels,
    required this.onSelected,
  });

  final List<ShellSection> sections;
  final int index;
  final bool showLabels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: showLabels ? 232.w : 78.w,
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.h,
              vertical: 18.h,
            ),
            child: showLabels
                ? const BrandMark(size: 40)
                : const BrandMark(size: 34, showName: false),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              itemCount: sections.length,
              itemBuilder: (BuildContext context, int i) => _RailItem(
                section: sections[i],
                selected: i == index,
                showLabel: showLabels,
                onTap: () => onSelected(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.section,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final ShellSection section;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primary : AppColors.secondaryText;

    final Widget content = Container(
      margin: EdgeInsets.symmetric(vertical: 3.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.transparent,
        borderRadius: AppRadius.containerR,
      ),
      child: Row(
        mainAxisAlignment:
            showLabel ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: <Widget>[
          AppIcon(section.icon, size: 20.sp, color: color),
          if (showLabel) ...<Widget>[
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                section.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (selected
                        ? StyleText.fontSize14Weight600
                        : StyleText.fontSize14Weight400)
                    .copyWith(color: color),
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: AppRadius.containerR,
        onTap: onTap,
        child: showLabel
            ? content
            : Tooltip(message: section.label, child: content),
      ),
    );
  }
}

class _ThemeAction extends StatelessWidget {
  const _ThemeAction();

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.to;
    return Obx(
      () => IconButton(
        onPressed: theme.toggleDarkMode,
        tooltip: S.of(context).darkMode,
        icon: AppIcon(
          theme.isDarkMode.value
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
        ),
      ),
    );
  }
}

class _LanguageAction extends StatelessWidget {
  const _LanguageAction();

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = ThemeController.to;
    return IconButton(
      onPressed: theme.toggleLanguage,
      tooltip: S.of(context).language,
      icon: const AppIcon(Icons.translate_rounded),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.user, required this.onSignOut});

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return PopupMenuButton<int>(
      tooltip: user.displayName,
      offset: Offset(0, 46.h),
      icon: AppAvatar(name: user.displayName, size: 32),
      onSelected: (_) => onSignOut(),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        PopupMenuItem<int>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(user.displayName, style: StyleText.fontSize14Weight600),
              Text(
                user.email,
                style: StyleText.fontSize12Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
              SizedBox(height: 4.h),
              Text(
                user.role.label(context),
                style: StyleText.fontSize11Weight600
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: <Widget>[
              AppIcon(Icons.logout_rounded, size: 18.sp, color: AppColors.red),
              SizedBox(width: 10.w),
              Text(
                s.signOut,
                style: StyleText.fontSize14Weight500
                    .copyWith(color: AppColors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
