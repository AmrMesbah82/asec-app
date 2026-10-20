/// Module: core / animation
///
///*************************** FILE INFO ****************************///
/// File Name: app_animations.dart
/// Purpose: The app's motion kit, in one place so every screen moves the same
///          way:
///            * `FadeSlideIn`       — a widget arrives: fades in, rises, and
///                                    settles from 96% scale. `delay` staggers.
///            * `staggerDelay`      — the delay for item N of a list/grid.
///            * `CountUp`           — a number that counts up to its value.
///            * `HoverLift`         — lifts and grows a little under the mouse,
///                                    dips when pressed.
///            * `AppPageTransitions`— the route transition for every push.
///            * `ShellSwitch`       — fades/slides a shell section in when the
///                                    rail selection changes.
/// Author: ASEC team
/// Created: 25/9/2026
///
/// Durations are short (250–600 ms) and curves ease out: motion that is felt,
/// never waited for. With the OS "reduce motion" setting on, everything shows
/// instantly.

import 'package:flutter/material.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

abstract final class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 420);
  static const Duration slow = Duration(milliseconds: 650);
  static const Curve curve = Curves.easeOutCubic;
  static const Curve bounce = Curves.easeOutBack;

  /// Off when the OS asks for less motion OR the super admin switched
  /// animations off in the control centre.
  static bool reduced(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      !AppFeatures.to.isOn(AppFeature.animations);
}

/// The delay for the [index]th item: 45 ms apart, capped so a long list
/// never makes the last row wait.
Duration staggerDelay(int index, {int stepMs = 45, int maxMs = 500}) =>
    Duration(milliseconds: (index * stepMs).clamp(0, maxMs));

// ── FadeSlideIn ──────────────────────────────────────────────────────────────

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.medium,
    this.offset = const Offset(0, 24),
    this.scale = 0.96,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Where the child starts, in logical pixels, relative to where it ends.
  final Offset offset;

  /// Starting scale. 1 = no zoom.
  final double scale;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: AppMotion.curve);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double v = _t.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: widget.offset * (1 - v),
            child: Transform.scale(
              scale: widget.scale + (1 - widget.scale) * v,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

// ── CountUp ──────────────────────────────────────────────────────────────────

/// Counts from 0 (or the previous value) to [value]. Anything after the
/// number — "%", " MB" — goes in [suffix].
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.duration = AppMotion.slow,
  });

  final num value;
  final TextStyle? style;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: AppMotion.reduced(context) ? Duration.zero : duration,
      curve: AppMotion.curve,
      builder: (BuildContext context, double v, Widget? _) {
        final String text = value is int
            ? v.round().toString()
            : v.toStringAsFixed(1);
        return Text(FormatHelper.capitalize('$text$suffix'), style: style);
      },
    );
  }
}

// ── HoverLift ────────────────────────────────────────────────────────────────

class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.lift = 4,
    this.scale = 1.015,
    this.enabled = true,
  });

  final Widget child;
  final double lift;
  final double scale;
  final bool enabled;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final double scale =
        _down ? 0.98 : (_hover ? widget.scale : 1.0);
    final double dy = _down ? 0 : (_hover ? -widget.lift : 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(0.0, dy)
            ..scale(scale),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Route transition ─────────────────────────────────────────────────────────

/// Every pushed page fades in while rising 6% and settling from 97% scale;
/// the page underneath fades back a little. Used for all platforms so the
/// app feels the same on phone and desktop.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<double> inT =
        CurvedAnimation(parent: animation, curve: AppMotion.curve);
    final Animation<double> outT =
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn);

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(outT),
      child: FadeTransition(
        opacity: inT,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(inT),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(inT),
            child: child,
          ),
        ),
      ),
    );
  }
}

const PageTransitionsTheme appPageTransitions = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: AppPageTransitionsBuilder(),
    TargetPlatform.iOS: AppPageTransitionsBuilder(),
    TargetPlatform.macOS: AppPageTransitionsBuilder(),
    TargetPlatform.windows: AppPageTransitionsBuilder(),
    TargetPlatform.linux: AppPageTransitionsBuilder(),
    TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
  },
);

// ── Shell section switch ─────────────────────────────────────────────────────

/// Replays a short fade + rise whenever [switchKey] changes. The child keeps
/// its state (it is the same IndexedStack), only the entrance is animated.
class ShellSwitch extends StatefulWidget {
  const ShellSwitch({super.key, required this.switchKey, required this.child});

  final Object switchKey;
  final Widget child;

  @override
  State<ShellSwitch> createState() => _ShellSwitchState();
}

class _ShellSwitchState extends State<ShellSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.medium)..value = 1;

  @override
  void didUpdateWidget(ShellSwitch old) {
    super.didUpdateWidget(old);
    if (old.switchKey != widget.switchKey && !AppMotion.reduced(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> t =
        CurvedAnimation(parent: _c, curve: AppMotion.curve);
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(t),
        child: widget.child,
      ),
    );
  }
}
