/// Module: web
///
///*************************** FILE INFO ****************************///
/// File Name: web_control_page.dart
/// Purpose: Declares `WebControlPage` — the "Website" tab of the ASEC admin
///          drawer. It holds the whole asecbim website control panel
///          (dashboard, inbox, site settings, services, why us, projects,
///          articles, partners, testimonials, control centre, admins,
///          import) on the page beside the drawer.
/// Author: ASEC team
/// Created: 26/9/2026
///
/// The panel pages are the same widgets the stand-alone web panel (/admin,
/// web_main.dart) shows; only the frame differs:
///   * a second menu of the panel's pages — a side list when the page is
///     wide, a row of chips when it is narrow;
///   * a nested Navigator, so an editor opened from a list stays inside the
///     page instead of covering the app's drawer;
///   * the panel follows the app's language switch (Arabic / English) and
///     its light / dark switch — its colours come from the app's own;
///   * every icon is an SVG (AppIcon → AppSvgIcons).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/theme_controller.dart';
import 'package:asec/features/web/admin/admin_session.dart';
import 'package:asec/features/web/admin/admin_shell.dart' show AdminNav, kAdminNav;
import 'package:asec/features/web/admin/panel_nav.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/site_preview_page.dart';

class WebControlPage extends StatefulWidget {
  const WebControlPage({super.key});

  /// From here the panel's own menu is a side list; below, a chip row.
  static const double sideMenuWidth = 860;

  @override
  State<WebControlPage> createState() => _WebControlPageState();
}

class _WebControlPageState extends State<WebControlPage> {
  Uri _uri = Uri.parse('/admin');
  late final Worker _langWorker;

  @override
  void initState() {
    super.initState();
    AdminSession.instance; // starts listening to the signed-in account
    final ThemeController theme = ThemeController.to;
    _syncLanguage(theme.languageCode.value);
    _langWorker = ever<String>(theme.languageCode, _syncLanguage);
  }

  @override
  void dispose() {
    _langWorker.dispose();
    super.dispose();
  }

  void _syncLanguage(String code) {
    final Locale next = Locale(code == 'ar' ? 'ar' : 'en');
    if (AppLang.locale.value != next) AppLang.locale.value = next;
  }

  void _go(String path) {
    final Uri next = Uri.parse(path);
    if (next.path == '/admin/admins' && !AdminSession.instance.isSuper) return;
    if (next.toString() == _uri.toString()) return;
    setState(() => _uri = next);
  }

  /// Bumped when the site preview closes: the preview drew with the site's
  /// light colours, so the panel's pages are rebuilt in the app's look.
  int _generation = 0;

  Future<void> _viewSite() async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const SitePreviewPage()),
    );
    if (mounted) setState(() => _generation++);
  }

  bool _isActive(AdminNav n) => n.path == '/admin' ? _uri.path == '/admin' : _uri.path.startsWith(n.path);

  /// The panel's neutrals, taken from the app's own light / dark colours so
  /// the Website tab looks like every other tab.
  static WebPalette _paletteFromApp() {
    final bool dark = AppTheme.isDark;
    // On dark, raised fills and borders are the card lifted towards white.
    Color lift(double a) => Color.alphaBlend(Colors.white.withValues(alpha: a), AppColors.card);
    return WebPalette(
      isDark: dark,
      page: AppColors.background,
      card: AppColors.card,
      surface: dark ? lift(0.06) : AppColors.background,
      border: dark ? lift(0.14) : AppColors.fieldBorder,
      text: AppColors.text,
      heading: AppColors.text,
      muted: AppColors.secondaryText,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obx: rebuild when the app's dark mode or language switch flips.
    return Obx(() {
      final ThemeController theme = ThemeController.to;
      final bool dark = theme.isDarkMode.value;
      final String lang = theme.languageCode.value;
      _syncLanguage(lang);

      final WebPalette palette = _paletteFromApp();
      WebColors.palette = palette;

      return ListenableBuilder(
        listenable: AdminSession.instance,
        builder: (BuildContext context, _) {
          final AdminSession s = AdminSession.instance;
          return Theme(
            data: WebTheme.of(palette),
            child: Directionality(
              textDirection: AppLang.direction,
              child: Material(
                color: WebColors.adminBg,
                child: !s.isResolved
                    ? const Loading(height: double.infinity)
                    : !s.isStaff
                        ? const _NoAccess()
                        : WebPanelScope(go: _go, child: _frame(s, '$lang|$dark')),
              ),
            ),
          );
        },
      );
    });
  }

  /// [look] is the language + theme: part of the Navigator's key, so a
  /// language or dark-mode switch redraws the open page in the new look.
  Widget _frame(AdminSession s, String look) {
    final List<AdminNav> items = kAdminNav.where((AdminNav n) => !n.superOnly || s.isSuper).toList();

    // A fresh Navigator per page: switching pages drops any editor that was
    // open on the previous one, like the web panel's URL change does.
    final Widget content = ClipRect(
      child: Navigator(
        key: ValueKey<String>('$_uri|$look|$_generation'),
        onGenerateRoute: (RouteSettings settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Material(color: WebColors.adminBg, child: panelPageFor(_uri)),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        if (c.maxWidth >= WebControlPage.sideMenuWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 240,
                child: _SideMenu(items: items, isActive: _isActive, onTap: _go, onViewSite: _viewSite),
              ),
              VerticalDivider(width: 1, color: WebColors.border),
              Expanded(child: content),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ChipMenu(items: items, isActive: _isActive, onTap: _go, onViewSite: _viewSite),
            Divider(height: 1, color: WebColors.border),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}

/// The panel's pages as a list, grouped like the web panel's side menu.
class _SideMenu extends StatelessWidget {
  const _SideMenu({required this.items, required this.isActive, required this.onTap, required this.onViewSite});

  final List<AdminNav> items;
  final bool Function(AdminNav) isActive;
  final ValueChanged<String> onTap;

  /// Opens the in-app preview of the public site.
  final VoidCallback onViewSite;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tiles = <Widget>[
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 6),
        child: Row(
          children: <Widget>[
            Image.asset('assets/web/images/logo.png', height: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                const L('الموقع الإلكتروني', 'Website').t,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: WebColors.navy),
              ),
            ),
          ],
        ),
      ),
    ];
    L? lastGroup;
    for (final AdminNav n in items) {
      if (n.group != null && n.group != lastGroup) {
        tiles.add(Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 4),
          child: Text(n.group!.t,
              style: TextStyle(color: WebColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ));
        lastGroup = n.group;
      }
      final bool active = isActive(n);
      tiles.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        child: ListTile(
          dense: true,
          selected: active,
          selectedTileColor: WebColors.red.withValues(alpha: 0.1),
          selectedColor: WebColors.red,
          iconColor: WebColors.ink,
          textColor: WebColors.ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: AppIcon(n.icon, size: 20),
          title: Text(n.label.t, style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
          onTap: () => onTap(n.path),
        ),
      ));
    }
    tiles.add(Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      child: OutlinedButton.icon(
        onPressed: onViewSite,
        icon: const AppIcon(Icons.open_in_new_rounded, size: 18),
        label: Text(const L('عرض الموقع', 'View site').t),
      ),
    ));
    // A Material, not a ColoredBox: ListTile paints its selected fill and
    // its ink ON the nearest Material, so a ColoredBox in between hides both
    // (and Flutter asserts "ListTile background color or ink splashes may be
    // invisible"). Half-transparent over the page, so it reads as a second
    // layer beside the app's own drawer.
    return Material(
      color: WebColors.card.withValues(alpha: 0.5),
      child: ListView(padding: const EdgeInsets.only(bottom: 8), children: tiles),
    );
  }
}

/// The same pages as one scrollable row of chips, for a narrow page.
class _ChipMenu extends StatelessWidget {
  const _ChipMenu({required this.items, required this.isActive, required this.onTap, required this.onViewSite});

  final List<AdminNav> items;
  final bool Function(AdminNav) isActive;
  final ValueChanged<String> onTap;

  /// Opens the in-app preview of the public site.
  final VoidCallback onViewSite;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // Half-transparent over the page, so it reads as a second layer
      // beside the app's own drawer.
      color: WebColors.card.withValues(alpha: 0.5),
      child: SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          children: <Widget>[
            for (final AdminNav n in items)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  selected: isActive(n),
                  showCheckmark: false,
                  avatar: AppIcon(n.icon, size: 18, color: isActive(n) ? WebColors.white : WebColors.ink),
                  label: Text(n.label.t),
                  labelStyle: TextStyle(
                    color: isActive(n) ? WebColors.white : WebColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: WebColors.red,
                  backgroundColor: WebColors.surface,
                  side: BorderSide(color: WebColors.border),
                  onSelected: (_) => onTap(n.path),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ActionChip(
                avatar: AppIcon(Icons.open_in_new_rounded, size: 18, color: WebColors.navy),
                label: Text(const L('عرض الموقع', 'View site').t),
                backgroundColor: WebColors.surface,
                side: BorderSide(color: WebColors.border),
                onPressed: onViewSite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyNote(
            const L(
              'حسابك ليس له صلاحية "الموقع الإلكتروني". اطلبها من المشرف الرئيسي في الإعدادات ← المشرفون.',
              'Your account has no "Website" permission. Ask the super admin (Settings → Admins).',
            ).t,
            icon: Icons.lock_outline_rounded,
          ),
        ),
      );
}
