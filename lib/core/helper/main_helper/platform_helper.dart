/// Module: core/helper
///
///*************************** FILE INFO ****************************///
/// File Name: platform_helper.dart
/// Purpose: Declares `DeviceKind` and `PlatformHelper` — which kind of device
///          this build is running on, and which roles may use it.
/// Author: Manger Plus team
/// Created: 18/9/2026
///
/// THE RULE
/// --------
///   * Students and parents  -> phone or tablet ONLY.
///   * Teachers and admins   -> desktop OR tablet (never a phone).
///
/// A tablet is a phone-or-tablet build whose SHORTEST side is at least
/// [tabletBreakpoint], so an iPad counts in either orientation and a phone in
/// landscape never does.
///
/// WHAT DECIDES (19/9/2026)
/// -----------------------
/// A real PHONE OR TABLET is decided by the platform: an iPad in landscape is
/// 1366pt wide and is still a tablet, so Android and iOS are always
/// [DeviceKind.mobile] and the shortest side then says phone or tablet.
///
/// Everywhere else — macOS, Windows, Linux and the web — the WINDOW decides,
/// because there is no device to ask and a 500pt window is a phone-shaped
/// space whatever machine it is on:
///
///   * `>= desktopLayoutWidth` (1100) -> desktop,
///   * `>= tabletBreakpoint`   (600)  -> tablet,
///   * below that                     -> phone.
///
/// That is what makes the console resizable into its own phone and tablet
/// designs: drag the macOS window narrow and the app scales, lays out and
/// gates itself exactly as it would on the device that size.
///
/// The rule itself — which role may use which kind — lives on `UserRole`
/// (`allowedOn`). This file only answers "what am I running on".

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/constants/app_keys.dart';

enum DeviceKind {
  /// Phone or tablet.
  mobile,

  /// macOS / Windows / Linux, or a wide browser window.
  desktop,
}

abstract final class PlatformHelper {
  const PlatformHelper._();

  /// Kept as the old name for [desktopLayoutWidth]; both are 1100.
  static const double webDesktopWidth = desktopLayoutWidth;

  /// Width from which the MOBILE apps switch to their tablet layout
  /// (two-column grids, wider cards). Same figure as `context.isTablet`.
  static const double tabletBreakpoint = 600;

  static bool get isWeb => kIsWeb;

  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static bool get isDesktopPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  /// What this build is for the space it has — see the header.
  static DeviceKind kindOf(BuildContext context) =>
      kindForWidth(MediaQuery.sizeOf(context).width);

  /// Same answer from a raw width, for code above `MediaQuery` (main.dart).
  static DeviceKind kindForWidth(double width) {
    final DeviceKind? forced = debugOverride;
    if (forced != null) return forced;

    // A real phone or tablet is mobile at every width.
    if (isMobilePlatform) return DeviceKind.mobile;

    // A desktop or a browser is whatever its WINDOW is. Dragging a macOS
    // window under 1100 is how the console's tablet design is tested, and
    // under 600 is how the phone design is — including the scale, which
    // main.dart takes from this same answer.
    return width >= desktopLayoutWidth ? DeviceKind.desktop : DeviceKind.mobile;
  }

  /// True on an iPad / Android tablet (or a narrow-but-not-phone browser).
  ///
  /// This is a question about the DEVICE. For "should this screen use its
  /// tablet layout", ask [isTabletLayout] — a desktop window dragged down to
  /// iPad width is not a tablet, but it has a tablet's room.
  static bool isTablet(BuildContext context) {
    if (kindOf(context) != DeviceKind.mobile) return false;
    final Size size = MediaQuery.sizeOf(context);
    // A real tablet is measured by its SHORTEST side, so an iPad is a tablet
    // in both orientations and a phone in landscape is not. A window is
    // measured by its WIDTH — its height is the screen's, not the design's.
    final double measure =
        isMobilePlatform ? size.shortestSide : size.width;
    return measure >= tabletBreakpoint;
  }

  /// Width from which a layout may spread out like a desktop: the full rail,
  /// a seven-column table, charts side by side. The console's own "am I
  /// cramped" test is this number, so every widget that asks the question
  /// gets the same answer.
  static const double desktopLayoutWidth = 1100;

  /// TRUE WHEN THE UI SHOULD LAY ITSELF OUT AS A TABLET.
  ///
  /// Two ways to be one: a real tablet, or any window — macOS included —
  /// that is narrower than [desktopLayoutWidth]. The second case is the one
  /// that matters day to day: the console is developed on a Mac in a
  /// half-width window, and that window has exactly an iPad's room, so it
  /// must get the iPad's layout rather than a desktop layout squeezed.
  ///
  /// Pass [width] from a `LayoutBuilder` when the widget owns only part of
  /// the window — a table inside a narrow panel is cramped even when the
  /// window is not.
  static bool isTabletLayout(BuildContext context, {double? width}) {
    if (isTablet(context)) return true;
    final double w = width ?? MediaQuery.sizeOf(context).width;
    return w.isFinite && w < desktopLayoutWidth;
  }

  /// Where the admin / teacher console may run: a desktop, or a tablet.
  static bool canRunConsole(BuildContext context) =>
      kindOf(context) == DeviceKind.desktop || isTablet(context);

  // ── Debug override ───────────────────────────────────────────────────────
  //
  // Testing the student app normally needs a phone. In DEBUG builds only, the
  // "wrong device" screen offers a button that pretends this machine is the
  // other kind, so the whole system can be clicked through on one Mac.
  // Release builds ignore the stored value completely.

  static DeviceKind? get debugOverride {
    if (!kDebugMode) return null;
    try {
      final String? value = GetStorage().read(AppKeys.debugDeviceOverride);
      if (value == DeviceKind.mobile.name) return DeviceKind.mobile;
      if (value == DeviceKind.desktop.name) return DeviceKind.desktop;
    } catch (_) {}
    return null;
  }

  static void setDebugOverride(DeviceKind? kind) {
    if (!kDebugMode) return;
    try {
      if (kind == null) {
        GetStorage().remove(AppKeys.debugDeviceOverride);
      } else {
        GetStorage().write(AppKeys.debugDeviceOverride, kind.name);
      }
    } catch (_) {}
  }
}
