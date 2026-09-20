/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 24-custom_chart_card.dart
/// Purpose: Declares `ChartCard`, `ChartData`, `ChartOrientation`,
///          `ChartLegendRow`, `ChartLegendInline`, `ChartTabPill` and
///          `ChartPalette`.
/// Author: Manger Plus team
/// Updated: 8/9/2026 - Ported from knowticed_plus `24-custom_chart_card.dart`.
///
/// PORTED FROM KNOWTICED, WITH THREE CHANGES
/// -----------------------------------------
///  1. `ChartSvg` did not come across. It was a list of literal paths into
///     knowticed's own icon folders; this app resolves every asset through
///     `AppAssets`, so a second table of paths would just be a table that
///     drifts.
///  2. Gridlines and empty tracks never use `AppColors.border`. That colour is
///     TRANSPARENT in this app's dark theme — the same bug that was fixed in
///     `revenue_chart.dart` — so anything drawn with it exists in light mode
///     only. `ChartPalette.grid` is the replacement.
///  3. `ChartPalette` is new. The house rule is one hue, not a rainbow: a
///     segment's colour must not imply an identity the data does not have.
///
/// Same style language as the card widgets: AppColors theme + screenutil.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/16-custom_card_styles.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';

/// Height of a paired chart card on the console overview.
///
/// ADDED 8/9/2026. Two cards side by side used to size themselves to their own
/// content, so the shorter one stopped early and left a band of page showing
/// between it and the row below — which is exactly what a dashboard should not
/// do, because the eye reads that gap as "something failed to load".
///
/// A CONSTANT RATHER THAN IntrinsicHeight
/// --------------------------------------
/// `IntrinsicHeight` is the textbook answer for an equal-height row and cannot
/// be used here. It asks each child how tall it would like to be, and these
/// cards contain `LayoutBuilder`s and fl_chart plots — neither can answer, and
/// the row throws rather than measuring. So the height is declared, and the
/// contents are built to fill whatever they are given.
///
/// 360 fits the revenue line's axis labels, seven service rows, and the donut
/// with its legend, without any of them scrolling.
const double kChartRowHeight = 360;

/// Brand-safe colours for every chart in the app.
///
/// WHY THIS EXISTS
/// ---------------
/// A donut with six slices needs six distinguishable fills, and the obvious
/// move — red, orange, blue, green, purple, teal — is the one thing the design
/// rules forbid, because it reads as a stock template and implies each slice
/// belongs to a different category system. The answer is a RAMP: one hue,
/// stepped in lightness. Slices stay separable, and the card still looks like
/// this product.
abstract final class ChartPalette {
  const ChartPalette._();

  /// Gridlines, axis rules and the empty part of a bar track.
  ///
  /// A wash of the text colour rather than `AppColors.border`, which is
  /// transparent in dark mode.
  static Color get grid => AppColors.secondaryText.withOpacity(.18);

  /// The unfilled part of a horizontal bar. `background` is a real colour in
  /// both themes; `border` is not.
  static Color get track => AppColors.background;

  /// [count] distinguishable fills, brightest first, all drawn from the brand
  /// accent.
  ///
  /// Blended toward the card colour rather than faded with opacity, so a slice
  /// sitting on top of another slice cannot show what is behind it.
  static List<Color> ramp(int count) {
    if (count <= 0) return const <Color>[];
    if (count == 1) return <Color>[AppColors.secondaryPrimary];

    final Color base = AppColors.secondaryPrimary;
    final Color into = AppColors.card;

    return <Color>[
      for (int i = 0; i < count; i++)
        // 0 → the full accent, last → 62% of the way to the card colour. Past
        // that the palest step stops reading as a slice at all.
        Color.lerp(base, into, (i / (count - 1)) * .62)!,
    ];
  }

  /// The ramp colour at position [index] of [count]. Convenience for building
  /// `ChartData` inside a `for`.
  static Color at(int index, int count) {
    final List<Color> colors = ramp(count);
    if (colors.isEmpty) return AppColors.secondaryPrimary;
    return colors[index.clamp(0, colors.length - 1)];
  }
}

/// Card with the standard chart header:
/// [primary dot or icon badge] Title ................ [trailing controls]
class ChartCard extends StatelessWidget {
  final String title;
  final Color? dotColor;
  final Widget? trailing;
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  /// SVG drawn inside the header badge. Null renders the small dot instead.
  final String? dotIcon;

  /// A line of supporting copy under the title, matching `DashboardCard`'s
  /// caption. Added here so the ported cards read the same as the console's
  /// own panels on the same page.
  final String? caption;

  /// Let [child] absorb the leftover vertical space instead of hugging
  /// its content. Only valid together with an explicit [height] (or a
  /// parent that gives a tight height) — a flexed child in an unbounded
  /// column asserts.
  final bool expandChild;

  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.dotColor,
    this.trailing,
    this.width,
    this.height,
    this.padding,
    this.dotIcon,
    this.caption,
    this.expandChild = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: padding ?? EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 20.sp),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: CardStyles.radius(),
        boxShadow: CardStyles.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // `min` while the card sizes itself to its content; `max` once a
        // height is given, so the child's Expanded has the full box to divide
        // rather than the height of the header above it.
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: <Widget>[
          Row(
            children: <Widget>[
              // House rule: artwork sits in a primary-filled circle and
              // anything inside it is drawn in `textButton`.
              if (dotIcon != null)
                Container(
                  width: 26.r,
                  height: 26.r,
                  decoration: BoxDecoration(
                    color: dotColor ?? AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomSvgImage(
                      assetPath: dotIcon!,
                      width: 16.r,
                      height: 16.r,
                      fit: BoxFit.contain,
                      color: AppColors.textButton,
                    ),
                  ),
                )
              else
                Container(
                  width: 10.r,
                  height: 10.r,
                  decoration: BoxDecoration(
                    color: dotColor ?? AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: CardStyles.title(14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (caption != null)
                      Text(
                        caption!,
                        style: CardStyles.label(11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: 14.h),
          // NOTE: keep this branch intrinsic-safe. A LayoutBuilder or a scroll
          // view cannot report an intrinsic height, so a caller that puts this
          // card inside an IntrinsicHeight must pass a fixed [height] large
          // enough for the content, or use [expandChild].
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

/// Whether a bar chart renders vertically ([BarChartCard], 26) or
/// horizontally ([HorizontalBarChartCard], 28).
enum ChartOrientation {
  horizontal,
  vertical;

  String toFirestore() => name;

  static ChartOrientation fromFirestore(String value) {
    switch (value.toLowerCase()) {
      case 'horizontal':
        return ChartOrientation.horizontal;
      case 'vertical':
        return ChartOrientation.vertical;
      default:
        return ChartOrientation.vertical;
    }
  }
}

/// One data entry for charts: label + value + colour.
class ChartData {
  final String label;
  final double value;
  final Color? color;

  const ChartData({required this.label, required this.value, this.color});
}

/// Legend row item: [coloured dot] Name ..... Amount
class ChartLegendRow extends StatelessWidget {
  final String name;
  final String? amount;
  final Color color;
  final double fontSize;

  const ChartLegendRow({
    super.key,
    required this.name,
    required this.color,
    this.amount,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: <Widget>[
          Container(
            width: 10.r,
            height: 10.r,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              name,
              style: CardStyles.label(fontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (amount != null)
            Text(amount!, style: CardStyles.value(fontSize)),
        ],
      ),
    );
  }
}

/// Compact horizontal legend (dot + name) used above or below a chart.
class ChartLegendInline extends StatelessWidget {
  final List<ChartData> items;
  final double fontSize;

  const ChartLegendInline({super.key, required this.items, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 4.h,
      children: <Widget>[
        for (final ChartData item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8.r,
                height: 8.r,
                decoration: BoxDecoration(
                  color: item.color ?? AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4.w),
              Text(item.label, style: CardStyles.label(fontSize)),
            ],
          ),
      ],
    );
  }
}

/// Small primary pill used in chart headers.
class ChartTabPill extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? color;

  const ChartTabPill({super.key, required this.text, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.buttonR,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 4.h),
        decoration: BoxDecoration(
          color: color ?? AppColors.primary,
          borderRadius: AppRadius.buttonR,
        ),
        child: Text(
          text,
          style: CardStyles.title(11).copyWith(color: AppColors.textButton),
        ),
      ),
    );
  }
}
