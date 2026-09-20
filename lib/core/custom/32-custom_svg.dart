/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: custom_svg_image.dart
/// Purpose: Declares `CustomSvgImage`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The single entry point for rendering SVG assets.
///
/// Nothing outside this file should call [SvgPicture] directly — that keeps
/// sizing, tinting and fit behaviour consistent across the app, and gives us
/// one place to adapt if flutter_svg's API shifts again.
///
/// Sizing:
///  * [CustomSvgImage] falls back to 12.sp when no width/height is given.
///  * [CustomSvgImage.natural] renders at the asset's own intrinsic size instead.
///
/// Tinting: pass [color] to tint the whole glyph (equivalent to the old
/// `SvgPicture.color`), or [colorFilter] for full control. [colorFilter] wins
/// when both are supplied. A null tint leaves the asset's own colours intact.
class CustomSvgImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final ColorFilter? colorFilter;
  final Alignment alignment;
  final String? semanticsLabel;

  /// When true, width/height fall through as null so the asset renders at its
  /// intrinsic size rather than the 12.sp default.
  final bool useNaturalSize;

  const CustomSvgImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.scaleDown,
    this.color,
    this.colorFilter,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : useNaturalSize = false;

  /// Renders at the asset's intrinsic size. Any [width]/[height] passed here is
  /// still honoured; omitting them means "whatever the asset declares".
  const CustomSvgImage.natural({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.colorFilter,
    this.alignment = Alignment.center,
    this.semanticsLabel,
  }) : useNaturalSize = true;

  ColorFilter? get _filter {
    if (colorFilter != null) return colorFilter;
    if (color != null) return ColorFilter.mode(color!, BlendMode.srcIn);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: useNaturalSize ? width : (width ?? 12.sp),
      height: useNaturalSize ? height : (height ?? 12.sp),
      fit: fit,
      alignment: alignment,
      colorFilter: _filter,
      semanticsLabel: semanticsLabel,
    );
  }
}
