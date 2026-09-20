/// Module: admin / a3_dashboard
///
///*************************** FILE INFO ****************************///
/// File Name: dashboard_charts.dart
/// Purpose: Declares `DashboardCharts` — the four cards above the table.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// Every card here is one of the shared chart widgets from `core/custom`
/// (24 / 26 / 27 / 28). Nothing in this file draws a chart itself; it turns
/// [DashboardData]'s series into [ChartData] and picks the card.
///
/// LAYOUT
/// ------
/// Two by two on a wide console. Under 1000pt the cards stack, because a bar
/// chart's axis at half that width is unlabelled mush — the ring is the one
/// shape that still reads small, so it goes first.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/24-custom_chart_card.dart';
import 'package:asec/core/custom/26-custom_bar_chart_card.dart';
import 'package:asec/core/custom/27-custom_donut_chart_card.dart';
import 'package:asec/core/custom/28-custom_horizontal_bar_chart_card.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a3_dashboard/presentation/ui/widgets/dashboard_data.dart';
import 'package:asec/generated/l10n.dart';

class DashboardCharts extends StatelessWidget {
  const DashboardCharts({super.key, required this.data});

  final DashboardData data;

  static const double _cardHeight = 300;
  static const double _breakpoint = 1000;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    final Widget bands = _scoreBands(context, s);
    final Widget byDay = _attemptsByDay(context, s);
    final Widget byQuiz = _averageByQuiz(context, s);
    final Widget top = _topMembers(context, s);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        if (c.maxWidth < _breakpoint) {
          return Column(
            children: <Widget>[
              bands,
              SizedBox(height: 16.h),
              byDay,
              SizedBox(height: 16.h),
              byQuiz,
              SizedBox(height: 16.h),
              top,
            ],
          );
        }
        return Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 2, child: bands),
                SizedBox(width: 16.w),
                Expanded(flex: 3, child: byDay),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: byQuiz),
                SizedBox(width: 16.w),
                Expanded(flex: 2, child: top),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── 1. Score bands ────────────────────────────────────────────────────────
  //
  // A ring rather than bars: every attempt lands in exactly one band and the
  // four add up to the whole, which is the one case a ring does not mislead.
  Widget _scoreBands(BuildContext context, S s) {
    final List<int> bands = data.scoreBands;
    final List<String> labels = <String>[s.band0, s.band50, s.band65, s.band80];
    final List<Color> colors = <Color>[
      AppColors.red,
      AppColors.statusPending,
      AppColors.lightGreen,
      AppColors.green,
    ];

    return DonutChartCard(
      title: s.scoreBands,
      caption: s.allQuizzesAvg,
      height: _cardHeight.h,
      expandChild: true,
      chartSize: 140,
      ringWidth: 26,
      centerValue: data.hasAttempts ? '${data.averagePercent}%' : '—',
      centerLabel: s.averageScoreLabel,
      emptyMessage: s.noResultsYet,
      sections: <ChartData>[
        for (int i = 0; i < bands.length; i++)
          if (bands[i] > 0)
            ChartData(
              label: labels[i],
              value: bands[i].toDouble(),
              color: colors[i],
            ),
      ],
    );
  }

  // ── 2. Attempts by day ────────────────────────────────────────────────────
  //
  // Counts, not averages — this card answers "is anybody using it", and a day
  // with no attempts is a real zero, so it keeps its bar.
  Widget _attemptsByDay(BuildContext context, S s) {
    final List<Series> days = data.attemptsByDay();

    return BarChartCard(
      title: s.attemptsByDay,
      caption: s.last7Days,
      height: _cardHeight.h,
      expandChild: true,
      barColor: AppColors.primary,
      emptyMessage: s.noResultsYet,
      bars: <ChartData>[
        for (final Series d in days) ChartData(label: d.label, value: d.value),
      ],
    );
  }

  // ── 3. Average per quiz ───────────────────────────────────────────────────
  //
  // Horizontal, because quiz titles are words: vertical bars would turn
  // "Unit 3 revision" into a rotated smear under the axis.
  Widget _averageByQuiz(BuildContext context, S s) {
    final List<Series> rows = data.averageByQuiz();

    return HorizontalBarChartCard(
      title: s.averageByQuiz,
      caption: s.averageScoreLabel,
      height: _cardHeight.h,
      expandChild: true,
      // Always 0..100: a percentage axis that rescales to the best score makes
      // a class average of 40 look like a full bar.
      maxX: 100,
      suffix: '%',
      barColor: AppColors.secondaryPrimary,
      emptyMessage: s.noResultsYet,
      bars: <ChartData>[
        for (final Series r in rows)
          ChartData(label: r.label, value: r.value, color: _bandColor(r.value)),
      ],
    );
  }

  // ── 4. Top members ────────────────────────────────────────────────────────
  Widget _topMembers(BuildContext context, S s) {
    final List<Series> rows = data.topMembers();

    return HorizontalBarChartCard(
      title: s.topMembers,
      caption: s.averageScoreLabel,
      height: _cardHeight.h,
      expandChild: true,
      maxX: 100,
      suffix: '%',
      barColor: AppColors.primary,
      emptyMessage: s.noResultsYet,
      bars: <ChartData>[
        for (final Series r in rows)
          ChartData(label: r.label, value: r.value, color: _bandColor(r.value)),
      ],
    );
  }

  /// The same three bands the result screens use, so a score never changes
  /// colour between two places in the app.
  static Color _bandColor(double percent) {
    if (percent >= 80) return AppColors.green;
    if (percent >= 50) return AppColors.statusPending;
    return AppColors.red;
  }
}
