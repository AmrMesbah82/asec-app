/// Module: tools / t4_pipe_calc
///
///*************************** FILE INFO ****************************///
/// File Name: pipe_calculator.dart
/// Purpose: The pipe sizer maths — pipe section properties and weights,
///          and the friction loss of a fluid flowing through it.
/// Author: ASEC team
/// Created: 22/10/2026
///
/// Pure Dart, works offline. Same method as McQuay PipeSizer 6.2
/// (verified against its screen), computed in IP units:
///   • ID = OD − 2·wall; areas, I = π(D⁴−d⁴)/64, S = I/(D/2), r = √(I/A)
///   • weight of pipe = 10.68·(OD − wall)·wall · ρ_material / ρ_steel (lb/ft)
///   • weight full = pipe + fluid in the bore
///   • V = Q / inside area;  Re = ρ·V·D/μ
///   • f = 64/Re below Re 2000, else Colebrook (ε by material)
///   • head loss = f·(100/D)·V²/2g  (ft per 100 ft)
///   • elbow loss = K·V²/2g (ft), K by size
///   • energy factor = ρ·cp·60/7.48 (Btu/h·°F per gpm)
/// [PipeSi] converts any of these for metric display.
library;

import 'dart:math' as math;

import 'package:asec/features/tools/t4_pipe_calc/domain/pipe_data.dart';

/// Everything the pipe sizer shows, in IP units.
class PipeResult {
  const PipeResult({
    required this.outsideDiameter,
    required this.wallThickness,
    required this.insideDiameter,
    required this.insideArea,
    required this.metalArea,
    required this.sectionModulus,
    required this.momentOfInertia,
    required this.radiusOfGyration,
    required this.weightOfPipe,
    required this.weightWithFluid,
    required this.velocity,
    required this.reynolds,
    required this.frictionFactor,
    required this.headLoss,
    required this.elbowLoss,
  });

  /// in
  final double outsideDiameter;
  final double wallThickness;
  final double insideDiameter;

  /// in²
  final double insideArea;
  final double metalArea;

  /// in³
  final double sectionModulus;

  /// in⁴
  final double momentOfInertia;

  /// in
  final double radiusOfGyration;

  /// lb/ft
  final double weightOfPipe;
  final double weightWithFluid;

  /// ft/s
  final double velocity;
  final double reynolds;
  final double frictionFactor;

  /// ft of fluid per 100 ft of pipe
  final double headLoss;

  /// ft of fluid, one elbow
  final double elbowLoss;
}

class PipeCalcException implements Exception {
  const PipeCalcException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PipeCalculator {
  const PipeCalculator._();

  static const double gravity = 32.174; // ft/s²
  static const double gallonsPerCubicFoot = 7.48052;
  static const double weightConstant = 10.68;
  static const double steelDensity = 0.282; // lb/in³

  /// Darcy friction factor: laminar below Re 2000, Colebrook above.
  static double frictionFactor(double re, double relativeRoughness) {
    if (re <= 0) return 0;
    if (re < 2000) return 64 / re;
    double f = 0.02;
    for (int i = 0; i < 100; i++) {
      final double x = -2 *
          math.log(relativeRoughness / 3.7 + 2.51 / (re * math.sqrt(f))) /
          math.ln10;
      final double next = 1 / (x * x);
      if ((next - f).abs() < 1e-9) return next;
      f = next;
    }
    throw const PipeCalcException('Friction not converged');
  }

  /// Energy factor ρ·cp·60/7.48, Btu/(h·°F) per gpm.
  static double energyFactor(PipeFluid fluid) =>
      fluid.densityLbFt3 * fluid.specificHeatBtuLbF * 60 / gallonsPerCubicFoot;

  /// Null when [type] is not made in [size] ("no data").
  static PipeResult? calculate({
    required PipeType type,
    required PipeSize size,
    required PipeFluid fluid,
    required double flowGpm,
  }) {
    final ({double od, double wall})? dims = size.dimensionsFor(type);
    if (dims == null) return null;
    final double od = dims.od;
    final double t = dims.wall;
    final double id = od - 2 * t;

    final double insideArea = math.pi / 4 * id * id;
    final double metalArea = math.pi / 4 * (od * od - id * id);
    final double moment = math.pi / 64 * (math.pow(od, 4) - math.pow(id, 4));
    final double modulus = moment / (od / 2);
    final double gyration = math.sqrt(moment / metalArea);
    final double weight = weightConstant * (od - t) * t *
        type.material.densityLbIn3 / steelDensity;
    final double fluidWeight = insideArea / 144 * fluid.densityLbFt3;

    // Flow: gpm → ft³/s over the bore in ft².
    final double q = flowGpm / gallonsPerCubicFoot / 60;
    final double dFt = id / 12;
    final double v = flowGpm > 0 ? q / (insideArea / 144) : 0;
    final double re = fluid.densityLbFt3 * v * dFt / (fluid.viscosityLbFtH / 3600);
    final double f = v > 0
        ? frictionFactor(re, type.material.roughnessFt / dFt)
        : 0;
    final double hv = v * v / (2 * gravity);

    return PipeResult(
      outsideDiameter: od,
      wallThickness: t,
      insideDiameter: id,
      insideArea: insideArea,
      metalArea: metalArea,
      sectionModulus: modulus,
      momentOfInertia: moment,
      radiusOfGyration: gyration,
      weightOfPipe: weight,
      weightWithFluid: weight + fluidWeight,
      velocity: v,
      reynolds: re,
      frictionFactor: f,
      headLoss: f * (100 / dFt) * hv,
      elbowLoss: size.elbowK * hv,
    );
  }
}

/// IP → SI for display.
class PipeSi {
  const PipeSi._();

  static const double gpmToLs = 0.0630901964;
  static const double inToMm = 25.4;
  static const double in2ToMm2 = 645.16;
  static const double in3ToCm3 = 16.387064;
  static const double in4ToCm4 = 41.62314256;
  static const double lbFtToKgM = 1.48816394;
  static const double ftToM = 0.3048;
  static const double lbFt3ToKgM3 = 16.018463;
  static const double lbFtHToMPaS = 0.413378942;
  static const double btuLbFToKjKgK = 4.1868;
  static const double g = 9.80665;

  static double density(PipeFluid f) => f.densityLbFt3 * lbFt3ToKgM3;

  /// kW per (L/s) per K  ( = ρ·cp in kJ/(L·K) ).
  static double energyFactor(PipeFluid f) =>
      density(f) * f.specificHeatBtuLbF * btuLbFToKjKgK / 1000;

  /// ft/100 ft → Pa/m for [fluid].
  static double headLossPaPerM(double ftPer100Ft, PipeFluid fluid) =>
      ftPer100Ft / 100 * density(fluid) * g;

  /// ft of fluid → Pa for [fluid].
  static double headPa(double ft, PipeFluid fluid) =>
      ft * ftToM * density(fluid) * g;
}
