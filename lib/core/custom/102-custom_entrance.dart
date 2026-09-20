/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 102-custom_entrance.dart
/// Purpose: Declares `BrandBackdrop` and `Entrance` — the customer app's
///          motion language, lifted out of the splash screen so every screen
///          moves the same way.
/// Author: Manger Plus team
/// Created: 4/9/2026 - The customer screens were static next to the opener.
///
/// WHY THIS EXISTS
///
/// The splash was the only animated thing in the app: drifting brand washes
/// behind a drum that fills, and copy that rises into place. Every screen after
/// it appeared fully formed and completely still, which made the opener read as
/// a different app's.
///
/// These two widgets are that opener's vocabulary, in a form a page can use:
///
///   BrandBackdrop  the two soft, slowly orbiting brand washes, behind any
///                  child. Purely decorative and non-interactive.
///   Entrance       one element fading up into place, with an [Entrance.index]
///                  so a column or a list arrives as a wave rather than all at
///                  once.
///
/// Both are deliberately cheap. The backdrop paints two blurred circles on one
/// repeating controller inside a RepaintBoundary; Entrance runs a single short
/// controller and then holds still forever. Neither rebuilds its child.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/theme/app_colors.dart';

/// Two soft brand washes drifting on slow, out-of-phase orbits, behind [child].
///
/// The same device the splash opens with. Static blobs read as a JPEG
/// background; moving ones make a screen feel alive without competing with
/// anything on it — which is why the opacities here are low enough that the
/// blobs never read as content.
class BrandBackdrop extends StatefulWidget {
  const BrandBackdrop({
    super.key,
    required this.child,
    this.intensity = 1,
  });

  final Widget child;

  /// Scales both blobs' opacity. 0 turns them off without having to take the
  /// widget back out — useful on a screen that turns out to be busy enough
  /// already.
  final double intensity;

  @override
  State<BrandBackdrop> createState() => _BrandBackdropState();
}

class _BrandBackdropState extends State<BrandBackdrop>
    with SingleTickerProviderStateMixin {
  /// One slow cycle for both blobs; they are separated by phase, not by rate,
  /// so a single controller drives the pair.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 9000),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.intensity <= 0) return widget.child;

    return Stack(
      children: <Widget>[
        // Behind everything and unable to swallow a tap — a decorative layer
        // that eats gestures is the classic "the button does nothing" bug.
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: Stack(
                children: <Widget>[
                  _DriftingBlob(
                    animation: _loop,
                    size: 320.sp,
                    color: AppColors.primary
                        .withOpacity(.13 * widget.intensity.clamp(0.0, 1.0)),
                    anchor: const Alignment(1.15, -1.05),
                    travel: 26,
                    phase: 0,
                  ),
                  _DriftingBlob(
                    animation: _loop,
                    size: 380.sp,
                    color: AppColors.secondaryPrimary
                        .withOpacity(.09 * widget.intensity.clamp(0.0, 1.0)),
                    anchor: const Alignment(-1.2, 1.1),
                    travel: 34,
                    phase: math.pi * .7,
                  ),
                ],
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// Fades [child] in and lifts it into place, once, when it first appears.
///
/// [index] staggers it against its siblings: give the items of a column or a
/// list their position and the group arrives as a wave. The stagger is capped
/// so a long list does not make its last item wait — past the cap everything
/// simply starts together.
///
/// Runs ONCE. After the first play the child is a plain, untouched widget with
/// no controller work behind it, so this is safe to leave on a screen the user
/// will sit on for a long time.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
    this.duration = const Duration(milliseconds: 420),
    this.stagger = const Duration(milliseconds: 70),
  });

  final Widget child;

  /// Position in the group. 0 starts immediately.
  final int index;

  /// How far, in logical pixels, the child rises. Deliberately NOT `.h`: this
  /// is a motion distance, not a layout measurement, and scaling it with the
  /// design canvas makes the same animation feel different on a tablet.
  final double offset;

  final Duration duration;

  /// Delay added per [index].
  final Duration stagger;

  /// Past this the stagger stops accumulating — the tail of a long list should
  /// not animate a second and a half after its head.
  static const Duration maxDelay = Duration(milliseconds: 560);

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _eased = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();

    final Duration delay = widget.stagger * widget.index;
    if (delay <= Duration.zero) {
      _controller.forward();
      return;
    }

    // The guard matters: a list item scrolled off and disposed inside the
    // delay would otherwise drive a dead controller.
    Future<void>.delayed(
      delay > Entrance.maxDelay ? Entrance.maxDelay : delay,
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _eased,
      // Built once and handed through — the child does not rebuild 25 times a
      // second just because something above it is moving.
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double t = _eased.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        );
      },
    );
  }
}

/// Wraps each of [children] in an [Entrance], numbering them in order.
///
/// For a column written out by hand, where passing an index to every child is
/// noise. A `ListView.builder` should use [Entrance] directly with its own
/// item index instead.
List<Widget> staggered(List<Widget> children, {int from = 0}) {
  return <Widget>[
    for (int i = 0; i < children.length; i++)
      Entrance(index: from + i, child: children[i]),
  ];
}

/// A soft brand wash that drifts on a slow ellipse. Ported from the splash.
class _DriftingBlob extends StatelessWidget {
  const _DriftingBlob({
    required this.animation,
    required this.size,
    required this.color,
    required this.anchor,
    required this.travel,
    required this.phase,
  });

  final Animation<double> animation;
  final double size;
  final Color color;

  /// Where the blob sits, in Alignment space — values beyond ±1 push it off
  /// screen so only the soft edge shows.
  final Alignment anchor;

  /// How far, in pixels, it wanders from that anchor.
  final double travel;

  /// Offsets this blob's orbit from the other one's.
  final double phase;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withOpacity(0)],
          ),
        ),
      ),
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value * 2 * math.pi + phase;
        return Align(
          alignment: anchor,
          child: Transform.translate(
            offset: Offset(
              math.cos(t) * travel,
              math.sin(t * .8) * travel * .7,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
