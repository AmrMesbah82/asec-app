/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 113-custom_circular_menu.dart
/// Purpose: Declares `CustomCircularMenu` and `CircularMenuItem` — a round
///          "speed dial" that fans its items out in an arc around the spot
///          that was tapped (like the `circular_menu` package).
/// Author: ASEC team
/// Created: 21/10/2026
/// Updated: 22/10/2026 - Radius 104 → 150 so the bubbles and their labels
///          sit further from the centre button and from each other.
/// Updated: 22/10/2026 - Optional `sweep` (radians) on `show`, so the phone
///          bar's centre button can fan its tools in a narrower arc that
///          stays above the bar.
/// Updated: 22/10/2026 - `vertical: true` — a speed dial: the items stack
///          straight up from the anchor, each a round icon with its name in
///          a pill beside it (the phone bar's centre Calculators button).
///          The list is centred on the screen and the ✕ is drawn exactly on
///          the button that opened it, at the same size.
///
/// ```dart
/// final int? picked = await CustomCircularMenu.show(
///   context: context,
///   anchor: rectOfTheTappedButton,
///   items: const <CircularMenuItem>[
///     CircularMenuItem(icon: Icons.calculate_rounded, label: 'Converter'),
///     CircularMenuItem(icon: Icons.air_rounded, label: 'Ducts'),
///   ],
///   selected: 0,
/// );
/// ```
///
/// The arc always opens TOWARDS THE MIDDLE OF THE SCREEN, so the same menu
/// opens upwards from the phone's bottom bar and sideways from the rail /
/// drawer, in LTR and RTL alike. Tapping outside or the centre ✕ closes it
/// and returns null.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';

/// One choice of [CustomCircularMenu].
class CircularMenuItem {
  const CircularMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class CustomCircularMenu {
  const CustomCircularMenu._();

  /// Diameter of each item bubble.
  static const double itemSize = 54;

  /// Diameter of the centre (close) button.
  static const double centerSize = 58;

  /// Distance from the centre to each item.
  static const double radius = 150;

  /// Opens the menu around [anchor] (global coordinates of the tapped
  /// control). Returns the picked item's index, or null when dismissed.
  static Future<int?> show({
    required BuildContext context,
    required Rect anchor,
    required List<CircularMenuItem> items,
    int? selected,
    double? sweep,
    bool vertical = false,
  }) {
    return showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation,
              Animation<double> _) =>
          _CircularMenuOverlay(
        anchor: anchor,
        items: items,
        selected: selected,
        animation: animation,
        sweep: sweep,
        vertical: vertical,
      ),
    );
  }

  /// The global rectangle of the widget that owns [context].
  static Rect rectOf(BuildContext context) {
    final RenderObject? ro = context.findRenderObject();
    if (ro is RenderBox && ro.hasSize) {
      return ro.localToGlobal(Offset.zero) & ro.size;
    }
    final Size screen = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(screen.width / 2, screen.height - 60),
      width: 1,
      height: 1,
    );
  }
}

class _CircularMenuOverlay extends StatelessWidget {
  const _CircularMenuOverlay({
    required this.anchor,
    required this.items,
    required this.selected,
    required this.animation,
    this.sweep,
    this.vertical = false,
  });

  /// Speed-dial column above the anchor instead of an arc.
  final bool vertical;

  /// Centre-to-centre distance between rows of the vertical list.
  static const double _rowGap = CustomCircularMenu.itemSize + 14;

  /// Total arc in radians; null = 60° between neighbours, half a circle max.
  final double? sweep;

  final Rect anchor;
  final List<CircularMenuItem> items;
  final int? selected;
  final Animation<double> animation;

  /// Item centres, before animation, kept inside the safe screen area.
  List<Offset> _targets(Offset c, Size screen, EdgeInsets pad) {
    final Offset toMiddle = Offset(screen.width / 2, screen.height / 2) - c;
    final double base = toMiddle.distance < 1
        ? -math.pi / 2
        : math.atan2(toMiddle.dy, toMiddle.dx);
    final int n = items.length;
    // 60° between neighbours, never more than a half circle in total.
    final double sweep = n <= 1
        ? 0
        : (this.sweep ?? math.min(math.pi, (n - 1) * math.pi / 3));
    const double margin = CustomCircularMenu.itemSize / 2 + 8;
    return <Offset>[
      for (int i = 0; i < n; i++)
        () {
          final double a = n <= 1 ? base : base - sweep / 2 + sweep * i / (n - 1);
          final Offset p = c +
              Offset(math.cos(a), math.sin(a)) * CustomCircularMenu.radius;
          return Offset(
            p.dx.clamp(margin + pad.left, screen.width - margin - pad.right),
            // Room under each bubble for its label.
            p.dy.clamp(margin + pad.top, screen.height - margin - 30 - pad.bottom),
          );
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final EdgeInsets pad = MediaQuery.paddingOf(context);
    // Vertical (the phone bar's centre button): the ✕ takes the button's own
    // size and sits exactly on it.
    final double centerSize =
        vertical ? anchor.shortestSide : CustomCircularMenu.centerSize;
    final double half = centerSize / 2;
    final Offset center = vertical ? anchor.center : Offset(
      anchor.center.dx.clamp(half + 8, screen.width - half - 8),
      anchor.center.dy.clamp(half + 8 + pad.top, screen.height - half - 8),
    );
    final List<Offset> targets =
        vertical ? const <Offset>[] : _targets(center, screen, pad);

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? _) {
        final double t = Curves.easeOutBack.transform(animation.value.clamp(0.0, 1.0));
        final double fade = animation.value.clamp(0.0, 1.0);

        // showGeneralDialog adds no Material: without this, every Text
        // here gets Flutter's yellow double underline.
        return Material(
          type: MaterialType.transparency,
          child: Stack(
          children: <Widget>[
            // Vertical: rows rise one after another, icon + name beside it.
            if (vertical) _speedDial(context, screen, center, centerSize),
            // Items, flying out from the centre.
            if (!vertical)
            for (int i = 0; i < items.length; i++)
              _place(
                Offset.lerp(center, targets[i], t)!,
                Opacity(
                  opacity: fade,
                  child: _ItemBubble(
                    item: items[i],
                    selected: i == selected,
                    onTap: () => Navigator.of(context).pop(i),
                  ),
                ),
                width: 104,
                // No height: the bubble + its label size themselves, so a
                // bigger font or a two-word label can never overflow.
                height: null,
                alignTop: true,
              ),
            // The centre button: ✕ that turns in as the menu opens.
            _place(
              center,
              Transform.rotate(
                angle: (1 - fade) * math.pi / 2,
                child: _CenterButton(onTap: () => Navigator.of(context).pop()),
              ),
              width: centerSize,
              height: centerSize,
            ),
          ],
          ),
        );
      },
    );
  }

  /// The vertical list: one block, CENTRED on the screen, standing just above
  /// the centre button. Every row is as wide as the widest, so the circles
  /// line up in one column and the names start on one line. Rows rise out of
  /// the button one after another, nearest first.
  Widget _speedDial(
    BuildContext context,
    Size screen,
    Offset center,
    double centerSize,
  ) {
    const double gap = 14;
    final double labelMax =
        screen.width - 32 - CustomCircularMenu.itemSize - 10;
    final int n = items.length;
    return Positioned(
      left: 16,
      right: 16,
      bottom: screen.height - (center.dy - centerSize / 2 - gap),
      child: Center(
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Item 0 at the bottom, nearest the button.
              for (int i = n - 1; i >= 0; i--)
                Builder(builder: (BuildContext _) {
                  final double start = (i * 0.08).clamp(0.0, 0.6);
                  final double raw =
                      ((animation.value - start) / (1 - start)).clamp(0.0, 1.0);
                  final double t = Curves.easeOutBack.transform(raw);
                  final double drop = _rowGap * (i + 1);
                  return Padding(
                    padding: EdgeInsets.only(top: i == n - 1 ? 0 : gap),
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * drop),
                      child: Opacity(
                        opacity: raw,
                        child: _ItemRow(
                          item: items[i],
                          selected: i == selected,
                          labelMaxWidth: labelMax,
                          onTap: () => Navigator.of(context).pop(i),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  /// Positions [child] so that its circle is centred on [p].
  Widget _place(
    Offset p,
    Widget child, {
    required double width,
    required double? height,
    bool alignTop = false,
  }) {
    final double top = alignTop || height == null
        ? p.dy - CustomCircularMenu.itemSize / 2
        : p.dy - height / 2;
    return Positioned(
      left: p.dx - width / 2,
      top: top,
      width: width,
      height: height,
      child: child,
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(
          child: Icon(Icons.close_rounded, color: AppColors.textButton, size: 28),
        ),
      ),
    );
  }
}

class _ItemBubble extends StatelessWidget {
  const _ItemBubble({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CircularMenuItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: CustomCircularMenu.itemSize,
          height: CustomCircularMenu.itemSize,
          child: Material(
            color: selected ? AppColors.primary : AppColors.card,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: AppIcon(
                  item.icon,
                  size: 24,
                  color: selected ? AppColors.textButton : AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            FormatHelper.capitalize(item.label),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: StyleText.fontSize11Weight600.copyWith(color: AppColors.text),
          ),
        ),
      ],
    );
  }
}


/// A speed-dial row: the round icon, then its name in a pill.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.selected,
    required this.labelMaxWidth,
    required this.onTap,
  });

  final CircularMenuItem item;
  final bool selected;
  final double labelMaxWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: CustomCircularMenu.itemSize,
            height: CustomCircularMenu.itemSize,
            child: Material(
              color: selected ? AppColors.primary : AppColors.card,
              shape: const CircleBorder(),
              elevation: 4,
              child: Center(
                child: AppIcon(
                  item.icon,
                  size: 24,
                  color: selected ? AppColors.textButton : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: labelMaxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                FormatHelper.capitalize(item.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize14Weight600.copyWith(
                  color: selected ? AppColors.primary : AppColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
