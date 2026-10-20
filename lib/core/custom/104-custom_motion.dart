/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 104-custom_motion.dart
/// Purpose: Declares `AppMotion`, `AnimateInList`, `AnimatedCount` and
///          `SectionTransition` — the console's shared motion vocabulary,
///          built on the app's existing `Entrance` widget (102).
/// Author: Manger Plus team
/// Created at: 8/9/2026 - Added so every dashboard page arrives the same way
///          instead of appearing fully formed between one frame and the next.
///
/// WHY ONE FILE
/// ------------
/// Motion is a house rule like colour is. Six screens each picking their own
/// duration and curve is how an app ends up feeling assembled rather than
/// designed — one card easing in over 600ms next to another snapping in over
/// 120ms reads as a bug even when both are deliberate. Everything here comes
/// out of [AppMotion], and no screen writes its own `Duration`.
///
/// THE BUDGET
/// ----------
/// This is a console someone has open all day, so the animation has to be
/// invisible on the tenth visit and only felt on the first. That means short
/// (under a third of a second), small (a rise of a few pixels, never a slide
/// across the screen), and never blocking: the content is readable the whole
/// way through, and nothing waits on an animation to become interactive.
///
/// It also means NOTHING LOOPS. A spinner that never stops, a card that
/// pulses — those are fine for a few seconds and unbearable for an afternoon.
/// The one exception in this app is the brand drum, which is a logo.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/102-custom_entrance.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// The console's motion constants. Change them here, everywhere follows.
abstract final class AppMotion {
  const AppMotion._();

  /// A single element arriving.
  static const Duration entrance = Duration(milliseconds: 260);

  /// One page giving way to another.
  static const Duration section = Duration(milliseconds: 220);

  /// A number moving to a new value. Longer than an entrance on purpose: the
  /// point of a count-up is that the eye can follow it, and 260ms across four
  /// digits is a blur.
  static const Duration count = Duration(milliseconds: 700);

  /// Gap between one staggered child and the next.
  ///
  /// 45ms — enough to read as a sequence rather than a single block, short
  /// enough that a page of eight cards is fully in within 600ms. Past about
  /// 80ms a long page starts to feel like it is loading slowly.
  static const Duration stagger = Duration(milliseconds: 45);

  // The cap on accumulated stagger delay is NOT here: `Entrance.maxDelay`
  // already owns it, at 560ms. A second cap in a second file is a second
  // number to keep in step.

  /// Decelerating, no overshoot. A console is not a toy: things arrive and
  /// settle, they do not bounce.
  static const Curve curve = Curves.easeOutCubic;

  /// How far an arriving element travels, in logical pixels.
  ///
  /// Deliberately NOT scaled with `.h`, following `Entrance`: this is a motion
  /// distance, not a layout measurement, and scaling it with the design canvas
  /// makes the same animation feel different on a bigger screen. 10 against
  /// `Entrance`'s own default of 18 — the console is denser than the phone,
  /// and a card that travels 18 next to a stat tile that does not reads as a
  /// jump.
  static const double rise = 10;
}

/// A [Column] whose children arrive one after another.
///
/// A drop-in replacement for the `Column` at the top of a dashboard page:
/// same children, same layout, each one wrapped in an [Entrance] carrying its
/// own index.
///
/// THE ANIMATION IS NOT MINE
/// -------------------------
/// This delegates to `Entrance` in `102-custom_entrance.dart`, which the
/// mobile home screen has used since day one. I wrote a second, identical
/// widget here first — same fade, same lift, same easeOutCubic, same one-shot
/// with a mounted guard on the delay — and deleted it once I found the
/// original. Two primitives doing one job is how the console and the phone app
/// end up animating differently for no reason anyone can name.
///
/// What this adds on top is the CONSOLE'S timings ([AppMotion]) and the
/// bookkeeping a page-level column needs: spacers skipped, flex children
/// handled.
class AnimateInList extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  /// Defaults to [MainAxisSize.max] because `Column` does.
  ///
  /// This widget is meant to be swapped in for a `Column` by changing one
  /// word, so every default it has must match Column's. `min` here would
  /// silently make four pages shrink-wrap where they used to fill.
  final MainAxisSize mainAxisSize;

  final bool enabled;

  /// Stagger index the first child gets. Lets a page that has already animated
  /// something above the list continue the sequence rather than restart it.
  final int startStep;

  const AnimateInList({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.max,
    this.enabled = true,
    this.startStep = 0,
  });

  /// True for the widgets that are spacing rather than content. Animating a
  /// bare `SizedBox` costs a controller and shows nothing, and it would make
  /// the stagger count gaps as if they were cards.
  static bool _isSpacer(Widget child) =>
      child is SizedBox && child.child == null;

  @override
  Widget build(BuildContext context) {
    int step = startStep;

    Widget entrance(Widget child) => Entrance(
          index: step++,
          offset: AppMotion.rise,
          duration: AppMotion.entrance,
          stagger: AppMotion.stagger,
          child: child,
        );

    // `Expanded` and `Flexible` are ParentDataWidgets: they have to be the
    // DIRECT child of the Column or Flutter throws "Incorrect use of
    // ParentDataWidget" at runtime. Wrapping one would break every page that
    // fills its remaining height with a table — which is four of the six. So
    // the flex stays where it is and the animation goes INSIDE it.
    Widget wrap(Widget child) {
      if (_isSpacer(child)) return child;
      if (!enabled) return child;

      if (child is Flexible) {
        return Flexible(
          flex: child.flex,
          fit: child.fit,
          child: entrance(child.child),
        );
      }

      return entrance(child);
    }

    final List<Widget> wrapped = <Widget>[
      for (final Widget child in children) wrap(child),
    ];

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      // A Column holding a flex child must be allowed to fill: MainAxisSize
      // .min with an Expanded inside is a contradiction Flutter resolves by
      // ignoring one of them. Detected rather than asked for, because it is
      // not a decision any caller should have to remember.
      mainAxisSize: children.any((Widget c) => c is Flexible)
          ? MainAxisSize.max
          : mainAxisSize,
      children: wrapped,
    );
  }
}

/// A number that travels to its new value instead of jumping to it.
///
/// [format] turns the running value into the string on screen, so the caller
/// keeps control of currency, grouping and Arabic-Indic digits — this widget
/// knows about motion and nothing else.
///
/// Unlike an entrance animation this DOES re-run: whenever [value] changes it
/// animates from wherever it is to the new number. That is the behaviour that
/// makes a live dashboard feel live — an order lands, the tile moves.
class AnimatedCount extends StatelessWidget {
  final num value;
  final String Function(num value) format;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Passed straight to the [Text]. The pipeline's count boxes rely on it to
  /// sit a digit dead-centre in a 45pt circle, and losing it here would move
  /// every number a pixel or two off centre.
  final TextHeightBehavior? textHeightBehavior;

  /// Set false to print [value] with no animation.
  final bool enabled;

  const AnimatedCount({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.textHeightBehavior,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Text(
        FormatHelper.capitalize(format(value)),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        textHeightBehavior: textHeightBehavior,
      );
    }

    return TweenAnimationBuilder<double>(
      // `TweenAnimationBuilder` re-targets from its CURRENT value when the end
      // changes, so a number that updates mid-flight continues smoothly rather
      // than snapping back to zero and starting again.
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: AppMotion.count,
      curve: AppMotion.curve,
      builder: (BuildContext context, double running, Widget? _) {
        return Text(
          FormatHelper.capitalize(format(running)),
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          textHeightBehavior: textHeightBehavior,
        );
      },
    );
  }
}

/// Cross-fades and lifts its child whenever [section] changes.
///
/// WHY NOT AnimatedSwitcher
/// ------------------------
/// The console keeps its pages in an `IndexedStack` on purpose: switching
/// section preserves each page's scroll position and its open Firestore
/// subscription, and tearing a live query down and rebuilding it on every tab
/// change is both slower and more expensive.
///
/// `AnimatedSwitcher` would undo exactly that. It animates between two
/// DIFFERENT children, so it would need a new `IndexedStack` per section, and
/// disposing the old one takes every page's state and every listener with it.
///
/// This keeps ONE child — the same `IndexedStack` instance, untouched — and
/// animates the box around it. The transition is free, and nothing below it
/// even knows it happened.
class SectionTransition extends StatefulWidget {
  /// Anything that changes when the page changes; an enum value, an index.
  final Object section;

  final Widget child;

  const SectionTransition({
    super.key,
    required this.section,
    required this.child,
  });

  @override
  State<SectionTransition> createState() => _SectionTransitionState();
}

class _SectionTransitionState extends State<SectionTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.section,
    // Starts settled: the first page the console shows has already arrived,
    // and fading it in behind the sign-in transition just looks like a stall.
    value: 1,
  );

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.curve,
  );

  @override
  void didUpdateWidget(SectionTransition old) {
    super.didUpdateWidget(old);
    if (old.section != widget.section) {
      // From zero every time, not `reverse().then(forward())`: a fade-out
      // followed by a fade-in doubles the duration and shows the user a blank
      // panel in between. The new page simply arrives.
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _t.value,
          child: Transform.translate(
            // Half the rise of a single card. The whole page moving as far as
            // one card does reads as the window itself shifting.
            offset: Offset(0, (1 - _t.value) * (AppMotion.rise / 2).h),
            child: child,
          ),
        );
      },
    );
  }
}
