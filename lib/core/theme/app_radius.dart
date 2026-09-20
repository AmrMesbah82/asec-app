/// Module: core / theme
///
///*************************** FILE INFO ****************************///
/// File Name: app_radius.dart
/// Purpose: Declares `AppRadius` — the app's THREE corner radii.
/// Author: Manger Plus team
/// Created: 19/9/2026
///
/// THE RULE (19/9/2026)
/// --------------------
/// Every rounded corner in the app is one of three numbers, on every device:
///
///   * [container] — 4. Cards, panels, surfaces, dialogs, sheets, tiles,
///     banners, images, avatarless boxes: anything that HOLDS something.
///   * [button] — 8. Buttons, the search box, chips, pills, tabs, toggles,
///     segments: anything you PRESS.
///   * [field] — 4. Text fields, dropdowns and their menus: anything you TYPE
///     or CHOOSE in. The same number as a container on purpose — a field is a
///     box, and the pressables are the only thing that stands out.
///
/// Before this the app carried fourteen different radii (4, 6, 8, 10, 12, 14,
/// 16, 18, 20, 22, 24 …), often two of them in one row, so nothing looked
/// deliberate. Pass one of these, never a number.
///
/// SHAPES ARE NOT RADII
/// --------------------
/// A partial radius is a SHAPE, not a corner treatment — the curve under a
/// gradient header, the top of a bottom sheet, a chat bubble's tail corner,
/// a chart's rounded bar. Those keep their own numbers; this file is about
/// the corners of boxes.

import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract final class AppRadius {
  const AppRadius._();

  /// Cards, panels, dialogs, tiles — anything that holds something.
  static const double container = 4;

  /// Buttons, search, chips, pills, tabs, toggles — anything you press.
  static const double button = 8;

  /// Text fields, dropdowns, menus — anything you type or choose in.
  static const double field = 4;

  /// Responsive `BorderRadius` for each. Scaled with `.r`, so a corner grows
  /// with the rest of the UI on a tablet exactly as padding and type do.
  static BorderRadius get containerR => BorderRadius.circular(container.r);
  static BorderRadius get buttonR => BorderRadius.circular(button.r);
  static BorderRadius get fieldR => BorderRadius.circular(field.r);

  /// The same three as a single [Radius], for `BorderRadius.only` and friends.
  static Radius get containerRadius => Radius.circular(container.r);
  static Radius get buttonRadius => Radius.circular(button.r);
  static Radius get fieldRadius => Radius.circular(field.r);
}
