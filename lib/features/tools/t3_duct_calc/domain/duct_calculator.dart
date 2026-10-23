/// Module: tools / t3_duct_calc
///
///*************************** FILE INFO ****************************///
/// File Name: duct_calculator.dart
/// Purpose: The metric "Ductulator" maths — round duct table, rectangular
///          duct, bend losses and volume-flow conversions.
/// Author: ASEC team
/// Created: 21/10/2026
///
/// Pure Dart, no Flutter, works offline. Matches the original FDuct.exe
/// to within 0.02 %:
///   • air: ρ = 1.204 kg/m³, ν = 1.484e-5 m²/s (20 °C)
///   • friction factor: Swamee–Jain
///       f = 0.25 / [log10(ε/(3.7·D) + 5.74/Re^0.9)]²
///     ε = 0.1 mm (spiral) or 3.0 mm (flexible, fully extended)
///   • ΔP/L = f/D · ρV²/2,  total ΔP = ΔP/L × length
///   • rectangular: De = 1.265·[(a·b)³/(a+b)]^0.2; friction is that of a
///     round duct of De carrying the same flow, while velocity and velocity
///     pressure use the real a×b area
///   • bend loss = C · Pv with C = C90 × K(angle);
///       C90 = 0.72 / 0.22 (R/D 0.5 / 1) for D < 300 mm,
///       C90 = 0.96 / 0.37 for D ≥ 300 mm;
///       K = 1, 0.78, 0.60, 0.45 for 90°, 60°, 45°, 30°.
library;

import 'dart:math' as math;

import 'package:asec/features/tools/t3_duct_calc/domain/duct_data.dart';

/// Air properties used by the metric duct tables.
class DuctAir {
  const DuctAir._();

  /// Density, kg/m³.
  static const double density = 1.204;

  /// Kinematic viscosity, m²/s.
  static const double kinematicViscosity = 1.484e-5;
}

/// One row of the round duct table.
class RoundDuctRow {
  const RoundDuctRow({
    required this.diameterMm,
    required this.velocity,
    required this.pressureDropPerMetre,
    required this.totalPressureDrop,
    required this.velocityPressure,
    required this.bendLosses,
  });

  final int diameterMm;

  /// m/s
  final double velocity;

  /// Pa/m
  final double pressureDropPerMetre;

  /// Pa (over the entered length)
  final double totalPressureDrop;

  /// Pa
  final double velocityPressure;

  /// Pa, one per [kBendTypes] entry. Null for flexible duct.
  final List<double>? bendLosses;
}

/// Result of the rectangular duct calculation.
class RectDuctResult {
  const RectDuctResult({
    required this.equivalentDiameterMm,
    required this.velocity,
    required this.pressureDropPerMetre,
    required this.totalPressureDrop,
    required this.velocityPressure,
  });

  final double equivalentDiameterMm;
  final double velocity;
  final double pressureDropPerMetre;
  final double totalPressureDrop;
  final double velocityPressure;
}

class DuctCalculator {
  const DuctCalculator._();

  /// Swamee–Jain explicit friction factor.
  static double frictionFactor({
    required double reynolds,
    required double roughnessM,
    required double diameterM,
  }) {
    if (reynolds <= 0 || diameterM <= 0) return 0;
    final double x = math.log(
          roughnessM / (3.7 * diameterM) + 5.74 / math.pow(reynolds, 0.9),
        ) /
        math.ln10;
    return 0.25 / (x * x);
  }

  /// Velocity pressure ρV²/2, Pa.
  static double velocityPressure(double velocity) =>
      DuctAir.density * velocity * velocity / 2;

  /// Friction pressure drop per metre (Pa/m) for a round duct.
  static double roundPressureDropPerMetre({
    required double flowM3s,
    required double diameterM,
    required double roughnessM,
  }) {
    if (flowM3s <= 0 || diameterM <= 0) return 0;
    final double area = math.pi * diameterM * diameterM / 4;
    final double v = flowM3s / area;
    final double re = v * diameterM / DuctAir.kinematicViscosity;
    final double f = frictionFactor(
      reynolds: re,
      roughnessM: roughnessM,
      diameterM: diameterM,
    );
    return f / diameterM * velocityPressure(v);
  }

  /// 90° bend coefficient for a round duct of [diameterMm].
  static double bend90Coefficient(double diameterMm, double radiusRatio) {
    final bool small = diameterMm < 300;
    if (radiusRatio <= 0.5) return small ? 0.72 : 0.96;
    return small ? 0.22 : 0.37;
  }

  /// Angle correction applied to the 90° coefficient.
  static double bendAngleFactor(int angleDeg) {
    switch (angleDeg) {
      case 90:
        return 1.0;
      case 60:
        return 0.78;
      case 45:
        return 0.60;
      case 30:
        return 0.45;
      default:
        return angleDeg / 90.0;
    }
  }

  /// Bend loss coefficient C for [bend] in a duct of [diameterMm].
  static double bendCoefficient(double diameterMm, BendType bend) =>
      bend90Coefficient(diameterMm, bend.radiusRatio) *
      bendAngleFactor(bend.angleDeg);

  /// The full round duct table for every standard diameter.
  ///
  /// [flowLs] in l/s, [lengthM] in metres.
  static List<RoundDuctRow> roundTable({
    required double flowLs,
    required double lengthM,
    required RoundDuctType type,
    List<int> diametersMm = kStandardRoundDiametersMm,
  }) {
    final double q = flowLs / 1000.0;
    return <RoundDuctRow>[
      for (final int dMm in diametersMm)
        _roundRow(q: q, dMm: dMm, lengthM: lengthM, type: type),
    ];
  }

  static RoundDuctRow _roundRow({
    required double q,
    required int dMm,
    required double lengthM,
    required RoundDuctType type,
  }) {
    final double d = dMm / 1000.0;
    final double v = q / (math.pi * d * d / 4);
    final double pv = velocityPressure(v);
    final double dpm = roundPressureDropPerMetre(
      flowM3s: q,
      diameterM: d,
      roughnessM: type.roughnessM,
    );
    return RoundDuctRow(
      diameterMm: dMm,
      velocity: v,
      pressureDropPerMetre: dpm,
      totalPressureDrop: dpm * lengthM,
      velocityPressure: pv,
      bendLosses: type == RoundDuctType.flexible
          ? null
          : <double>[
              for (final BendType b in kBendTypes)
                bendCoefficient(dMm.toDouble(), b) * pv,
            ],
    );
  }

  /// Equivalent diameter of an a×b rectangle (same units in and out).
  static double rectEquivalentDiameter(double a, double b) {
    if (a <= 0 || b <= 0) return 0;
    return 1.265 * math.pow(math.pow(a * b, 3) / (a + b), 0.2).toDouble();
  }

  /// Rectangular duct (galvanised, ε = 0.1 mm).
  ///
  /// [flowLs] l/s, sides in mm, [lengthM] metres.
  static RectDuctResult rectangular({
    required double flowLs,
    required double sideAMm,
    required double sideBMm,
    required double lengthM,
  }) {
    final double q = flowLs / 1000.0;
    final double a = sideAMm / 1000.0;
    final double b = sideBMm / 1000.0;
    final double de = rectEquivalentDiameter(a, b);
    final double v = q / (a * b);
    final double dpm = roundPressureDropPerMetre(
      flowM3s: q,
      diameterM: de,
      roughnessM: RoundDuctType.spiral.roughnessM,
    );
    return RectDuctResult(
      equivalentDiameterMm: de * 1000.0,
      velocity: v,
      pressureDropPerMetre: dpm,
      totalPressureDrop: dpm * lengthM,
      velocityPressure: velocityPressure(v),
    );
  }

  /// [value] in [from] expressed in every [FlowUnit].
  static Map<FlowUnit, double> convertFlow(double value, FlowUnit from) {
    final double m3s = value * from.toCubicMetresPerSecond;
    return <FlowUnit, double>{
      for (final FlowUnit u in FlowUnit.values)
        u: m3s / u.toCubicMetresPerSecond,
    };
  }
}
