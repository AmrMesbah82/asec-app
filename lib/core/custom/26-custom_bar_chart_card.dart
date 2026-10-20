/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 26-custom_bar_chart_card.dart
/// Purpose: Declares `BarChartCard` — the VERTICAL bar chart.
/// Author: Manger Plus team
/// Updated: 8/9/2026 - Ported from knowticed_plus
///          `26-custom_bar_chart_card.dart`.
///
/// CHANGES MADE ON THE WAY ACROSS
/// ------------------------------
///  * Gridlines use `ChartPalette.grid`, not `AppColors.border` — see the note
///    at the top of `24-custom_chart_card.dart` for why that colour cannot be
///    used in this app.
///  * Axis labels moved from font size 9 to 10. `CardStyles` has a real token
///    at 10; anything it does not recognise silently falls back to 14, which
///    is how the axis ended up bigger than the bar labels.
///  * Bars default to `AppColors.secondaryPrimary` (the data accent the
///    revenue chart already uses) rather than `primary`, so the fill and the
///    header badge are not the same flat yellow.

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/16-custom_card_styles.dart';
import 'package:asec/core/custom/24-custom_chart_card.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// Rewrite the ASCII digits in [value] as Arabic-Indic numerals (٠١٢…) when
/// [arabic] is true, so the axis and the value labels read in Arabic figures
/// under an RTL locale. Non-digit characters are kept.
String _localizeDigits(String value, bool arabic) {
  if (!arabic) return value;
  const List<String> western = <String>[
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  ];
  const List<String> eastern = <String>[
    '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩',
  ];
  String out = value;
  for (int i = 0; i < western.length; i++) {
    out = out.replaceAll(western[i], eastern[i]);
  }
  return out;
}

/// Vertical bar chart card with the value printed above each bar.
///
/// ```dart
/// BarChartCard(
///   title: 'Orders by weekday',
///   dotIcon: AppAssets.metricOrders,
///   bars: const <ChartData>[
///     ChartData(label: 'Sat', value: 12),
///     ChartData(label: 'Sun', value: 18),
///   ],
/// )
/// ```
class BarChartCard extends StatelessWidget {
  final String title;
  final List<ChartData> bars;
  final Widget? trailing;

  /// One line of supporting copy under the title.
  final String? caption;

  /// Anything drawn between the header and the plot — a range switcher, say.
  final Widget? header;

  /// Anything drawn under the plot — usually a "view details" link.
  final Widget? footer;

  final double chartHeight;
  final double barWidth;

  /// Default bar colour when a [ChartData.color] is null.
  final Color? barColor;
  final double? width;

  /// Fixed card height. Null keeps the card hugging its content.
  final double? height;

  final EdgeInsetsGeometry? padding;

  /// Forwarded to [ChartCard.expandChild].
  final bool expandChild;

  /// Colour of the header badge.
  final Color? dotColor;

  /// SVG placed inside the header badge.
  final String? dotIcon;

  /// Message drawn instead of the plot when every bar is zero or the list is
  /// empty. Null falls back to an empty axis.
  final String? emptyMessage;

  const BarChartCard({
    super.key,
    required this.title,
    required this.bars,
    this.trailing,
    this.caption,
    this.header,
    this.footer,
    this.chartHeight = 220,
    this.barWidth = 16,
    this.barColor,
    this.width,
    this.height,
    this.padding,
    this.expandChild = false,
    this.dotColor,
    this.dotIcon,
    this.emptyMessage,
  });

  /// Highest bar value.
  double get _rawMax {
    double m = 0;
    for (final ChartData b in bars) {
      if (b.value > m) m = b.value;
    }
    return m;
  }

  /// Round [rough] UP to a "nice" whole-number step (1, 2, 5 × 10ⁿ), so the
  /// Y axis never shows fractional ticks like 0.5 / 1.5.
  double _niceStep(double rough) {
    if (rough <= 1) return 1;
    final int exp = (math.log(rough) / math.ln10).floor();
    final double pow10 = math.pow(10, exp).toDouble();
    final double frac = rough / pow10; // 1..10
    final double niceFrac = frac <= 1
        ? 1
        : frac <= 2
            ? 2
            : frac <= 5
                ? 5
                : 10;
    return niceFrac * pow10;
  }

  /// Whole-number gap between Y-axis gridlines.
  ///
  /// Derived from the DATA (the tallest bar), so the axis always shows exactly
  /// five equally-spaced whole numbers: 0, s, 2s, 3s, 4s. No data → 0,1,2,3,4.
  double get _step {
    final double s = _niceStep(_rawMax / 4);
    return s < 1 ? 1 : s;
  }

  /// Top of the Y axis: exactly four steps above zero, so the tallest bar
  /// always fits (step ≥ rawMax/4 ⇒ 4·step ≥ rawMax).
  double get _maxY => _step * 4;

  /// Widest bar label measured at the label text style.
  double get _maxLabelWidth {
    double maxW = 0;
    final TextStyle style = CardStyles.label(10);
    for (final ChartData b in bars) {
      final TextPainter tp = TextPainter(
        text: TextSpan(text: b.label, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      if (tp.width > maxW) maxW = tp.width;
    }
    return maxW;
  }

  @override
  Widget build(BuildContext context) {
    final Color defaultColor = barColor ?? AppColors.secondaryPrimary;
    final bool isEmpty = bars.isEmpty || _rawMax == 0;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (header != null) ...<Widget>[header!, SizedBox(height: 8.h)],
          if (isEmpty && emptyMessage != null)
            // The empty message fills the card the same way the plot does.
            // Left at its own height it would sit under the header with the
            // rest of a 360pt card blank beneath it — the shape of a broken
            // card, on the one screen that is meant to say "no data yet".
            _fill(
              SizedBox(
                height: expandChild ? null : chartHeight.h,
                child: Center(
                  child: Text(
                    FormatHelper.capitalize(emptyMessage!),
                    style: CardStyles.label(13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          // `Expanded` when the card has a fixed height, so the plot grows to
          // whatever is left after the header rather than sitting at its own
          // 220 with dead card underneath. Paired cards share a height now so
          // they end on the same line, and this is what stops that height
          // turning into a gap inside the card instead of below it.
          else
            _fill(_plot(context, defaultColor)),
          if (footer != null) ...<Widget>[SizedBox(height: 6.h), footer!],
        ],
      ),
    );
  }

  /// Wraps [child] in an [Expanded] when the card was given a fixed height.
  ///
  /// One place decides it, so the plot and the empty state cannot disagree
  /// about whether they fill the card.
  Widget _fill(Widget child) =>
      expandChild ? Expanded(child: child) : child;

  /// The axes and the bars. Split out so it can be dropped into an [Expanded]
  /// or laid out at its natural height from one place.
  Widget _plot(BuildContext context, Color defaultColor) {
    return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double available = constraints.maxWidth;
                // Each bar needs room for its label plus a gap; if that does
                // not fit, the plot scrolls sideways rather than letting the
                // labels overlap into a smear.
                final double slot =
                    math.max(barWidth.w, _maxLabelWidth) + 10.w;
                final double needed = slot * bars.length;
                final bool scrollable = needed > available;

                // In RTL the value axis belongs on the RIGHT.
                final bool isRtl =
                    Directionality.of(context) == TextDirection.rtl;

                final AxisTitles yAxisTitles = AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34.w,
                    interval: _step,
                    getTitlesWidget: (double v, TitleMeta meta) {
                      // Guard against a stray tick just past the top.
                      if (v > meta.max + 0.0001) return const SizedBox.shrink();
                      return Text(
                        FormatHelper.capitalize(_localizeDigits(v.round().toString(), isRtl)),
                        style: CardStyles.label(10),
                      );
                    },
                  ),
                );
                const AxisTitles hiddenAxis =
                    AxisTitles(sideTitles: SideTitles(showTitles: false));

                // Inside an Expanded the incoming height is real and is
                // exactly what should be filled; standing alone it is
                // unbounded, and the card's own default applies.
                final double plotHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : chartHeight.h;

                final Widget chart = SizedBox(
                  width: scrollable ? needed : available,
                  height: plotHeight,
                  child: BarChart(
                    BarChartData(
                      maxY: _maxY,
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _step,
                        getDrawingHorizontalLine: (double v) => FlLine(
                          color: ChartPalette.grid,
                          strokeWidth: 1,
                          dashArray: <int>[4, 4],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: hiddenAxis,
                        leftTitles: isRtl ? hiddenAxis : yAxisTitles,
                        rightTitles: isRtl ? yAxisTitles : hiddenAxis,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28.h,
                            getTitlesWidget: (double v, TitleMeta meta) {
                              final int i = v.toInt();
                              if (i < 0 || i >= bars.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: EdgeInsets.only(top: 6.h),
                                child: Text(
                                  FormatHelper.capitalize(bars[i].label),
                                  style: CardStyles.label(10),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        // The value is ALWAYS on screen (see
                        // showingTooltipIndicators below), so touch is off —
                        // a hover tooltip on top of a permanent label is the
                        // same number drawn twice.
                        enabled: false,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.transparent,
                          tooltipMargin: 2,
                          tooltipPadding: EdgeInsets.zero,
                          getTooltipItem: (
                            BarChartGroupData group,
                            int gi,
                            BarChartRodData rod,
                            int ri,
                          ) =>
                              BarTooltipItem(
                            _localizeDigits(rod.toY.toInt().toString(), isRtl),
                            CardStyles.value(11),
                          ),
                        ),
                      ),
                      barGroups: <BarChartGroupData>[
                        for (int i = 0; i < bars.length; i++)
                          BarChartGroupData(
                            x: i,
                            showingTooltipIndicators: const <int>[0],
                            barRods: <BarChartRodData>[
                              BarChartRodData(
                                toY: bars[i].value,
                                color: bars[i].color ?? defaultColor,
                                width: barWidth.w,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );

                if (!scrollable) return chart;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: chart,
                );
              },
            );
  }
}
