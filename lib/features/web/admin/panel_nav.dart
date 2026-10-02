/// Module: web / admin
///
///*************************** FILE INFO ****************************///
/// File Name: panel_nav.dart
/// Purpose: ONE panel, TWO hosts. The website control panel runs
///          * inside the ASEC app, as the "Website" tab of the admin drawer
///            (web_control_page.dart) — no URLs, a tab switch;
///          * stand-alone on the web at /admin (core/router.dart) — go_router.
///          Panel pages never call `context.go` directly: they call
///          `panelGo`, which asks whichever host they are in.
/// Author: ASEC team
/// Created: 26/9/2026
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:asec/features/web/admin/configs.dart';
import 'package:asec/features/web/admin/pages/admins_page.dart';
import 'package:asec/features/web/admin/pages/collection_page.dart';
import 'package:asec/features/web/admin/pages/control_page.dart';
import 'package:asec/features/web/admin/pages/dashboard_page.dart';
import 'package:asec/features/web/admin/pages/import_page.dart';
import 'package:asec/features/web/admin/pages/inbox_page.dart';
import 'package:asec/features/web/admin/pages/site_settings_page.dart';

/// Where the public site is served. "View site" opens it.
/// Change to https://app.asecbim.com once the custom domain is live.
const String kWebsiteUrl = 'https://asecbim-web.web.app';

/// Put above the panel by the in-app host; absent on the stand-alone web.
class WebPanelScope extends InheritedWidget {
  const WebPanelScope({super.key, required this.go, required super.child});

  /// Takes a panel path, e.g. `/admin/projects` or `/admin/inbox?tab=1`.
  final ValueChanged<String> go;

  @override
  bool updateShouldNotify(WebPanelScope oldWidget) => go != oldWidget.go;
}

/// Moves the panel to [path], in whichever host it is running.
void panelGo(BuildContext context, String path) {
  final WebPanelScope? scope = context.getInheritedWidgetOfExactType<WebPanelScope>();
  if (scope != null) {
    scope.go(path);
    return;
  }
  GoRouter.of(context).go(path);
}

/// The page for a panel path — the same table for both hosts.
Widget panelPageFor(Uri uri) {
  switch (uri.path) {
    case '/admin/inbox':
      return InboxPage(initialTab: int.tryParse(uri.queryParameters['tab'] ?? '') ?? 0);
    case '/admin/site':
      return const SiteSettingsPage();
    case '/admin/services':
      return CollectionPage(key: const ValueKey<String>('services'), config: servicesConfig);
    case '/admin/features':
      return CollectionPage(key: const ValueKey<String>('features'), config: featuresConfig);
    case '/admin/projects':
      return CollectionPage(key: const ValueKey<String>('projects'), config: projectsConfig);
    case '/admin/articles':
      return CollectionPage(key: const ValueKey<String>('articles'), config: articlesConfig);
    case '/admin/partners':
      return CollectionPage(key: const ValueKey<String>('partners'), config: partnersConfig);
    case '/admin/testimonials':
      return CollectionPage(key: const ValueKey<String>('testimonials'), config: testimonialsConfig);
    case '/admin/control':
      return const ControlPage();
    case '/admin/admins':
      return const AdminsPage();
    case '/admin/import':
      return const ImportPage();
    default:
      return const DashboardPage();
  }
}
