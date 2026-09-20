/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 69-cross_axis_count_helper.dart
/// Purpose: Declares `CrossAxisCountHelper` — how many cards fit in a row, and
///          the one grid delegate every card grid in the app is built on.
/// Author: Manger Plus team
/// Created: 3/9/2026
/// Updated: 19/9/2026 - Added `getCrossAxisCountForDefaultTablet2` (the
///          knowticed_plus helper, made web-safe) and `gridDelegate`, so a
///          card grid never hand-rolls its own column maths again.
///
/// Ported from knowticed_plus with one deliberate change: the original branches
/// on `Platform.isMacOS || isWindows || isLinux`, which THROWS on web because
/// `dart:io` has no Platform there. Wash ships a web build of the console, so
/// this reads the platform through [PlatformHelper] instead, which answers the
/// same question on every target.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/helper/main_helper/platform_helper.dart';

abstract class CrossAxisCountHelper {

  /// The breakpoint knowticed's tablet grids key off — narrower than [tablet],
  /// because at 768 a record card still reads at two columns.
  static const double tabletWide = 768;

  /// THE app's card count. Ported verbatim (bar the `dart:io` fix) from
  /// knowticed_plus, and the one every card grid should ask — a table drawn as
  /// cards on a tablet, the dashboard tiles, the sections and content grids.
  ///
  /// It keys off BOTH width and orientation, because an iPad turned sideways
  /// has the width of a laptop and none of its pointer precision: a phone-sized
  /// column count there wastes half the glass, and a laptop count there gives
  /// cards nobody can read.
  static int getCrossAxisCountForDefaultTablet2(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double width = size.width;
    final bool isLandscape = width > size.height;

    // ==================== DESKTOP PLATFORMS ====================
    if (PlatformHelper.isDesktopPlatform) {
      if (width >= desktop) return isLandscape ? 5 : 4;
      if (width >= laptop) return isLandscape ? 4 : 3;
      if (width >= tabletWide) return isLandscape ? 3 : 2;
      return 1;
    }

    // ==================== LARGE / TV (>= 1920) ====================
    if (width >= desktop) return isLandscape ? 6 : 5;

    // ==================== LAPTOP (1366 - 1919) ====================
    if (width >= laptop) return isLandscape ? 5 : 4;

    // ==================== TABLET (768 - 1365) ====================
    if (width >= tabletWide) return isLandscape ? 3 : 2;

    // ==================== MOBILE (< 768) ====================
    return isLandscape ? 2 : 1;
  }

  /// The delegate every card grid in the app uses.
  ///
  /// One place decides the count, the gaps and the cell height, so two grids
  /// on two pages can never drift apart. Spacing is responsive
  /// (`.w` / `.h`), and [mainAxisExtent] is given in DESIGN pixels — it is
  /// scaled here, so callers pass the number they drew, not the number times
  /// the current scale factor.
  ///
  /// [minCellWidth] guards the case the raw count cannot see: a grid inside a
  /// half-width panel is handed the WINDOW's column count by
  /// [getCrossAxisCountForDefaultTablet2], which would slice its own box into
  /// slivers. Pass the width the card stops working at and the count is
  /// brought down to what actually fits; pass the box it was measured in as
  /// [availableWidth] when the grid is inside a `LayoutBuilder`.
  static SliverGridDelegateWithFixedCrossAxisCount gridDelegate(
    BuildContext context, {
    double? mainAxisExtent,
    double spacing = 16,
    double? minCellWidth,
    double? availableWidth,
  }) {
    int count = getCrossAxisCountForDefaultTablet2(context);

    if (minCellWidth != null) {
      final double box = availableWidth ?? MediaQuery.sizeOf(context).width;
      count = count.clamp(
        1,
        forWidth(box, minCellWidth: minCellWidth.w, spacing: spacing.w, max: 8),
      );
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: count,
      crossAxisSpacing: spacing.w,
      mainAxisSpacing: spacing.h,
      mainAxisExtent: mainAxisExtent == null ? null : mainAxisExtent.h,
    );
  }

  /// Breakpoints, in logical pixels. Named so a change here reads as a design
  /// decision rather than a magic number edit.
  static const double phone = 600;
  static const double tablet = 900;
  static const double laptop = 1366;
  static const double desktop = 1920;

  /// Columns for a standard record card (~260–320 wide at every step).
  static int forCards(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    if (width >= desktop) return 5;
    if (width >= laptop) return 4;
    if (width >= tablet) return 3;
    if (width >= phone) return 2;
    return 1;
  }

  /// Columns for a compact tile — the stat row on the overview page, where the
  /// content is a number and a word rather than a paragraph.
  static int forTiles(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    if (width >= desktop) return 6;
    if (width >= laptop) return 4;
    if (width >= tablet) return 3;
    if (width >= phone) return 2;
    return 1;
  }

  /// Columns that keep every cell at least [minCellWidth] wide inside a box of
  /// [availableWidth]. Prefer this inside a `LayoutBuilder`: it measures the
  /// space the grid actually got, not the whole window, so a grid in a
  /// half-width panel does not lay out as if it owned the screen.
  static int forWidth(
    double availableWidth, {
    double minCellWidth = 280,
    double spacing = 16,
    int max = 6,
  }) {
    if (availableWidth <= 0) return 1;
    final int fits =
        ((availableWidth + spacing) / (minCellWidth + spacing)).floor();
    return fits.clamp(1, max);
  }
}
