/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 61-custom_color_picker.dart
/// Purpose: Declares `CustomColorPickerField` and `CustomColorPickerSection`.
/// Author: Manger Plus team
/// Created: 4/9/2026 — ported from knowticed_plus.
///
/// Colour selection built on the flex_color_picker package, styled to sit
/// alongside CustomTextField / CustomDropdown: filled background, no border,
/// hint text while unset. Purely presentational — it takes the current colours
/// and reports changes, so it has no controller dependency and can be dropped
/// into the console settings and the phone settings unchanged.

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// A single colour field that opens the picker dialog on tap.
///
/// While [color] is null the field shows [label] as a hint, exactly like an
/// empty CustomTextField. Once a colour is picked it shows a swatch plus the
/// hex code.
class CustomColorPickerField extends StatelessWidget {
  const CustomColorPickerField({
    super.key,
    required this.label,
    required this.color,
    required this.onColorSelected,
    this.dialogTitle,
    this.enabled = true,
  });

  /// Hint shown while no colour is selected, e.g. "Primary colour".
  final String label;

  /// Currently selected colour, or null when nothing has been chosen.
  final Color? color;

  /// Called with the newly picked colour. NOT called if the user discards.
  final ValueChanged<Color> onColorSelected;

  /// Optional dialog heading; defaults to [label].
  final String? dialogTitle;

  final bool enabled;

  static String hexOf(Color color) =>
      '#${(color.value & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';

  /// Owns the dialog rather than calling `showColorPickerDialog`.
  ///
  /// That helper draws its own chrome and gives no way to replace it: a
  /// copy / paste / ✓ / ✕ icon row across the top and an `0xFFRRGGBB` chip at
  /// the bottom, none of which belong in this app. Building an AlertDialog
  /// around the bare `ColorPicker` is the only way to put the app's own
  /// `customButton` in their place.
  ///
  /// It also avoids a real bug in that flow: `showColorPickerDialog` returns
  /// the SEED colour when the user cancels, which is indistinguishable from
  /// deliberately re-picking the same colour. Here Save and Discard are
  /// separate answers, and Discard reports nothing, ever.
  Future<void> _pick(BuildContext context) async {
    if (!enabled) return;

    final Color start = color ?? AppColors.primary;

    // The working value. `ColorPicker` reports every change through
    // `onColorChanged`; nothing reaches the caller until Save.
    Color working = start;

    final bool? saved = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.totalBlack.withOpacity(0.4),
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kAppRadius.r),
          ),
          title: Text(
            FormatHelper.capitalize(dialogTitle ?? label),
            style:
                StyleText.fontSize16Weight500.copyWith(color: AppColors.text),
          ),
          // The button row lives in the CONTENT, not in `actions:`.
          //
          // `AlertDialog.actions` renders its children in an OverflowBar, which
          // is not a Flex: it lays each child out at its intrinsic width and
          // ignores `spaceBetween` entirely, so the two buttons stay bunched at
          // one end. As a plain Row inside the content it behaves — Discard
          // pins to the leading edge, Save to the trailing one — and the picker
          // above keeps its own scroll view, so the buttons stay put instead of
          // scrolling away with a tall wheel.
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: SingleChildScrollView(
                  child: ColorPicker(
                    color: working,
                    onColorChanged: (Color value) => working = value,
                    width: 40.sp,
                    height: 36.sp,
                    spacing: 4.w,
                    runSpacing: 4.h,
                    borderRadius: 4,
                    wheelDiameter: 190.sp,
                    enableShadesSelection: true,
                    showColorCode: false,
                    copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                      copyButton: false,
                      pasteButton: false,
                      longPressMenu: false,
                    ),
                    pickersEnabled: const <ColorPickerType, bool>{
                      ColorPickerType.both: false,
                      ColorPickerType.primary: true,
                      ColorPickerType.accent: false,
                      ColorPickerType.wheel: true,
                    },
                    // All three off — the dialog supplies its own actions.
                    actionButtons: const ColorPickerActionButtons(
                      okButton: false,
                      closeButton: false,
                      dialogActionButtons: false,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.sp),
              // Direction-aware, like every other row in the app: in Arabic it
              // mirrors with the rest of the UI, so Save stays on the reader's
              // "forward" side.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  customButton(
                    title: S.of(context).discard,
                    function: () => Navigator.of(dialogContext).pop(false),
                    color: AppColors.greyDark,
                    width: 120.sp,
                    height: 36.h,
                    textStyle: StyleText.fontSize14Weight500
                        .copyWith(color: AppColors.text),
                  ),
                  customButton(
                    title: S.of(context).save,
                    function: () => Navigator.of(dialogContext).pop(true),
                    color: AppColors.primary,
                    width: 120.sp,
                    height: 36.h,
                    textStyle: StyleText.fontSize14Weight500
                        .copyWith(color: AppColors.textButton),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) onColorSelected(working);
  }

  @override
  Widget build(BuildContext context) {
    final Color? value = color;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: () => _pick(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 9.sp),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(kAppRadius.r),
          ),
          // 20.sp is what the dropdown's chevron holds its content row open to,
          // so the empty (hint-only) field matches the filled one instead of
          // collapsing to the text's line height.
          child: SizedBox(
            height: 20.sp,
            child: Row(
              children: <Widget>[
                if (value != null) ...<Widget>[
                  Container(
                    width: 20.sp,
                    height: 20.sp,
                    decoration: BoxDecoration(
                      color: value,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 10.sp),
                ],
                Expanded(
                  child: Text(
                    FormatHelper.capitalize(value != null ? hexOf(value) : label),
                    // A hex code is a number: it stays LTR even in Arabic.
                    textDirection: value != null ? TextDirection.ltr : null,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize14Weight400.copyWith(
                      color: value != null
                          ? AppColors.text
                          : AppColors.text.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The primary / secondary pair — side by side when there is room, stacked
/// when there is not.
class CustomColorPickerSection extends StatelessWidget {
  const CustomColorPickerSection({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onPrimaryColorSelected,
    required this.onSecondaryColorSelected,
    this.showHeading = true,
  });

  /// Null renders the field in its hint state.
  final Color? primaryColor;
  final Color? secondaryColor;
  final ValueChanged<Color> onPrimaryColorSelected;
  final ValueChanged<Color> onSecondaryColorSelected;

  /// Set false when the caller already draws its own section title.
  final bool showHeading;

  @override
  Widget build(BuildContext context) {
    // Measured, not orientation-guessed: this sits in a console card at one
    // width and a phone settings list at another, and orientation says nothing
    // useful about either.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stacked = constraints.maxWidth < 420;

        // The name above each field: once a colour is set the field shows
        // only its hex code, so without it you cannot tell which is which.
        Widget labelled(String name, Widget field) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  FormatHelper.capitalize(name),
                  style: StyleText.fontSize12Weight600.copyWith(color: AppColors.text),
                ),
                SizedBox(height: 6.h),
                field,
              ],
            );

        final Widget primary = labelled(
          S.of(context).primaryColor,
          CustomColorPickerField(
            label: S.of(context).primaryColor,
            color: primaryColor,
            onColorSelected: onPrimaryColorSelected,
          ),
        );
        final Widget secondary = labelled(
          S.of(context).secondaryColor,
          CustomColorPickerField(
            label: S.of(context).secondaryColor,
            color: secondaryColor,
            onColorSelected: onSecondaryColorSelected,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (showHeading) ...<Widget>[
              Text(
                FormatHelper.capitalize(S.of(context).colors),
                style: StyleText.fontSize16Weight500
                    .copyWith(color: AppColors.text),
              ),
              SizedBox(height: 12.h),
            ],
            if (stacked) ...<Widget>[
              primary,
              SizedBox(height: 12.h),
              secondary,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: primary),
                  SizedBox(width: 12.w),
                  Expanded(child: secondary),
                ],
              ),
          ],
        );
      },
    );
  }
}
