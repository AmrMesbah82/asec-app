/// Every URL of the site and the panel.
///
/// Public:   /  /about  /services  /services/:slug  /projects  /projects/:id
///           /articles  /articles/:id  /contact  /requests  /request-service
///           /request-job  /privacy
/// Panel:    /admin/login  /admin  /admin/…
///
/// The old WordPress addresses (/من-نحن/, /أعمالنا/, …) redirect to the new
/// ones, so the site can later take over the root domain without breaking
/// links people saved or Google indexed.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:asec/features/web/admin/admin_session.dart';
import 'package:asec/features/web/admin/admin_shell.dart';
import 'package:asec/features/web/admin/configs.dart';
import 'package:asec/features/web/admin/pages/admins_page.dart';
import 'package:asec/features/web/admin/pages/collection_page.dart';
import 'package:asec/features/web/admin/pages/control_page.dart';
import 'package:asec/features/web/admin/pages/dashboard_page.dart';
import 'package:asec/features/web/admin/pages/import_page.dart';
import 'package:asec/features/web/admin/pages/inbox_page.dart';
import 'package:asec/features/web/admin/pages/login_page.dart';
import 'package:asec/features/web/admin/pages/site_settings_page.dart';
import 'package:asec/features/web/site/pages/articles_pages.dart';
import 'package:asec/features/web/site/pages/forms_pages.dart';
import 'package:asec/features/web/site/pages/home_page.dart';
import 'package:asec/features/web/site/pages/inner_pages.dart';
import 'package:asec/features/web/site/site_shell.dart';

const Map<String, String> _legacy = <String, String>{
  'من-نحن': '/about',
  'خدماتنا': '/services',
  'خدمتنا': '/services',
  'تصميم-متكامل': '/services/integrated-design',
  'لوحات-تنفيذية': '/services/shop-drawings',
  'اشراف-على-التنفيذ': '/services/supervision',
  'المقالات': '/articles',
  'أعمالنا': '/projects',
  'أعمالي': '/projects',
  'تواصل-معنا': '/contact',
  'تقديم-طلب': '/requests',
  'طلب-خدمة': '/request-service',
  'طلب-وظيفة': '/request-job',
  'سياسة-الخصوصية': '/privacy',
};

/// Page change: the new page fades in while rising a few pixels.
Page<void> _fade(GoRouterState s, Widget child) => CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, Animation<double> a, _, Widget c) {
        final Animation<double> e = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: e,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(e),
            child: c,
          ),
        );
      },
    );

GoRoute _page(String path, Widget Function(GoRouterState s) build) =>
    GoRoute(path: path, pageBuilder: (BuildContext c, GoRouterState s) => _fade(s, build(s)));

GoRoute _admin(String path, Widget Function(GoRouterState s) build) =>
    GoRoute(path: path, pageBuilder: (BuildContext c, GoRouterState s) => NoTransitionPage<void>(key: s.pageKey, child: build(s)));

const Set<String> _superOnly = <String>{'/admin/admins'};

final GoRouter appRouter = GoRouter(
  refreshListenable: AdminSession.instance,
  redirect: (BuildContext context, GoRouterState state) {
    final String path = state.uri.path;

    // Old WordPress URLs.
    String decoded = path;
    try {
      decoded = Uri.decodeComponent(path);
    } catch (_) {}
    decoded = decoded.replaceAll(RegExp(r'^/+|/+$'), '');
    final String? legacy = _legacy[decoded];
    if (legacy != null) return legacy;

    if (!path.startsWith('/admin')) return null;
    final AdminSession s = AdminSession.instance;
    if (!s.isResolved) return null; // the shell shows a spinner meanwhile
    final bool atLogin = path == '/admin/login';
    if (!s.isStaff) return atLogin ? null : '/admin/login';
    if (atLogin) return '/admin';
    if (_superOnly.contains(path) && !s.isSuper) return '/admin';
    // Website → Content / Inbox / Settings.
    final AdminNav? nav = AdminNav.of(path);
    if (nav != null && !nav.allowedFor(s)) return '/admin';
    return null;
  },
  errorBuilder: (BuildContext c, GoRouterState s) => SiteShell(location: s.uri.path, child: const NotFoundPage()),
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext c, GoRouterState s, Widget child) => SiteShell(location: s.uri.path, child: child),
      routes: <RouteBase>[
        _page('/', (_) => const HomePage()),
        _page('/about', (_) => const AboutPage()),
        _page('/services', (_) => const ServicesPage()),
        _page('/services/:slug', (GoRouterState s) => ServiceDetailPage(slug: s.pathParameters['slug'] ?? '')),
        _page('/projects', (_) => const ProjectsPage()),
        _page('/projects/:id', (GoRouterState s) => ProjectDetailPage(id: s.pathParameters['id'] ?? '')),
        _page('/articles', (_) => const ArticlesPage()),
        _page('/articles/:id', (GoRouterState s) => ArticleDetailPage(id: s.pathParameters['id'] ?? '')),
        _page('/contact', (_) => const ContactPage()),
        // "Apply" is the service request only; old links land on it too.
        _page('/requests', (_) => const ServiceRequestPage()),
        _page('/request-service', (_) => const ServiceRequestPage()),
        _page('/request-job', (_) => const ServiceRequestPage()),
        _page('/privacy', (_) => const PrivacyPage()),
      ],
    ),
    GoRoute(path: '/admin/login', builder: (BuildContext c, GoRouterState s) => const AdminLoginPage()),
    ShellRoute(
      builder: (BuildContext c, GoRouterState s, Widget child) => AdminShell(location: s.uri.path, child: child),
      routes: <RouteBase>[
        _admin('/admin', (_) => const DashboardPage()),
        _admin('/admin/inbox',
            (GoRouterState s) => InboxPage(initialTab: int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0)),
        _admin('/admin/site', (_) => const SiteSettingsPage()),
        _admin('/admin/services', (_) => CollectionPage(key: const ValueKey<String>('services'), config: servicesConfig)),
        _admin('/admin/features', (_) => CollectionPage(key: const ValueKey<String>('features'), config: featuresConfig)),
        _admin('/admin/projects', (_) => CollectionPage(key: const ValueKey<String>('projects'), config: projectsConfig)),
        _admin('/admin/articles', (_) => CollectionPage(key: const ValueKey<String>('articles'), config: articlesConfig)),
        _admin('/admin/partners', (_) => CollectionPage(key: const ValueKey<String>('partners'), config: partnersConfig)),
        _admin('/admin/testimonials',
            (_) => CollectionPage(key: const ValueKey<String>('testimonials'), config: testimonialsConfig)),
        _admin('/admin/control', (_) => const ControlPage()),
        _admin('/admin/admins', (_) => const AdminsPage()),
        _admin('/admin/import', (_) => const ImportPage()),
      ],
    ),
  ],
);
