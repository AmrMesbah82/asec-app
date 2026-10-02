/// Module: web
///
///*************************** FILE INFO ****************************///
/// File Name: web_main.dart
/// Purpose: SECOND ENTRY POINT — the public asecbim website (and its /admin
///          panel) as a stand-alone Flutter web app. The ASEC app itself
///          starts from lib/main.dart and shows the same panel in its
///          "Website" drawer tab (features/web/web_control_page.dart).
///
/// Run / build it with:
///   flutter run   -d chrome -t lib/features/web/web_main.dart
///   ./tool/build_site.sh          (builds with web_site/ as the host page)
///
/// Same Firebase project as the ASEC app (asec-a811b). Served on a
/// subdomain of asecbim.com (Firebase Hosting); the WordPress site on the
/// root domain is not touched. See SETUP.md §3c.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:asec/features/web/admin/admin_session.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/router.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // /projects/p01, not /#/projects/p01
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLang.initForWebsite(); // ?lang=en, else the visitor's last choice, else Arabic
  SiteSettings.instance; // start listening to site_settings/main
  AdminSession.instance; // and to the auth state
  runApp(const AsecWebApp());
}

class AsecWebApp extends StatelessWidget {
  const AsecWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLang.locale,
      builder: (BuildContext context, Locale locale, _) => MaterialApp.router(
        title: const L('أسيك للاستشارات الهندسية | ASEC', 'ASEC Engineering Consultants').t,
        debugShowCheckedModeBanner: false,
        theme: WebTheme.light,
        routerConfig: appRouter,
        locale: locale,
        supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
