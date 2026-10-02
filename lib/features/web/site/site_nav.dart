/// Module: web / site
///
///*************************** FILE INFO ****************************///
/// File Name: site_nav.dart
/// Purpose: ONE site, TWO hosts — the same idea as admin/panel_nav.dart.
///          * On the web (web_main.dart) the site has real URLs: go_router.
///          * Inside the ASEC app, "View site" opens a PREVIEW of the site
///            (site_preview_page.dart) — no URLs; a link swaps the page.
///          Site widgets never call `context.go` directly: they call
///          `siteGo`, which asks whichever host they are in.
/// Author: ASEC team
/// Created: 26/9/2026
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:asec/features/web/site/pages/articles_pages.dart';
import 'package:asec/features/web/site/pages/forms_pages.dart';
import 'package:asec/features/web/site/pages/home_page.dart';
import 'package:asec/features/web/site/pages/inner_pages.dart';

/// Put above the site by the in-app preview; absent on the web.
class SitePreviewScope extends InheritedWidget {
  const SitePreviewScope({super.key, required this.go, required super.child});

  /// Takes a site path, e.g. `/projects/p01`.
  final ValueChanged<String> go;

  @override
  bool updateShouldNotify(SitePreviewScope oldWidget) => go != oldWidget.go;
}

/// Moves the site to [path], in whichever host it is running.
void siteGo(BuildContext context, String path) {
  final SitePreviewScope? scope = context.getInheritedWidgetOfExactType<SitePreviewScope>();
  if (scope != null) {
    scope.go(path);
    return;
  }
  GoRouter.of(context).go(path);
}

/// The page for a site path — the same pages core/router.dart serves.
Widget sitePageFor(Uri uri) {
  final List<String> seg = uri.pathSegments.where((String s) => s.isNotEmpty).toList();
  if (seg.isEmpty) return const HomePage();
  final String id = seg.length > 1 ? seg[1] : '';
  switch (seg.first) {
    case 'about':
      return const AboutPage();
    case 'services':
      return id.isEmpty ? const ServicesPage() : ServiceDetailPage(key: ValueKey<String>(id), slug: id);
    case 'projects':
      return id.isEmpty ? const ProjectsPage() : ProjectDetailPage(key: ValueKey<String>(id), id: id);
    case 'articles':
      return id.isEmpty ? const ArticlesPage() : ArticleDetailPage(key: ValueKey<String>(id), id: id);
    case 'contact':
      return const ContactPage();
    case 'requests':
      return const RequestsPage();
    case 'request-service':
      return const ServiceRequestPage();
    case 'request-job':
      return const JobRequestPage();
    case 'privacy':
      return const PrivacyPage();
    default:
      return const NotFoundPage();
  }
}
