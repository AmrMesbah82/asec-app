/// Motion for the public site — smooth, cheap, and switched off when the
/// visitor's system asks for reduced motion.
///
///   * [OnVisible] — tells its builder once the widget has scrolled into view.
///   * [Reveal]    — fades a section / card up into place the first time it
///                   is seen; `delay` staggers cards in a row.
///   * [SmoothWheel] — eases mouse-wheel scrolling instead of jumping 100px a
///                   notch (trackpads and touch keep their own 1:1 feel).
///   * [HoverLift] — lifts a card a few pixels under the pointer.
///
/// Everything animates with transforms and opacity only (no layout per
/// frame), which is what keeps it smooth in the browser.
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

bool _reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Calls [builder] with `false` until the widget's top has entered the
/// bottom ~92% of the screen, then with `true` for good.
class OnVisible extends StatefulWidget {
  const OnVisible({super.key, required this.builder, this.child});

  final Widget Function(BuildContext context, bool visible, Widget? child) builder;
  final Widget? child;

  @override
  State<OnVisible> createState() => _OnVisibleState();
}

class _OnVisibleState extends State<OnVisible> {
  bool _seen = false;
  ScrollPosition? _pos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seen) return;
    if (_reduceMotion(context)) {
      _seen = true;
      return;
    }
    final ScrollPosition? pos = Scrollable.maybeOf(context)?.position;
    if (pos != _pos) {
      _pos?.removeListener(_check);
      _pos = pos;
      _pos?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (_seen || !mounted) return;
    final RenderObject? ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
      return;
    }
    final double top = ro.localToGlobal(Offset.zero).dy;
    final double screen = MediaQuery.sizeOf(context).height;
    if (top < screen * 0.92 && top + ro.size.height > 0) {
      _pos?.removeListener(_check);
      _pos = null;
      setState(() => _seen = true);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _seen, widget.child);
}

/// Fades [child] in and slides it up [offset] px the first time it is seen.
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.offset = 36,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final int total = delay.inMilliseconds + duration.inMilliseconds;
    final double start = total == 0 ? 0 : delay.inMilliseconds / total;
    return OnVisible(
      child: child,
      builder: (BuildContext context, bool visible, Widget? child) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: visible ? 1 : 0),
        duration: Duration(milliseconds: total),
        curve: Interval(start, 1, curve: Curves.easeOutCubic),
        child: child,
        builder: (BuildContext context, double v, Widget? child) => v >= 1
            ? child!
            : Opacity(
                opacity: v,
                child: Transform.translate(offset: Offset(0, (1 - v) * offset), child: child),
              ),
      ),
    );
  }
}

/// Eases mouse-wheel scrolling of [controller]. Put it INSIDE the scroll
/// view, around the content: the innermost wheel listener wins, so it takes
/// the wheel before the scroll view's own jumpy handler does.
class SmoothWheel extends StatefulWidget {
  const SmoothWheel({super.key, required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  State<SmoothWheel> createState() => _SmoothWheelState();
}

class _SmoothWheelState extends State<SmoothWheel> {
  double? _target;

  void _onSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent || _reduceMotion(context)) return;
    if (!widget.controller.hasClients) return;
    GestureBinding.instance.pointerSignalResolver.register(e, (PointerSignalEvent ev) {
      final ScrollPosition p = widget.controller.position;
      final double dy = (ev as PointerScrollEvent).scrollDelta.dy;
      if (dy == 0) return;
      // Small, fast deltas are a trackpad: follow them 1:1.
      if (dy.abs() < 50) {
        _target = null;
        p.jumpTo((p.pixels + dy).clamp(p.minScrollExtent, p.maxScrollExtent));
        return;
      }
      final double from = _target ?? p.pixels;
      final double to = (from + dy * 1.1).clamp(p.minScrollExtent, p.maxScrollExtent);
      _target = to;
      p.animateTo(to, duration: const Duration(milliseconds: 520), curve: Curves.easeOutQuart).whenComplete(() {
        if (_target == to) _target = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) => Listener(onPointerSignal: _onSignal, child: widget.child);
}

/// Lifts its child [lift] px (and calls [builder] with the hover state).
class HoverLift extends StatefulWidget {
  const HoverLift({super.key, required this.builder, this.lift = 6});

  final Widget Function(BuildContext context, bool hover) builder;
  final double lift;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _h = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _h ? -widget.lift : 0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: widget.builder(context, _h),
          builder: (BuildContext context, double dy, Widget? child) =>
              Transform.translate(offset: Offset(0, dy), child: child),
        ),
      );
}

/// A number that counts up from 0 once it has been seen.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.builder});

  final double value;
  final Widget Function(BuildContext context, int n) builder;

  @override
  Widget build(BuildContext context) => OnVisible(
        builder: (BuildContext context, bool visible, _) => TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: visible ? value : 0),
          duration: Duration(milliseconds: math.min(2200, 900 + (value * 4).round())),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double v, _) => builder(context, v.round()),
        ),
      );
}
