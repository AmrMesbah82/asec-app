/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 101-custom_surface.dart
/// Purpose: Declares `AppCard`, `AppSectionHeader`, `AppStatusChip`,
///          `AppIconBadge` and `AppStatCard` — the console's surfaces.
/// Author: Manger Plus team
/// Created: 3/9/2026
///
/// THE ONE RULE
/// ------------
/// Nothing in this app draws a border. A panel is a fill (`AppColors.card`) at
/// radius 8 with the Figma 2% drop shadow, sitting on the page fill
/// (`AppColors.background`). The two-value contrast between them IS the edge.
///
/// This matters more in dark mode than in light: `AppColors.border` is
/// `Colors.transparent` there, so every `Border.all(color: AppColors.border)`
/// in the old console drew an edge in light mode and nothing in dark — the two
/// themes were not the same design. A fill reads identically in both.
///
/// EMPHASIS WITHOUT OUTLINES
/// -------------------------
/// Where a border used to carry meaning, one of these carries it instead:
///   * a background TINT of the meaning colour at 12–18% (status chips),
///   * a filled ICON BADGE beside the value (stat cards),
///   * a solid 3px LEADING BAR (the selected rail item).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/104-custom_motion.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// Standard CONTAINER corner radius, kept as an alias so the call sites that
/// already read `kAppRadius` do not all have to change. The number itself
/// lives in [AppRadius] with the other two — see that file for the rule.
const double kAppRadius = AppRadius.container;

/// Radius of the app's icon badge — the circle an icon lives in.
///
/// Every identity icon in the product sits in one of these: a solid
/// `AppColors.primary` circle of radius 25.sp, with whatever is inside it drawn
/// in `AppColors.textButton`. Before 4/9/2026 each screen invented its own
/// container — a 40.sp square at radius 12 on the service tiles, 38 at radius
/// 10 on the order rows, 32 at radius 9 in settings, 34 at radius 8 in the
/// console headers — four shapes for one idea.
///
/// This is the RADIUS, so the box is twice it. Use [kAppBadgeSize] for the box.
const double kAppBadgeRadius = 25;

/// Diameter of [AppIconBadge] — `kAppBadgeRadius * 2`.
const double kAppBadgeSize = kAppBadgeRadius * 2;

/// The app's card gradient: the card colour washing into a hint of brand.
///
/// `Color.alphaBlend` rather than a translucent stop, on purpose. A gradient
/// ending in `primary.withOpacity(.18)` composites against whatever happens to
/// be BEHIND the card, so the same card looked different over the page fill
/// than it did over a sheet, and in dark mode it muddied. Blending the tint
/// into `AppColors.card` up front gives one opaque colour that is correct in
/// both themes and on any ground.
LinearGradient appCardGradient({double strength = 0.18}) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        AppColors.card,
        Color.alphaBlend(AppColors.primary.withOpacity(strength), AppColors.card),
      ],
    );

/// An ink colour that is actually readable when [meaning] is used as a tint.
///
/// WHY THIS IS NEEDED
/// ------------------
/// The status palette is now brand-only, and the brand primary is #FFDE59 — a
/// pale yellow. Drawing pale yellow text on a 14% pale-yellow tint gives a chip
/// nobody can read. The fill still carries the meaning; the ink falls back to
/// the body colour whenever the meaning colour is too light to be type.
///
/// 0.6 is the cut: #FFDE59 sits around 0.77, #E5B800 around 0.51, and the reds
/// and greys are far below.
Color readableInk(Color meaning) =>
    meaning.computeLuminance() > 0.6 ? AppColors.text : meaning;

/// The same decision for a SOLID fill of [meaning] rather than a tint of it.
Color readableOn(Color meaning) =>
    meaning.computeLuminance() > 0.6 ? AppColors.text : AppColors.white;

/// The panel every console section is built out of.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.caption,
    this.leadingAsset,
    this.actions = const <Widget>[],
    this.padding,
    this.color,
    this.gradient,
    this.radius,
    this.shadow = true,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
  });

  final Widget child;
  final String? title;
  final String? caption;

  /// SVG shown in a tinted badge to the left of [title]. Null keeps the header
  /// text-only, which is right for a card whose title is already unambiguous.
  final String? leadingAsset;

  final List<Widget> actions;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  /// Fills the card with a gradient instead of a flat [color]. Pass
  /// `appCardGradient()` for the house wash.
  final Gradient? gradient;

  final double? radius;
  final bool shadow;
  final CrossAxisAlignment crossAxisAlignment;

  /// `min` (the default) sizes the card to its content. Pass `max` when the
  /// card is given a bounded height by its parent AND its child uses
  /// `Expanded` — a flex child inside a `min` column throws.
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    final bool hasHeader = title != null;

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 20.sp),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular((radius ?? kAppRadius).sp),
        boxShadow: shadow
            ? <BoxShadow>[
                // Figma: (-3, 4), blur 20, black 2%. Deliberately almost
                // invisible — it separates the card from the page without
                // reading as a raised object.
                BoxShadow(
                  color: AppColors.totalBlack.withOpacity(0.02),
                  offset: Offset(-3.w, 4.h),
                  blurRadius: 20.r,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: <Widget>[
          if (hasHeader) ...<Widget>[
            AppSectionHeader(
              title: title!,
              caption: caption,
              leadingAsset: leadingAsset,
              actions: actions,
            ),
            SizedBox(height: 16.sp),
          ],
          child,
        ],
      ),
    );
  }
}

/// Title, optional caption, optional leading badge, right-aligned actions.
/// Used inside [AppCard] and standalone above a grid that has no card of its own.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.caption,
    this.leadingAsset,
    this.actions = const <Widget>[],
    this.titleStyle,
  });

  final String title;
  final String? caption;
  final String? leadingAsset;
  final List<Widget> actions;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (leadingAsset != null) ...<Widget>[
          AppIconBadge(assetPath: leadingAsset!),
          SizedBox(width: 10.sp),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                FormatHelper.capitalize(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (titleStyle ?? StyleText.fontSize16Weight600)
                    .copyWith(color: AppColors.text),
              ),
              if (caption != null) ...<Widget>[
                SizedBox(height: 2.sp),
                Text(
                  FormatHelper.capitalize(caption!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StyleText.fontSize11Weight400
                      .copyWith(color: AppColors.secondaryText),
                ),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

/// An SVG in a solid brand circle — the app's ONE way of presenting an icon
/// that stands for something (a service, a section, a setting, a metric).
///
/// THE RULE
/// --------
/// Circle of radius [kAppBadgeRadius], filled `AppColors.primary`, and anything
/// drawn inside it — glyph or initials — in `AppColors.textButton`. That is
/// deliberately not negotiable per screen: an icon badge should be recognisable
/// as the same object wherever it appears, and the brand yellow is what makes
/// it recognisable.
///
/// WHERE IT DOES NOT APPLY
/// -----------------------
///  * Toolbar CONTROLS (filter, sort, the view toggle, row actions). Those are
///    buttons, not badges: they are square, they take a label, and their fill
///    already means "active".
///  * Any badge sitting ON a primary surface — the gradient order card, the
///    selected rail item. A primary circle on a primary ground is invisible;
///    those keep a contrasting treatment, which is why [background] and
///    [foreground] exist at all.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.assetPath,
    this.size,
    this.iconSize,
    this.background,
    this.foreground,
  });

  final String assetPath;

  /// Diameter of the circle. Defaults to [kAppBadgeSize] (radius 25.sp). Pass a
  /// smaller value only where a 50.sp circle genuinely will not fit — inside a
  /// table row, for instance.
  final double? size;

  /// Glyph size. Defaults to 44% of the circle, which keeps a comfortable ring
  /// of colour around the artwork at every diameter.
  final double? iconSize;

  /// Override the fill. See "where it does not apply" above — this is for the
  /// handful of badges that sit on a primary ground, not a per-screen accent.
  final Color? background;

  /// Override the ink. Defaults to `AppColors.textButton`.
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final double box = size ?? kAppBadgeSize.sp;

    // No circle behind the glyph any more — the SVG alone, in the brand
    // colour, centred in the same box so surrounding layouts do not shift.
    return SizedBox(
      width: box,
      height: box,
      child: Center(
        child: CustomSvgImage(
          assetPath: assetPath,
          width: iconSize ?? (box * 0.7),
          height: iconSize ?? (box * 0.7),
          color: foreground ?? AppColors.primary,
        ),
      ),
    );
  }
}

/// The same circle carrying TEXT rather than a glyph — initials, a count.
/// Kept beside [AppIconBadge] so the two can never drift apart.
class AppTextBadge extends StatelessWidget {
  const AppTextBadge({
    super.key,
    required this.text,
    this.size,
    this.textStyle,
    this.background,
    this.foreground,
  });

  final String text;
  final double? size;
  final TextStyle? textStyle;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final double box = size ?? kAppBadgeSize.sp;

    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        FormatHelper.capitalize(text),
        maxLines: 1,
        style: (textStyle ?? StyleText.fontSize14Weight700)
            .copyWith(color: foreground ?? AppColors.textButton),
      ),
    );
  }
}

/// A status word on a tint of its own colour, with the status glyph.
///
/// This replaces the old outlined pill. The tint is the signal, so the chip
/// stays legible on a card, on a zebra row and inside a selected row, none of
/// which a 1px coloured outline manages.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.assetPath,
    this.count,
    this.active = false,
    this.onTap,
    this.dense = false,
  });

  final String label;
  final Color color;
  final String? assetPath;

  /// Optional trailing number — the pill row on the overview page uses it.
  final int? count;

  /// Filled rather than tinted. Marks the chip that is currently filtering.
  final bool active;

  final VoidCallback? onTap;

  /// Tighter padding and no glyph — for chips inside table rows, where a full
  /// chip would set the row height.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    // Inactive: the shared chip ground and ink (AppColors.chip / onChip) —
    // never a tint of the status colour. Active (the chip that is filtering
    // or selected): the brand primary. [color] no longer paints the chip;
    // the word says the state.
    final Color background = active ? AppColors.primary : AppColors.chip;
    final Color content = active ? AppColors.textButton : AppColors.onChip;

    final Widget chip = Container(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.h,
        vertical: dense ? 4.sp : 8.sp),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(kAppRadius.sp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (assetPath != null && !dense) ...<Widget>[
            CustomSvgImage(
              assetPath: assetPath!,
              width: 14.sp,
              height: 14.sp,
              color: content,
            ),
            SizedBox(width: 6.sp),
          ],
          Text(
            FormatHelper.capitalize(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (dense
                    ? StyleText.fontSize11Weight600
                    : StyleText.fontSize12Weight600)
                .copyWith(color: content),
          ),
          if (count != null) ...<Widget>[
            SizedBox(width: 8.sp),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 1.sp),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.white.withOpacity(0.25)
                    : AppColors.card,
                borderRadius: AppRadius.buttonR,
              ),
              child: Text(
                FormatHelper.capitalize('$count'),
                style: StyleText.fontSize11Weight700.copyWith(color: content),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: chip),
    );
  }
}

/// One headline number: badge, label, value, optional supporting line.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.assetPath,
    required this.label,
    required this.value,
    this.caption,
    this.onTap,
    this.countTo,
    this.format,
  });

  final String assetPath;
  final String label;

  /// The finished string. Used as-is unless [countTo] and [format] are both
  /// given, and always the fallback — a card that cannot count still shows
  /// its number.
  final String value;

  final String? caption;
  final VoidCallback? onTap;

  /// ADDED 8/9/2026 — the number behind [value], for the count-up.
  ///
  /// The card cannot animate a String: "48,661 EGP" is a currency, a
  /// thousands separator and a unit, and there is no honest way to interpolate
  /// halfway through one. So the caller passes the RAW number here and the
  /// formatter that turns it into the string in [format], and the card runs
  /// the number while the caller keeps ownership of how it reads — including
  /// Arabic-Indic digits, which a generic implementation would flatten.
  ///
  /// Both must be given, or neither. One alone falls back to [value].
  final num? countTo;

  /// Renders the running value. See [countTo].
  final String Function(num value)? format;

  @override
  Widget build(BuildContext context) {
    // REMOVED 4/9/2026: this took a `tint` and gave each stat card's badge its
    // own colour. Badges are brand circles now — see [AppIconBadge].
    final Widget card = AppCard(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 18.sp),
      crossAxisAlignment: CrossAxisAlignment.start,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIconBadge(assetPath: assetPath),
              SizedBox(width: 10.sp),
              Expanded(
                child: Text(
                  FormatHelper.capitalize(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StyleText.fontSize12Weight500
                      .copyWith(color: AppColors.secondaryText),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.sp),
          // The value is the point of the card, so it shrinks to fit rather
          // than ellipsising: "12,4…" is worse than a slightly smaller number.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: (countTo != null && format != null)
                ? AnimatedCount(
                    value: countTo!,
                    format: format!,
                    style: StyleText.fontSize28Weight600
                        .copyWith(color: AppColors.text),
                  )
                : Text(
                    FormatHelper.capitalize(value),
                    style: StyleText.fontSize28Weight600
                        .copyWith(color: AppColors.text),
                  ),
          ),
          if (caption != null) ...<Widget>[
            SizedBox(height: 4.sp),
            Text(
              FormatHelper.capitalize(caption!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StyleText.fontSize11Weight400
                  .copyWith(color: AppColors.secondaryText),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}

/// "label: value" line with a leading glyph — the body of every detail panel
/// and record card.
class AppFieldRow extends StatelessWidget {
  const AppFieldRow({
    super.key,
    required this.label,
    required this.value,
    this.assetPath,
    this.valueColor,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final String? assetPath;
  final Color? valueColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (assetPath != null) ...<Widget>[
            Padding(
              padding: EdgeInsets.only(top: 2.sp),
              child: CustomSvgImage(
                assetPath: assetPath!,
                width: 15.sp,
                height: 15.sp,
                color: AppColors.secondaryText,
              ),
            ),
            SizedBox(width: 8.sp),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label  ',
                style: StyleText.fontSize13Weight400
                    .copyWith(color: AppColors.secondaryText),
                children: <InlineSpan>[
                  TextSpan(
                    text: value,
                    style: StyleText.fontSize13Weight500
                        .copyWith(color: valueColor ?? AppColors.text),
                  ),
                ],
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
