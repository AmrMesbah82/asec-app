/// Module: admin / a3_dashboard
///
///*************************** FILE INFO ****************************///
/// File Name: dashboard_kpi_card.dart
/// Purpose: Declares `KpiCard` — one of the four cards at the top of the
///          dashboard: the total, a trend badge, a picture of how the total
///          splits (a segment bar or a 7-day sparkline) and the numbers
///          behind that picture.
/// Author: ASEC team
/// Created: 25/9/2026
///
/// LAYOUT (top to bottom)
/// ----------------------
///   [icon] Label ............................. [+3 this week]
///   42
///   ██████████████░░░░░░  (segments)   or   ╱╲_╱╲  (sparkline)
///   ● Active 5     ● Off 1     ● CV 4
///
/// The footer facts carry the same colours as the bar segments, so the footer
/// IS the legend — no separate key is needed.
///
/// COLOURS: the card is plain [AppColors.card] (no tint); the icon tile and
/// the trend badge use the shared chip ground ([AppColors.chip]) with
/// [AppColors.onChip] text; [accent] paints only the thin top line, the
/// sparkline and the hover border.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// One number in the footer. [color] also paints its bar segment.
class KpiFact {
  const KpiFact(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;
}

/// A slice of the segment bar.
class KpiSegment {
  const KpiSegment(this.value, this.color);

  final int value;
  final Color color;
}

class KpiCard extends StatefulWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.badge,
    this.badgeIcon = Icons.trending_up_rounded,
    this.segments,
    this.sparkline,
    this.facts = const <KpiFact>[],
    this.compact = false,
  });

  /// PHONE LAYOUT: a small tile for a 2-column grid — icon and label, the
  /// number with its trend beside the line, and one line of the first two
  /// facts. Same data, a third of the height.
  final bool compact;

  final IconData icon;
  final Color accent;
  final String label;
  final String value;

  /// Short trend text top-right — "+3 this week". Hidden when null.
  final String? badge;
  final IconData badgeIcon;

  /// Draws a stacked bar. Ignored when [sparkline] is set.
  final List<KpiSegment>? segments;

  /// Draws a line over these values (oldest first).
  final List<double>? sparkline;

  /// Up to three numbers under the picture.
  final List<KpiFact> facts;

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kAppRadius.sp),
          border: Border.all(
            color: _hover ? accent.withOpacity(0.55) : AppColors.transparent,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kAppRadius.sp),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AppCard(
                mainAxisSize: MainAxisSize.max,
                padding: widget.compact
                    ? EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h)
                    : EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
                child: Expanded(child: _body(accent)),
              ),
              // A thin accent line along the top edge.
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                child: Container(height: 3, color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(Color accent) {
    if (widget.compact) return _compactBody(accent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          children: <Widget>[
            Container(
              width: 34.r,
              height: 34.r,
              decoration: BoxDecoration(
                color: AppColors.chip,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: AppIcon(widget.icon, size: 18.sp, color: accent),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                FormatHelper.capitalize(widget.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize13Weight600
                    .copyWith(color: AppColors.text),
              ),
            ),
            if (widget.badge != null) _Badge(widget.badge!, widget.badgeIcon),
          ],
        ),
        const Spacer(),

        // ── The total ───────────────────────────────────────────────────────
        FittedBox(
          alignment: AlignmentDirectional.centerStart,
          fit: BoxFit.scaleDown,
          child: int.tryParse(widget.value) != null
              ? CountUp(
                  value: int.parse(widget.value),
                  style: StyleText.fontSize22Weight700.copyWith(
                    fontSize: 30.sp,
                    height: 1.1,
                    color: AppColors.text,
                  ),
                )
              : Text(
                  FormatHelper.capitalize(widget.value),
                  style: StyleText.fontSize22Weight700.copyWith(
                    fontSize: 30.sp,
                    height: 1.1,
                    color: AppColors.text,
                  ),
                ),
        ),
        const Spacer(),

        // ── The picture ─────────────────────────────────────────────────────
        SizedBox(
          height: 30.h,
          child: widget.sparkline != null
              ? TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: AppMotion.curve,
                  builder: (BuildContext context, double t, Widget? _) =>
                      ClipRect(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: t,
                      child: CustomPaint(
                        painter: _SparklinePainter(widget.sparkline!, accent),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                )
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: AppMotion.curve,
                    builder: (BuildContext context, double t, Widget? child) =>
                        Align(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: t,
                      child: child,
                    ),
                    child: _SegmentBar(widget.segments ?? const <KpiSegment>[]),
                  ),
                ),
        ),
        SizedBox(height: 12.h),

        // ── The facts ───────────────────────────────────────────────────────
        Row(
          children: <Widget>[
            for (int i = 0; i < widget.facts.length; i++) ...<Widget>[
              if (i > 0)
                Container(
                  width: 1,
                  height: 26.h,
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  color: AppColors.secondaryText.withOpacity(0.18),
                ),
              Expanded(child: _Fact(widget.facts[i])),
            ],
          ],
        ),
      ],
    );
  }
}

extension on _KpiCardState {
  Widget _compactBody(Color accent) {
    final List<KpiFact> facts = widget.facts.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 26.r,
              height: 26.r,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(child: AppIcon(widget.icon, size: 14.sp, color: accent)),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                FormatHelper.capitalize(widget.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize12Weight600.copyWith(color: AppColors.secondaryText),
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: FittedBox(
                alignment: AlignmentDirectional.centerStart,
                fit: BoxFit.scaleDown,
                child: int.tryParse(widget.value) != null
                    ? CountUp(
                        value: int.parse(widget.value),
                        style: StyleText.fontSize22Weight700
                            .copyWith(height: 1.05, color: AppColors.text),
                      )
                    : Text(
                        FormatHelper.capitalize(widget.value),
                        style: StyleText.fontSize22Weight700
                            .copyWith(height: 1.05, color: AppColors.text),
                      ),
              ),
            ),
            if (widget.sparkline != null)
              SizedBox(
                width: 56.w,
                height: 26.h,
                child: CustomPaint(
                  painter: _SparklinePainter(widget.sparkline!, accent, small: true),
                ),
              ),
          ],
        ),
        if (widget.badge != null) ...<Widget>[
          SizedBox(height: 4.h),
          Row(
            children: <Widget>[
              AppIcon(widget.badgeIcon, size: 11.sp, color: AppColors.green),
              SizedBox(width: 3.w),
              Flexible(
                child: Text(
                  FormatHelper.capitalize(widget.badge!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StyleText.fontSize10Weight600.copyWith(color: AppColors.green),
                ),
              ),
            ],
          ),
        ],
        if (facts.isNotEmpty) ...<Widget>[
          SizedBox(height: 6.h),
          Container(height: 1, color: AppColors.secondaryText.withOpacity(0.12)),
          SizedBox(height: 6.h),
          Text(
            FormatHelper.capitalize(facts.map((KpiFact f) => '${f.value} ${f.label}').join('  ·  ')),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StyleText.fontSize10Weight500.copyWith(color: AppColors.secondaryText),
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.icon);

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.onChip;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            FormatHelper.capitalize(text),
            style: StyleText.fontSize11Weight600.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.fact);

  final KpiFact fact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          FormatHelper.capitalize(fact.value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: StyleText.fontSize14Weight700.copyWith(color: AppColors.text),
        ),
        SizedBox(height: 2.h),
        Row(
          children: <Widget>[
            if (fact.color != null) ...<Widget>[
              Container(
                width: 7.r,
                height: 7.r,
                decoration: BoxDecoration(
                  color: fact.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4.w),
            ],
            Flexible(
              child: Text(
                FormatHelper.capitalize(fact.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize11Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Stacked horizontal bar. An all-zero bar draws as one empty track instead
/// of vanishing, so the card keeps its shape with no data.
class _SegmentBar extends StatelessWidget {
  const _SegmentBar(this.segments);

  final List<KpiSegment> segments;

  @override
  Widget build(BuildContext context) {
    final List<KpiSegment> visible =
        segments.where((KpiSegment s) => s.value > 0).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: SizedBox(
        height: 9.h,
        child: visible.isEmpty
            ? ColoredBox(color: AppColors.secondaryText.withOpacity(0.15))
            : Row(
                children: <Widget>[
                  for (int i = 0; i < visible.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: visible[i].value,
                      child: ColoredBox(color: visible[i].color),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// A smooth line with a soft fill under it and a dot on the last point.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color, {this.small = false});

  final List<double> values;
  final Color color;

  /// The tile-sized version: thinner line, smaller end dot.
  final bool small;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0) return;

    final double maxV = math.max(values.reduce(math.max), 1);
    final double dx = size.width / (values.length - 1);
    const double top = 4;
    final double usable = size.height - top - 2;

    final List<Offset> points = <Offset>[
      for (int i = 0; i < values.length; i++)
        Offset(i * dx, top + usable - (values[i] / maxV) * usable),
    ];

    final Path line = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final Offset a = points[i - 1];
      final Offset b = points[i];
      final double mid = (a.dx + b.dx) / 2;
      line.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
    }

    final Path fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[color.withOpacity(0.35), color.withOpacity(0.0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = small ? 1.6 : 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(points.last, small ? 2.5 : 3.5, Paint()..color = color);
    canvas.drawCircle(
      points.last,
      small ? 4.5 : 6,
      Paint()..color = color.withOpacity(0.25),
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.color != color || old.values != values || old.small != small;
}
