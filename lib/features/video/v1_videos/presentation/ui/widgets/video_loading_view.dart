/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_loading_view.dart
/// Purpose: Declares `VideoLoadingView` and `VideoBufferingBadge` — what the
///          player shows instead of a spinning circle while a lesson loads
///          or buffers.
/// Author: ASEC team
/// Created: 30/9/2026
///
/// VideoLoadingView (before the first frame)
/// ------------------------------------------
///  * a slow brand-coloured glow drifting across a dark stage,
///  * a play button that breathes, with rings rippling out of it,
///  * the lesson's title, and "Loading lesson" with three bouncing dots,
///  * a thin bar with a light sweeping along it.
/// Everything runs off ONE AnimationController, so it costs one ticker.
///
/// VideoBufferingBadge (the video stalls mid-lesson)
/// -------------------------------------------------
/// The same rippling button, smaller, on a soft dark disc — handed to
/// Chewie as its `bufferingBuilder`, so buffering matches the loading look.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class VideoLoadingView extends StatefulWidget {
  const VideoLoadingView({super.key, this.title = '', this.label = ''});

  /// The lesson's title, under the button. Empty hides it.
  final String title;

  /// "Loading lesson" in the app's language. Empty hides the line.
  final String label;

  @override
  State<VideoLoadingView> createState() => _VideoLoadingViewState();
}

class _VideoLoadingViewState extends State<VideoLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color brand = AppColors.primary;

    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, _) {
        final double t = _c.value; // 0 → 1, looping
        final double wave = math.sin(t * 2 * math.pi); // -1 → 1

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // ── The stage: dark, with a brand glow drifting slowly ─────────
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(wave * 0.6, -0.2 + 0.25 * math.cos(t * 2 * math.pi)),
                  radius: 1.2,
                  colors: <Color>[
                    Color.alphaBlend(brand.withOpacity(0.35), const Color(0xFF0B0B12)),
                    const Color(0xFF07070B),
                  ],
                ),
              ),
            ),

            // ── Button, title, label ───────────────────────────────────────
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints box) {
                final bool small = box.maxHeight < 220;
                final double button = small ? 52 : 72;
                return Center(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _RippleButton(t: t, size: button, color: brand),
                        if (widget.title.isNotEmpty && !small) ...<Widget>[
                          SizedBox(height: 18.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Text(
                              FormatHelper.capitalize(widget.title),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: StyleText.fontSize15Weight600
                                  .copyWith(color: Colors.white, height: 1.4),
                            ),
                          ),
                        ],
                        if (widget.label.isNotEmpty) ...<Widget>[
                          SizedBox(height: small ? 10 : 10.h),
                          _LoadingLabel(t: t, text: widget.label),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── The sweeping bar along the bottom ──────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 3,
              child: _SweepBar(t: t, color: brand),
            ),
          ],
        );
      },
    );
  }
}

/// A play button that breathes, with two rings rippling out of it.
class _RippleButton extends StatelessWidget {
  const _RippleButton({required this.t, required this.size, required this.color});

  final double t;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double breathe = 1 + 0.06 * math.sin(t * 4 * math.pi);
    final double box = size * 2.2;

    Widget ring(double phase) {
      final double p = (t + phase) % 1; // 0 → 1 as the ring grows
      final double d = size + (box - size) * Curves.easeOut.transform(p);
      return Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity((1 - p) * 0.55), width: 2),
        ),
      );
    }

    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          ring(0),
          ring(0.5),
          Transform.scale(
            scale: breathe,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[color, AppColors.secondaryPrimary],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: color.withOpacity(0.55), blurRadius: size * 0.45),
                ],
              ),
              child: Center(
                child: AppIcon(Icons.play_arrow_rounded, size: size * 0.55, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Loading lesson" followed by three dots that bounce in turn.
class _LoadingLabel extends StatelessWidget {
  const _LoadingLabel({required this.t, required this.text});

  final double t;
  final String text;

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) {
      final double p = ((t * 2) - i * 0.15) % 1;
      final double lift = p < 0.5 ? math.sin(p * 2 * math.pi) : 0;
      return Transform.translate(
        offset: Offset(0, -4 * lift.clamp(0.0, 1.0)),
        child: Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5 + 0.5 * lift.clamp(0.0, 1.0)),
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          FormatHelper.capitalize(text),
          style: StyleText.fontSize13Weight500.copyWith(color: Colors.white70),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[dot(0), dot(1), dot(2)]),
        ),
      ],
    );
  }
}

/// A faint track with a bright band of light sweeping across it.
class _SweepBar extends StatelessWidget {
  const _SweepBar({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double w = box.maxWidth;
        final double band = w * 0.35;
        final double x = -band + (w + band) * Curves.easeInOut.transform(t);
        return Stack(
          children: <Widget>[
            Positioned.fill(child: ColoredBox(color: Colors.white.withOpacity(0.08))),
            Positioned(
              left: x,
              top: 0,
              bottom: 0,
              width: band,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[color.withOpacity(0), color, color.withOpacity(0)],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Mid-lesson buffering: the rippling button on a soft dark disc.
class VideoBufferingBadge extends StatefulWidget {
  const VideoBufferingBadge({super.key});

  @override
  State<VideoBufferingBadge> createState() => _VideoBufferingBadgeState();
}

class _VideoBufferingBadgeState extends State<VideoBufferingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, _) =>
              _RippleButton(t: _c.value, size: 40, color: AppColors.primary),
        ),
      ),
    );
  }
}
