/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 27-custom_donut_chart_card.dart
/// Purpose: Declares `DonutChartCard`.
/// Author: Manger Plus team
/// Updated: 8/9/2026 - Ported from knowticed_plus
///          `27-custom_donut_chart_card.dart`.
///
/// A ring chart with a total in the middle and a legend carrying the amounts.
/// Built on fl_chart's `PieChart`.
///
/// PORTED WITH TWO CHANGES: the on-segment percentage is drawn in
/// `AppColors.textButton` rather than a hardcoded white (the house rule for
/// anything sitting on a brand fill, and white on the palest ramp step is
/// unreadable), and callers that pass no colours get `ChartPalette.ramp` —
/// one hue stepped in lightness — instead of a rainbow.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/16-custom_card_styles.dart';
import 'package:asec/core/custom/24-custom_chart_card.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';

/// Rewrite the ASCII digits in [value] as Arabic-Indic numerals (٠١٢…) when
/// [arabic] is true, so the ring percentages and legend amounts read in Arabic
/// figures under an RTL locale. Non-digit characters (like `%`) are kept.
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

/// Donut chart card: ring, centre total, legend rows with amounts.
///
/// ```dart
/// DonutChartCard(
///   title: 'Status share',
///   centerValue: '128',
///   centerLabel: 'orders',
///   sections: <ChartData>[
///     ChartData(label: 'Washing', value: 34),
///     ChartData(label: 'Ready', value: 22),
///   ],
/// )
/// ```
class DonutChartCard extends StatelessWidget {
  final String title;
  final List<ChartData> sections;
  final String? centerValue;
  final String? centerLabel;
  final Widget? trailing;

  /// One line of supporting copy under the title.
  final String? caption;

  final double chartSize;
  final double ringWidth;
  final double? width;

  /// Fixed card height. Null keeps the card hugging its content.
  final double? height;

  final EdgeInsetsGeometry? padding;
  final bool expandChild;

  /// Show the legend (name + amount) next to the ring.
  final bool showLegend;

  /// Stack the legend UNDER the ring as a compact dot + name row, for a narrow
  /// column where a side-by-side legend has no room.
  final bool legendBelow;

  final Color? dotColor;
  final String? dotIcon;

  /// Show the percentage label on each ring segment.
  final bool showPercentages;

  /// Message drawn instead of the ring when there is nothing to show.
  final String? emptyMessage;

  const DonutChartCard({
    super.key,
    required this.title,
    required this.sections,
    this.centerValue,
    this.centerLabel,
    this.trailing,
    this.caption,
    this.chartSize = 150,
    this.ringWidth = 28,
    this.width,
    this.height,
    this.padding,
    this.expandChild = false,
    this.showLegend = true,
    this.legendBelow = false,
    this.dotColor,
    this.dotIcon,
    this.showPercentages = true,
    this.emptyMessage,
  });

  /// The sections with a colour filled in for any that arrived without one.
  ///
  /// Done here rather than at the call site so every donut in the app lands on
  /// the same ramp without each screen remembering to ask for it.
  List<ChartData> get _colored {
    final int n = sections.length;
    return <ChartData>[
      for (int i = 0; i < n; i++)
        ChartData(
          label: sections[i].label,
          value: sections[i].value,
          color: sections[i].color ?? ChartPalette.at(i, n),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final List<ChartData> data = _colored;
    final double total = data.fold<double>(
      0,
      (double sum, ChartData s) => sum + s.value,
    );

    if (total == 0 && emptyMessage != null) {
      return ChartCard(
        title: title,
        caption: caption,
        trailing: trailing,
        width: width,
        height: height,
        padding: padding,
        dotColor: dotColor,
        dotIcon: dotIcon,
        // Fills a fixed-height card rather than leaving the bottom two thirds
        // blank under the message.
        expandChild: expandChild,
        child: SizedBox(
          height: expandChild ? null : 160.h,
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

    final Widget chart = SizedBox(
      width: chartSize.r,
      height: chartSize.r,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: (chartSize.r / 2) - ringWidth.r,
              sections: total > 0
                  ? <PieChartSectionData>[
                      for (final ChartData s in data)
                        PieChartSectionData(
                          value: s.value,
                          color: s.color,
                          radius: ringWidth.r,
                          // Hidden on slivers too thin for the text to fit,
                          // where it would spill over its own segment.
                          showTitle:
                              showPercentages && (s.value / total) >= 0.06,
                          title: _localizeDigits(
                            '${(s.value / total * 100).round()}%',
                            isRtl,
                          ),
                          titleStyle: StyleText.fontSize10Weight500.copyWith(
                            color: AppColors.textButton,
                            height: 1.h,
                          ),
                          titlePositionPercentageOffset: 0.5,
                        ),
                    ]
                  : <PieChartSectionData>[
                      // Empty state: one full, unlabelled grey ring. Passing
                      // fl_chart a set of zero-value slices paints as stray
                      // crossing lines, not as an empty donut.
                      PieChartSectionData(
                        value: 1,
                        color: ChartPalette.grid,
                        radius: ringWidth.r,
                        showTitle: false,
                      ),
                    ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (centerValue != null)
                Text(
                  _localizeDigits(centerValue!, isRtl),
                  style: CardStyles.title(18),
                ),
              if (centerLabel != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppPadding.h),
                  child: Text(
                    centerLabel!,
                    style: CardStyles.label(10),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

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
      child: !showLegend
          ? Center(child: chart)
          : legendBelow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Center(child: chart),
                    SizedBox(height: 12.h),
                    ChartLegendInline(items: data),
                  ],
                )
              : Row(
                  // Centred rather than stretched: with a fixed card height
                  // the legend and the ring are different lengths, and pinning
                  // them to the top leaves the ring floating above a gap.
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (final ChartData s in data)
                            ChartLegendRow(
                              name: s.label,
                              amount: _localizeDigits(
                                s.value.toInt().toString(),
                                isRtl,
                              ),
                              color: s.color ?? AppColors.secondaryPrimary,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20.w),
                    chart,
                  ],
                ),
    );
  }
}
