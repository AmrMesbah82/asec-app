/// The panel's frame: side menu (drawer on phones), top bar with the account,
/// language switch, "view site" and sign-out.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/admin/admin_session.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';

class AdminNav {
  const AdminNav(this.path, this.label, this.icon, {this.superOnly = false, this.group});

  final String path;
  final L label;
  final IconData icon;
  final bool superOnly;
  final L? group;
}

const L _gSite = L('محتوى الموقع', 'Website content');
const L _gControl = L('التحكم', 'Control');

const List<AdminNav> kAdminNav = <AdminNav>[
  AdminNav('/admin', L('لوحة المعلومات', 'Dashboard'), Icons.space_dashboard_outlined),
  AdminNav('/admin/inbox', L('الوارد', 'Inbox'), Icons.inbox_outlined),
  AdminNav('/admin/site', L('إعدادات الموقع', 'Site settings'), Icons.tune_rounded, group: _gSite),
  AdminNav('/admin/services', L('الخدمات', 'Services'), Icons.design_services_rounded, group: _gSite),
  AdminNav('/admin/features', L('مميزات العمل معنا', 'Why us'), Icons.star_outline_rounded, group: _gSite),
  AdminNav('/admin/projects', L('الأعمال', 'Projects'), Icons.apartment_rounded, group: _gSite),
  AdminNav('/admin/articles', L('المقالات', 'Articles'), Icons.article_outlined, group: _gSite),
  AdminNav('/admin/partners', L('شركاء النجاح', 'Partners'), Icons.handshake_outlined, group: _gSite),
  AdminNav('/admin/testimonials', L('أراء العملاء', 'Testimonials'), Icons.format_quote_rounded, group: _gSite),
  AdminNav('/admin/control', L('مركز التحكم', 'Control centre'), Icons.toggle_on_outlined, group: _gControl),
  AdminNav('/admin/admins', L('المشرفون', 'Admins'), Icons.admin_panel_settings_outlined,
      superOnly: true, group: _gControl),
  AdminNav('/admin/import', L('استيراد المحتوى', 'Import content'), Icons.cloud_download_outlined, group: _gControl),
];

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLang.locale,
      builder: (BuildContext context, Locale _, _) => ListenableBuilder(
        listenable: AdminSession.instance,
        builder: (BuildContext context, _) {
          final AdminSession s = AdminSession.instance;
          return Directionality(
            textDirection: AppLang.direction,
            child: !s.isResolved
                ? const Scaffold(body: Loading(height: double.infinity))
                : _Frame(location: location, session: s, child: child),
          );
        },
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.location, required this.session, required this.child});

  final String location;
  final AdminSession session;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 1000;
    final Widget menu = _Menu(location: location, session: session, closeOnTap: !wide);
    return Scaffold(
      backgroundColor: WebColors.adminBg,
      drawer: wide ? null : Drawer(backgroundColor: WebColors.adminSide, child: menu),
      appBar: AppBar(
        backgroundColor: WebColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        leading: wide
            ? null
            : Builder(
                builder: (BuildContext c) => IconButton(
                  onPressed: () => Scaffold.of(c).openDrawer(),
                  icon: const AppIcon(Icons.menu_rounded),
                ),
              ),
        titleSpacing: wide ? 24 : 0,
        title: Row(
          children: <Widget>[
            Image.asset('assets/web/images/logo.png', height: 34),
            const SizedBox(width: 10),
            Text(const L('لوحة تحكم أسيك', 'ASEC control panel').t,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: AppLang.toggle,
            icon: const AppIcon(Icons.translate_rounded, size: 18),
            label: Text(AppLang.isAr ? 'English' : 'عربي'),
          ),
          if (wide)
            TextButton.icon(
              onPressed: () => openLink(Uri.base.resolve('/').toString()),
              icon: const AppIcon(Icons.public_rounded, size: 18),
              label: Text(const L('عرض الموقع', 'View site').t),
            ),
          PopupMenuButton<String>(
            tooltip: session.user?.email ?? '',
            onSelected: (String v) async {
              if (v == 'out') {
                await AdminSession.instance.signOut();
                if (context.mounted) context.go('/admin/login');
              }
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Text('${session.name}\n${session.user?.email ?? ''}\n'
                    '${session.isSuper ? const L('المشرف الرئيسي', 'Super admin').t : const L('مشرف', 'Admin').t}'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(value: 'out', child: Text(const L('تسجيل الخروج', 'Sign out').t)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: WebColors.navy,
                child: Text(
                  (session.name.isEmpty ? '?' : session.name.characters.first).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: <Widget>[
                SizedBox(width: 260, child: Material(color: WebColors.adminSide, child: menu)),
                Expanded(child: child),
              ],
            )
          : child,
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.location, required this.session, required this.closeOnTap});

  final String location;
  final AdminSession session;
  final bool closeOnTap;

  @override
  Widget build(BuildContext context) {
    final List<AdminNav> items = kAdminNav.where((AdminNav n) => !n.superOnly || session.isSuper).toList();
    final List<Widget> tiles = <Widget>[];
    L? lastGroup;
    for (final AdminNav n in items) {
      if (n.group != null && n.group != lastGroup) {
        tiles.add(Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 6),
          child: Text(n.group!.t,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, fontWeight: FontWeight.w700)),
        ));
        lastGroup = n.group;
      }
      final bool active = n.path == '/admin' ? location == '/admin' : location.startsWith(n.path);
      tiles.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: ListTile(
          dense: true,
          selected: active,
          selectedTileColor: WebColors.red,
          selectedColor: Colors.white,
          iconColor: Colors.white70,
          textColor: Colors.white70,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: AppIcon(n.icon, size: 20),
          title: Text(n.label.t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          onTap: () {
            if (closeOnTap) Navigator.of(context).pop();
            context.go(n.path);
          },
        ),
      ));
    }
    return SafeArea(child: ListView(padding: const EdgeInsets.symmetric(vertical: 12), children: tiles));
  }
}
