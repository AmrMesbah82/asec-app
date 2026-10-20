/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: app_connectivity.dart
/// Purpose: Declares `AppConnectivity` and `OfflineConverterView` — losing
///          the internet closes the app and leaves only the "no connection"
///          animation and the offline tools (downloads, unit converter and —
///          for whoever has them — the engineering calculators),
///          on Android, iOS, macOS and Windows. When the internet comes back,
///          the app returns by itself.
/// Author: ASEC team
/// Created: 1/10/2026
///
/// HOW IT KNOWS
/// ------------
/// A tiny request to Google's "generate_204" address every 4 seconds and
/// whenever the app comes back to the foreground. Being on Wi-Fi is not
/// enough — a router with no internet, or a hotel login page, counts as
/// offline. Two failures in a row are needed before the app closes, so one
/// slow request does not flash the offline screen; one success brings the
/// app back at once.
///
/// The web is never switched to the offline screen: a browser blocks that
/// request (CORS), so it would look offline all the time.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/tools/t1_unit_converter/presentation/ui/pages/unit_converter_page.dart';
import 'package:asec/features/tools/t2_engineering_calc/data/calc_access.dart';
import 'package:asec/features/tools/t2_engineering_calc/presentation/ui/pages/engineering_calc_page.dart';
import 'package:asec/features/video/v1_videos/data/download/video_downloads.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/pages/downloads_page.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

abstract final class AppConnectivity {
  static bool get enforced => !kIsWeb;

  /// True while the device has no working internet.
  static final RxBool offline = false.obs;

  /// True while a check is running (the offline screen's button spinner).
  static final RxBool checking = false.obs;

  static final Uri _probe = Uri.parse('https://www.gstatic.com/generate_204');
  static Timer? _timer;
  static _ResumeObserver? _observer;
  static int _failures = 0;

  static void start() {
    if (!enforced) return;
    check();
    _timer ??= Timer.periodic(const Duration(seconds: 4), (_) => check());
    if (_observer == null) {
      _observer = _ResumeObserver();
      WidgetsBinding.instance.addObserver(_observer!);
    }
  }

  static Future<void> check() async {
    if (!enforced || checking.value) return;
    checking.value = true;
    bool ok;
    try {
      final http.Response r =
          await http.head(_probe).timeout(const Duration(seconds: 5));
      ok = r.statusCode == 204 || r.statusCode == 200;
    } catch (_) {
      ok = false;
    }
    checking.value = false;
    if (ok) {
      _failures = 0;
      if (offline.value) offline.value = false;
    } else {
      _failures++;
      if (_failures >= 2 && !offline.value) offline.value = true;
    }
  }

  /// Wraps the app. While offline the app is HIDDEN (Offstage, animations
  /// stopped, any video paused by the player) and the converter is drawn on
  /// top of it.
  ///
  /// Hidden, not removed: GetX keeps the app's navigator as `Get.context`,
  /// and the app's own widgets (customButton reads `Get.isDarkMode`) look
  /// the theme up through it. Removing the app tore that context down and
  /// every customButton on the offline screen threw.
  static Widget gate(Widget child) {
    if (!enforced) return child;
    return Obx(() {
      final bool off = offline.value;
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Offstage(
            offstage: off,
            child: TickerMode(enabled: !off, child: child),
          ),
          if (off) const OfflineConverterView(),
        ],
      );
    });
  }
}

class _ResumeObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) AppConnectivity.check();
  }
}

/// The whole app while offline: a banner and the unit converter.
///
/// It has its own Navigator because it replaces the app's — the custom
/// dropdowns open in an Overlay, which a Navigator provides.
class OfflineConverterView extends StatelessWidget {
  const OfflineConverterView({super.key});

  @override
  Widget build(BuildContext context) {
    // ITS OWN HERO SCOPE. This view sits in GetMaterialApp's `builder`,
    // beside the app's Navigator, so without this it picks up the app's
    // HeroController too. Two Navigators on one HeroController throws, and
    // once this view goes away the app's Navigator is left with a broken
    // controller: the next push fails half-way and locks the Navigator
    // ('!_debugLocked' on every tap after that).
    return HeroControllerScope.none(
      child: Navigator(
        onGenerateRoute: (RouteSettings settings) => MaterialPageRoute<void>(
          builder: (BuildContext context) => const _OfflineScreen(),
        ),
      ),
    );
  }
}

/// Offline, what works without internet: downloaded lessons (if any), the
/// unit converter, and the engineering calculators for whoever has them
/// (admins, and members the admin unlocked — CalcAccess). One tool alone is
/// shown without the switcher.
class _OfflineScreen extends StatefulWidget {
  const _OfflineScreen();

  @override
  State<_OfflineScreen> createState() => _OfflineScreenState();
}

enum _OfflineTool { downloads, converter, calculators }

class _OfflineScreenState extends State<_OfflineScreen> {
  _OfflineTool? _picked;

  @override
  void initState() {
    super.initState();
    VideoDownloads.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.statusPending.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.statusPending.withOpacity(0.4)),
              ),
              child: Row(
                children: <Widget>[
                  // The app's "no connection" animation (Wi-Fi being cut).
                  Lottie.asset(
                    AppAssets.lottieNoInternet,
                    width: 64,
                    height: 58,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          FormatHelper.capitalize(s.offlineTitle),
                          style: StyleText.fontSize15Weight600.copyWith(color: AppColors.text),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          FormatHelper.capitalize(s.offlineBody),
                          style: StyleText.fontSize12Weight400
                              .copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Obx(() => AppConnectivity.checking.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : customButton(
                          title: s.offlineRetry,
                          function: AppConnectivity.check,
                          wrapContent: true,
                        )),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final List<(_OfflineTool, String)> tools = <(_OfflineTool, String)>[
                  if (VideoDownloads.items.isNotEmpty)
                    (_OfflineTool.downloads, s.downloads),
                  (_OfflineTool.converter, s.unitConverter),
                  if (CalcAccess.allowed)
                    (_OfflineTool.calculators, s.engineeringCalc),
                ];
                final _OfflineTool shown = tools.any(
                  ((_OfflineTool, String) t) => t.$1 == _picked,
                )
                    ? _picked!
                    : tools.first.$1;
                final Widget page = switch (shown) {
                  _OfflineTool.downloads => const DownloadsPage(),
                  _OfflineTool.converter => const UnitConverterPage(),
                  _OfflineTool.calculators => const EngineeringCalcPage(),
                };
                if (tools.length == 1) return page;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: <Widget>[
                          for (final (_OfflineTool tool, String label) in tools)
                            customButton(
                              title: label,
                              function: () => setState(() => _picked = tool),
                              wrapContent: true,
                              color: shown == tool
                                  ? AppColors.primary
                                  : AppColors.card,
                              textColor: shown == tool
                                  ? Colors.white
                                  : AppColors.text,
                            ),
                        ],
                      ),
                    ),
                    // Each tool keeps what was typed while switching.
                    Expanded(
                      child: IndexedStack(
                        index: tools.indexWhere(
                          ((_OfflineTool, String) t) => t.$1 == shown,
                        ),
                        children: <Widget>[
                          for (final (_OfflineTool tool, String _) in tools)
                            switch (tool) {
                              _OfflineTool.downloads => const DownloadsPage(),
                              _OfflineTool.converter => const UnitConverterPage(),
                              _OfflineTool.calculators => const EngineeringCalcPage(),
                            },
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
