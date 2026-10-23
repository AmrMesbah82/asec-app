/// Module: tools / t4_pipe_calc
///
///*************************** FILE INFO ****************************///
/// File Name: pipe_data.dart
/// Purpose: Static data for the pipe sizer — pipe types and materials,
///          the size table (outside diameter + wall per schedule / copper
///          type, elbow K, suggested flow) and the fluids.
/// Author: ASEC team
/// Created: 22/10/2026
///
/// Recovered from McQuay "DesignTools PipeSizer" 6.2 and checked against
/// its screen. Wall thicknesses are the STANDARD values — ASME B36.10M /
/// B36.19M for steel and plastic, ASTM B88 for copper. The original had a
/// few wrong ones (3½" Sch 10 / 40, 12" Sch 5, and "Sch 40 / 80" from 12"
/// up were really the Standard / Extra-Strong walls); here they are
/// corrected, and a schedule the standard does not define is null
/// ("no data"), e.g. Sch 40 at 26"–30".
library;

/// Pipe wall material.
enum PipeMaterial {
  steel(roughnessFt: 0.00015, densityLbIn3: 0.282),
  abs(roughnessFt: 0.000005, densityLbIn3: 0.039),
  pvc(roughnessFt: 0.000005, densityLbIn3: 0.0542),
  copper(roughnessFt: 0.000005, densityLbIn3: 0.322);

  const PipeMaterial({required this.roughnessFt, required this.densityLbIn3});

  /// Absolute roughness, ft.
  final double roughnessFt;

  /// Density of the pipe material, lb/in³.
  final double densityLbIn3;
}

/// Which wall column of [PipeSize] a pipe type reads.
enum PipeSchedule { sch5, sch10, sch40, sch80, typeK, typeL, typeM }

/// The 11 pipe types, in the original program's order.
enum PipeType {
  sch5Steel('Sch 5 Steel', PipeMaterial.steel, PipeSchedule.sch5),
  sch10Steel('Sch 10 Steel', PipeMaterial.steel, PipeSchedule.sch10),
  sch40Steel('Sch 40 Steel', PipeMaterial.steel, PipeSchedule.sch40),
  sch40Abs('Sch 40 ABS Plastic', PipeMaterial.abs, PipeSchedule.sch40),
  sch40Pvc('Sch 40 PVC Plastic', PipeMaterial.pvc, PipeSchedule.sch40),
  sch80Steel('Sch 80 Steel', PipeMaterial.steel, PipeSchedule.sch80),
  sch80Abs('Sch 80 ABS Plastic', PipeMaterial.abs, PipeSchedule.sch80),
  sch80Pvc('Sch 80 PVC Plastic', PipeMaterial.pvc, PipeSchedule.sch80),
  copperK('Type K copper', PipeMaterial.copper, PipeSchedule.typeK),
  copperL('Type L copper', PipeMaterial.copper, PipeSchedule.typeL),
  copperM('Type M copper', PipeMaterial.copper, PipeSchedule.typeM);

  const PipeType(this.label, this.material, this.schedule);

  final String label;
  final PipeMaterial material;
  final PipeSchedule schedule;

  bool get isCopper => material == PipeMaterial.copper;
}

/// One nominal size. Dimensions in inches; null = not made in that
/// schedule / copper type.
class PipeSize {
  const PipeSize({
    required this.label,
    required this.dn,
    required this.odSteel,
    required this.sch5,
    required this.sch10,
    required this.sch40,
    required this.sch80,
    required this.odCopper,
    required this.typeK,
    required this.typeL,
    required this.typeM,
    required this.elbowK,
    required this.defaultFlowGpm,
  });

  /// Nominal size, e.g. ½".
  final String label;

  /// Metric nominal size (DN).
  final int dn;

  /// Outside diameter of steel / plastic pipe (iron pipe size), in.
  final double odSteel;
  final double? sch5;
  final double? sch10;
  final double? sch40;
  final double? sch80;

  /// Outside diameter of copper tube (nominal + ⅛"), in. Null when no copper.
  final double? odCopper;
  final double? typeK;
  final double? typeL;
  final double? typeM;

  /// Loss coefficient of one standard elbow.
  final double elbowK;

  /// The flow the original pre-fills when this size is picked, US gpm.
  final double defaultFlowGpm;

  String get displayLabel => '$label · DN$dn';

  /// (outside diameter, wall) for [type], or null when not made.
  ({double od, double wall})? dimensionsFor(PipeType type) {
    final double? wall = switch (type.schedule) {
      PipeSchedule.sch5 => sch5,
      PipeSchedule.sch10 => sch10,
      PipeSchedule.sch40 => sch40,
      PipeSchedule.sch80 => sch80,
      PipeSchedule.typeK => typeK,
      PipeSchedule.typeL => typeL,
      PipeSchedule.typeM => typeM,
    };
    final double? od = type.isCopper ? odCopper : odSteel;
    if (wall == null || od == null) return null;
    return (od: od, wall: wall);
  }
}

const List<PipeSize> kPipeSizes = <PipeSize>[
  PipeSize(label: '⅛"', dn: 6, odSteel: 0.405, sch5: null, sch10: 0.049, sch40: 0.068, sch80: 0.095, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 2.3, defaultFlowGpm: 0.16),
  PipeSize(label: '¼"', dn: 8, odSteel: 0.54, sch5: null, sch10: 0.065, sch40: 0.088, sch80: 0.119, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 2.2, defaultFlowGpm: 0.31),
  PipeSize(label: '⅜"', dn: 10, odSteel: 0.675, sch5: null, sch10: 0.065, sch40: 0.091, sch80: 0.126, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 2.1, defaultFlowGpm: 0.72),
  PipeSize(label: '½"', dn: 15, odSteel: 0.84, sch5: null, sch10: 0.083, sch40: 0.109, sch80: 0.147, odCopper: 0.625, typeK: 0.049, typeL: 0.04, typeM: 0.028, elbowK: 2.0, defaultFlowGpm: 1.4),
  PipeSize(label: '¾"', dn: 20, odSteel: 1.05, sch5: 0.065, sch10: 0.083, sch40: 0.113, sch80: 0.154, odCopper: 0.875, typeK: 0.065, typeL: 0.045, typeM: 0.032, elbowK: 1.7, defaultFlowGpm: 3.0),
  PipeSize(label: '1"', dn: 25, odSteel: 1.315, sch5: 0.065, sch10: 0.109, sch40: 0.133, sch80: 0.179, odCopper: 1.125, typeK: 0.065, typeL: 0.05, typeM: 0.035, elbowK: 1.5, defaultFlowGpm: 5.6),
  PipeSize(label: '1¼"', dn: 32, odSteel: 1.66, sch5: 0.065, sch10: 0.109, sch40: 0.14, sch80: 0.191, odCopper: 1.375, typeK: 0.065, typeL: 0.055, typeM: 0.042, elbowK: 1.1, defaultFlowGpm: 12.0),
  PipeSize(label: '1½"', dn: 40, odSteel: 1.9, sch5: 0.065, sch10: 0.109, sch40: 0.145, sch80: 0.2, odCopper: 1.625, typeK: 0.072, typeL: 0.06, typeM: 0.049, elbowK: 0.99, defaultFlowGpm: 18.0),
  PipeSize(label: '2"', dn: 50, odSteel: 2.375, sch5: 0.065, sch10: 0.109, sch40: 0.154, sch80: 0.218, odCopper: 2.125, typeK: 0.083, typeL: 0.07, typeM: 0.058, elbowK: 0.95, defaultFlowGpm: 35.0),
  PipeSize(label: '2½"', dn: 65, odSteel: 2.875, sch5: 0.083, sch10: 0.12, sch40: 0.203, sch80: 0.276, odCopper: 2.625, typeK: 0.095, typeL: 0.08, typeM: 0.065, elbowK: 0.37, defaultFlowGpm: 56.0),
  PipeSize(label: '3"', dn: 80, odSteel: 3.5, sch5: 0.083, sch10: 0.12, sch40: 0.216, sch80: 0.3, odCopper: 3.125, typeK: 0.109, typeL: 0.09, typeM: 0.072, elbowK: 0.35, defaultFlowGpm: 102.0),
  PipeSize(label: '3½"', dn: 90, odSteel: 4.0, sch5: 0.083, sch10: 0.12, sch40: 0.226, sch80: 0.318, odCopper: 3.625, typeK: 0.12, typeL: 0.1, typeM: 0.083, elbowK: 0.33, defaultFlowGpm: 174.0),
  PipeSize(label: '4"', dn: 100, odSteel: 4.5, sch5: 0.083, sch10: 0.12, sch40: 0.237, sch80: 0.337, odCopper: 4.125, typeK: 0.134, typeL: 0.11, typeM: 0.095, elbowK: 0.3, defaultFlowGpm: 208.0),
  PipeSize(label: '5"', dn: 125, odSteel: 5.563, sch5: 0.109, sch10: 0.134, sch40: 0.258, sch80: 0.375, odCopper: 5.125, typeK: 0.16, typeL: 0.125, typeM: 0.109, elbowK: 0.29, defaultFlowGpm: 380.0),
  PipeSize(label: '6"', dn: 150, odSteel: 6.625, sch5: 0.109, sch10: 0.134, sch40: 0.28, sch80: 0.432, odCopper: 6.125, typeK: 0.192, typeL: 0.14, typeM: 0.122, elbowK: 0.28, defaultFlowGpm: 617.0),
  PipeSize(label: '8"', dn: 200, odSteel: 8.625, sch5: 0.109, sch10: 0.148, sch40: 0.322, sch80: 0.5, odCopper: 8.125, typeK: 0.271, typeL: 0.2, typeM: 0.17, elbowK: 0.26, defaultFlowGpm: 1275.0),
  PipeSize(label: '10"', dn: 250, odSteel: 10.75, sch5: 0.134, sch10: 0.165, sch40: 0.365, sch80: 0.594, odCopper: 10.125, typeK: 0.338, typeL: 0.25, typeM: 0.212, elbowK: 0.25, defaultFlowGpm: 2320.0),
  PipeSize(label: '12"', dn: 300, odSteel: 12.75, sch5: 0.156, sch10: 0.18, sch40: 0.406, sch80: 0.688, odCopper: 12.125, typeK: 0.405, typeL: 0.28, typeM: 0.254, elbowK: 0.24, defaultFlowGpm: 3525.0),
  PipeSize(label: '14"', dn: 350, odSteel: 14.0, sch5: null, sch10: 0.25, sch40: 0.438, sch80: 0.75, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 0.23, defaultFlowGpm: 4300.0),
  PipeSize(label: '16"', dn: 400, odSteel: 16.0, sch5: null, sch10: 0.25, sch40: 0.5, sch80: 0.844, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 0.22, defaultFlowGpm: 5700.0),
  PipeSize(label: '18"', dn: 450, odSteel: 18.0, sch5: null, sch10: 0.25, sch40: 0.562, sch80: 0.938, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 0.21, defaultFlowGpm: 7280.0),
  PipeSize(label: '20"', dn: 500, odSteel: 20.0, sch5: null, sch10: 0.25, sch40: 0.594, sch80: 1.031, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 0.2, defaultFlowGpm: 9070.0),
  PipeSize(label: '24"', dn: 600, odSteel: 24.0, sch5: null, sch10: 0.25, sch40: 0.688, sch80: 1.219, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 0.18, defaultFlowGpm: 13230.0),
  PipeSize(label: '26"', dn: 650, odSteel: 26.0, sch5: null, sch10: 0.312, sch40: null, sch80: null, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 0.18, defaultFlowGpm: 15600.0),
  PipeSize(label: '28"', dn: 700, odSteel: 28.0, sch5: null, sch10: 0.312, sch40: null, sch80: null, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 0.18, defaultFlowGpm: 18180.0),
  PipeSize(label: '30"', dn: 750, odSteel: 30.0, sch5: null, sch10: 0.312, sch40: null, sch80: null, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 0.18, defaultFlowGpm: 20950.0),
  PipeSize(label: '32"', dn: 800, odSteel: 32.0, sch5: null, sch10: 0.312, sch40: 0.688, sch80: null, odCopper: null, typeK: null, typeL: null, typeM: null, elbowK: 0.18, defaultFlowGpm: 23900.0),
];

/// A fluid of the pipe sizer (properties in IP units, as in the original).
class PipeFluid {
  const PipeFluid({
    required this.label,
    required this.labelSi,
    required this.densityLbFt3,
    required this.viscosityLbFtH,
    required this.specificHeatBtuLbF,
    this.toxic = false,
  });

  final String label;
  final String labelSi;

  /// lb/ft³
  final double densityLbFt3;

  /// Dynamic viscosity, lb/(ft·h).
  final double viscosityLbFtH;

  /// Btu/(lb·°F)
  final double specificHeatBtuLbF;

  /// Ethylene glycol: the original shows "Very toxic".
  final bool toxic;
}

const List<PipeFluid> kPipeFluids = <PipeFluid>[
  PipeFluid(label: '50°F Water', labelSi: '10°C Water', densityLbFt3: 62.411, viscosityLbFtH: 3.1667, specificHeatBtuLbF: 1.002),
  PipeFluid(label: '70°F Water', labelSi: '21°C Water', densityLbFt3: 62.304, viscosityLbFtH: 2.3616, specificHeatBtuLbF: 0.998),
  PipeFluid(label: '170°F Water', labelSi: '77°C Water', densityLbFt3: 60.797, viscosityLbFtH: 0.8961, specificHeatBtuLbF: 1.001),
  PipeFluid(label: '190°F Water', labelSi: '88°C Water', densityLbFt3: 60.357, viscosityLbFtH: 0.7823, specificHeatBtuLbF: 1.003),
  PipeFluid(label: '30% Ethylene glycol', labelSi: '30% Ethylene glycol', densityLbFt3: 64.796, viscosityLbFtH: 5.8061, specificHeatBtuLbF: 0.89, toxic: true),
  PipeFluid(label: '40% Ethylene glycol', labelSi: '40% Ethylene glycol', densityLbFt3: 65.731, viscosityLbFtH: 7.5, specificHeatBtuLbF: 0.84, toxic: true),
  PipeFluid(label: '50% Ethylene glycol', labelSi: '50% Ethylene glycol', densityLbFt3: 66.354, viscosityLbFtH: 9.919, specificHeatBtuLbF: 0.79, toxic: true),
  PipeFluid(label: '30% Propylene glycol', labelSi: '30% Propylene glycol', densityLbFt3: 63.924, viscosityLbFtH: 7.2576, specificHeatBtuLbF: 0.94),
  PipeFluid(label: '40% Propylene glycol', labelSi: '40% Propylene glycol', densityLbFt3: 64.485, viscosityLbFtH: 14.757, specificHeatBtuLbF: 0.89),
  PipeFluid(label: '50% Propylene glycol', labelSi: '50% Propylene glycol', densityLbFt3: 64.921, viscosityLbFtH: 21.773, specificHeatBtuLbF: 0.86),
];
