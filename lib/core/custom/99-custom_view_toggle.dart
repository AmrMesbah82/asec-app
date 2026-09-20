/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 99-custom_view_toggle.dart
/// Purpose: Declares `ViewMode` and `CustomViewToggle` — the grid / table
///          switch that sits at the right-hand end of every list toolbar.
/// Author: Manger Plus team
/// Created: 3/9/2026
///
/// knowticed_plus splits this across `39-custom_grid_button.dart` and
/// `40-custom_table_button.dart`: two files, two near-identical widgets, and
/// every caller re-deriving which of them is lit. The pair only ever appears
/// together and only ever in one of two states, so here it is ONE widget with
/// one enum — the caller holds a `ViewMode`, not two booleans that can
/// disagree.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/haptic_controller.dart';

/// How a collection is laid out. Persisted per page, not per install: it is a
/// working preference, like a sort order, not a setting.
enum ViewMode {
  /// Cards in a responsive grid. The default on every page that has images or
  /// more than four fields per record.
  grid,

  /// Dense rows. The default where records are compared column by column —
  /// orders, above all.
  table;

  bool get isGrid => this == ViewMode.grid;
  bool get isTable => this == ViewMode.table;

  ViewMode get opposite => isGrid ? ViewMode.table : ViewMode.grid;
}

/// Two 38.sp squares, side by side, the current one filled with primary.
class CustomViewToggle extends StatelessWidget {
  const CustomViewToggle({
    super.key,
    required this.mode,
    required this.onChanged,
    this.spacing,
  });

  final ViewMode mode;
  final ValueChanged<ViewMode> onChanged;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ToggleButton(
          iconPath: AppAssets.grid,
          tooltip: 'Cards',
          isActive: mode.isGrid,
          // Tapping the active half is a no-op, not a toggle. A user who taps
          // "cards" while already in cards means "I want cards", and flipping
          // them to a table reads as the app arguing.
          onTap: () => mode.isGrid ? null : onChanged(ViewMode.grid),
        ),
        SizedBox(width: spacing ?? 8.sp),
        _ToggleButton(
          iconPath: AppAssets.listView,
          tooltip: 'Table',
          isActive: mode.isTable,
          onTap: () => mode.isTable ? null : onChanged(ViewMode.table),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.iconPath,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  final String iconPath;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticController.medium();
          onTap();
        },
        child: Container(
          width: 38.sp,
          height: 38.sp,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.card,
            borderRadius: AppRadius.buttonR,
          ),
          child: CustomSvgImage(
            assetPath: iconPath,
            width: 20.sp,
            height: 20.sp,
            color: isActive ? AppColors.textButton : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
