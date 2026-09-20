/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 28-custom_horizontal_bar_chart_card.dart
/// Purpose: Declares `HorizontalBarChartCard`.
/// Author: Manger Plus team
/// Updated: 8/9/2026 - Ported from knowticed_plus
///          `28-custom_horizontal_bar_chart_card.dart`.
///
/// Label + value sit ABOVE a full-width bar, with an x-axis scale underneath.
/// Drawn by hand rather than through fl_chart, for the reason the service-mix
/// chart is: one measure across a handful of categories with long names is the
/// case a plain layout does better — real text labels that wrap and never
/// collide, and a value at the end of every row.
///
/// PORTED WITH TWO CHANGES: the empty part of a bar uses `ChartPalette.track`
/// (`AppColors.border` is transparent in this app's dark theme, which made
/// every bar look full-width), and values can carry a unit suffix, so a
/// revenue chart can print "1 240 EGP" instead of a bare number.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/16-custom_card_styles.dart';
import 'package:asec/core/custom/24-custom_chart_card.dart';
import 'package:asec/core/theme/app_colors.dart';

/// Horizontal bar chart card.
///
/// ```dart
/// HorizontalBarChartCard(
///   title: 'Revenue by service',
///   suffix: 'EGP',
///   bars: <ChartData>[
///     ChartData(label: 'Wash & Fold', value: 3120),
///     ChartData(label: 'Dry Cleaning', value: 1980),
///   ],
/// )
/// ```
class HorizontalBarChartCard extends StatelessWidget {
  final String title;
  final List<ChartData> bars;
  final Widget? trailing;

  /// One line of supporting copy under the title.
  final String? caption;

  final Widget? header;
  final Widget? footer;

  /// Max X value; defaults to the highest bar.
  final double? maxX;
  final double barHeight;
  final Color? barColor;

  /// Show the value at the end of each row.
  final bool showValues;

  /// Printed after every value — a currency, a unit. Empty by default.
  final String suffix;

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool expandChild;

  /// Number of x-axis intervals (gridline labels = divisions + 1).
  final int divisions;

  /// Draw the x-axis scale under the bars.
  final bool showAxis;

  /// Vertical padding above and below each row.
  final double rowSpacing;

  /// Font size of the row label and value.
  final double labelFontSize;

  final Color? dotColor;
  final String? dotIcon;

  /// Message drawn instead of the bars when there is nothing to show.
  final String? emptyMessage;

  const HorizontalBarChartCard({
    super.key,
    required this.title,
    required this.bars,
    this.trailing,
    this.caption,
    this.header,
    this.footer,
    this.maxX,
    this.barHeight = 14,
    this.barColor,
    this.showValues = true,
    this.suffix = '',
    this.width,
    this.height,
    this.padding,
    this.expandChild = false,
    this.divisions = 5,
    this.showAxis = true,
    this.rowSpacing = 8,
    this.labelFontSize = 12,
    this.dotColor,
    this.dotIcon,
    this.emptyMessage,
  });

  double get _rawMax {
    double m = 0;
    for (final ChartData b in bars) {
      if (b.value > m) m = b.value;
    }
    return m;
  }

  double get _maxX {
    if (maxX != null && maxX! > 0) return maxX!;
    final double m = _rawMax;
    return m == 0 ? 100 : m;
  }

  /// Evenly spaced, rounded axis ticks from 0 to [_maxX].
  List<double> get _ticks {
    final double max = _maxX;
    final double step = _niceStep(max, divisions);
    final List<double> ticks = <double>[];
    for (double v = 0; v <= max + step * 0.001; v += step) {
      ticks.add(v);
    }
    return ticks;
  }

  /// Rounds a raw step up to a "nice" 1/2/5 × 10ⁿ value.
  double _niceStep(double range, int maxTicks) {
    if (range <= 0) return 1;
    final double raw = range / maxTicks;
    final double mag =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final double norm = raw / mag;
    final double step = norm <= 1
        ? 1
        : norm <= 2
            ? 2
            : norm <= 5
                ? 5
                : 10;
    return step * mag;
  }

  /// "1240" → "1 240". A space every three digits, because a four-figure
  /// revenue number with no grouping is read wrong at a glance.
  String _group(double value) {
    final String digits = value.round().abs().toString();
    final StringBuffer out = StringBuffer(value < 0 ? '-' : '');
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(' ');
      out.write(digits[i]);
    }
    return out.toString();
  }

  /// The value printed at the end of a row — grouped, with the unit. The
  /// axis ticks use [_group] instead: repeating the currency six times along
  /// the bottom of the card is noise, and every row already carries it.
  String _format(double value) =>
      suffix.isEmpty ? _group(value) : '${_group(value)} $suffix';

  @override
  Widget build(BuildContext context) {
    final Color defaultColor = barColor ?? AppColors.secondaryPrimary;

    if ((bars.isEmpty || _rawMax == 0) && emptyMessage != null) {
      return ChartCard(
        title: title,
        caption: caption,
        trailing: trailing,
        width: width,
        height: height,
        padding: padding,
        dotColor: dotColor,
        dotIcon: dotIcon,
        child: SizedBox(
          height: 160.h,
          child: Center(
            child: Text(
              emptyMessage!,
              style: CardStyles.label(13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final List<double> ticks = _ticks;

    return ChartCard(
      title: title,
      caption: caption,
      trailing: trailing,
      width: width,
      height: height,
      padding: padding,
      expandChild: expandChild,
      dotColor: dotColor,
      dotIcon: dotIcon,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final List<double> fractions = <double>[
            for (final double t in ticks) (t / _maxX).clamp(0.0, 1.0),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (header != null) ...<Widget>[header!, SizedBox(height: 8.h)],
              for (final ChartData b in bars)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: rowSpacing.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              b.label,
                              style: CardStyles.value(labelFontSize),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showValues) ...<Widget>[
                            SizedBox(width: 8.w),
                            Text(
                              _format(b.value),
                              style: CardStyles.value(labelFontSize),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Stack(
                        children: <Widget>[
                          Container(
                            height: barHeight.h,
                            decoration: BoxDecoration(
                              color: ChartPalette.track,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                          // A floor, so a service with a single small order is
                          // still a visible mark rather than nothing at all.
                          FractionallySizedBox(
                            widthFactor: (b.value / _maxX)
                                .clamp(b.value > 0 ? 0.02 : 0.0, 1.0)
                                .toDouble(),
                            child: Container(
                              height: barHeight.h,
                              decoration: BoxDecoration(
                                color: b.color ?? defaultColor,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (showAxis) ...<Widget>[
                SizedBox(height: 6.h),
                SizedBox(
                  height: 16.h,
                  child: Stack(
                    children: <Widget>[
                      for (int i = 0; i < ticks.length; i++)
                        Positioned(
                          left: fractions[i] * w,
                          child: FractionalTranslation(
                            // First tick hugs the left edge, last hugs the
                            // right, everything between is centred on its line.
                            translation: Offset(
                              i == 0
                                  ? 0
                                  : i == ticks.length - 1
                                      ? -1
                                      : -0.5,
                              0,
                            ),
                            child: Text(
                              _group(ticks[i]),
                              style: CardStyles.label(10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (footer != null) ...<Widget>[SizedBox(height: 4.h), footer!],
            ],
          );
        },
      ),
    );
  }
}
