/// Module: tools / t3_duct_calc
///
///*************************** FILE INFO ****************************///
/// File Name: duct_data.dart
/// Purpose: Static reference data for the duct calculator — standard round
///          sizes, duct materials, bend types, flow units, recommended /
///          maximum velocities and the DuctSizer air conditions.
/// Author: ASEC team
/// Created: 21/10/2026
///
/// The values were recovered from two Windows tools — Fridgetech
/// "Ductulator" (FDuct.exe) and McQuay "DesignTools DuctSizer" 6.4 — and
/// checked against what those programs show on screen.
library;

/// Standard round duct diameters (mm) listed by the Round Duct table.
const List<int> kStandardRoundDiametersMm = <int>[
  80, 100, 125, 150, 160, 200, 250, 300, 315, 355, 400, 450,
  500, 560, 630, 710, 800, 900, 1000, 1120, 1250, 1422, 1500,
];

/// Round duct material (sets the wall roughness).
enum RoundDuctType {
  spiral('Spiral', 0.0001),
  flexible('Flexible (fully extended)', 0.003);

  const RoundDuctType(this.label, this.roughnessM);

  final String label;

  /// Absolute wall roughness, metres.
  final double roughnessM;
}

/// One bend (elbow) column of the Round Duct table.
class BendType {
  const BendType(this.angleDeg, this.radiusRatio);

  /// Bend angle in degrees: 90, 60, 45 or 30.
  final int angleDeg;

  /// Centre-line radius ÷ diameter: 0.5 or 1.0.
  final double radiusRatio;

  String get label => '$angleDeg° R/D=${radiusRatio == 1.0 ? '1' : '0.5'}';
}

const List<BendType> kBendTypes = <BendType>[
  BendType(90, 0.5),
  BendType(90, 1.0),
  BendType(60, 0.5),
  BendType(60, 1.0),
  BendType(45, 0.5),
  BendType(45, 1.0),
  BendType(30, 0.5),
  BendType(30, 1.0),
];

/// Volume-flow units for the Conversions tab.
enum FlowUnit {
  litresPerSecond('l/s', 0.001),
  cubicMetresPerSecond('m³/s', 1.0),
  cubicMetresPerMinute('m³/min', 1.0 / 60.0),
  cubicMetresPerHour('m³/hr', 1.0 / 3600.0);

  const FlowUnit(this.label, this.toCubicMetresPerSecond);

  final String label;

  /// A value in this unit × this factor = m³/s.
  final double toCubicMetresPerSecond;
}

/// One row of the recommended / maximum velocity tables (m/s).
class VelocityRow {
  const VelocityRow({
    required this.ductClass,
    required this.shape,
    required this.values,
  });

  /// "Main Duct" or "Branch Duct".
  final String ductClass;

  /// "Rectangular" or "Round".
  final String shape;

  /// One value per [kVelocityColumns] entry, m/s.
  final List<double> values;
}

const List<String> kVelocityColumns = <String>[
  'Residences',
  'Theaters & Libraries',
  'Offices',
  'Industrial',
];

const List<VelocityRow> kRecommendedVelocities = <VelocityRow>[
  VelocityRow(ductClass: 'Main Duct', shape: 'Rectangular', values: <double>[3.6, 5, 11.2, 15.2]),
  VelocityRow(ductClass: 'Main Duct', shape: 'Round', values: <double>[4.6, 6, 12.2, 20.2]),
  VelocityRow(ductClass: 'Branch Duct', shape: 'Rectangular', values: <double>[2.6, 2.6, 8.2, 12.8]),
  VelocityRow(ductClass: 'Branch Duct', shape: 'Round', values: <double>[3, 3, 10.2, 15.2]),
];

const List<VelocityRow> kMaximumVelocities = <VelocityRow>[
  VelocityRow(ductClass: 'Main Duct', shape: 'Rectangular', values: <double>[4, 9, 12.8, 17.8]),
  VelocityRow(ductClass: 'Main Duct', shape: 'Round', values: <double>[6, 10.6, 16.2, 32]),
  VelocityRow(ductClass: 'Branch Duct', shape: 'Rectangular', values: <double>[3.6, 4, 10.2, 15.2]),
  VelocityRow(ductClass: 'Branch Duct', shape: 'Round', values: <double>[5, 5, 12.6, 20.2]),
];

/// An air condition offered by DuctSizer. Properties are kept in IP units,
/// exactly as the original program stores them.
class AirCondition {
  const AirCondition({
    required this.ipLabel,
    required this.siLabel,
    required this.densityLbFt3,
    required this.viscosityLbFtH,
    this.specificHeatBtuLbF = 0.24,
  });

  final String ipLabel;
  final String siLabel;

  /// Density, lb/ft³.
  final double densityLbFt3;

  /// Dynamic viscosity, lb/(ft·h).
  final double viscosityLbFtH;

  /// Specific heat, Btu/(lb·°F).
  final double specificHeatBtuLbF;
}

const List<AirCondition> kAirConditions = <AirCondition>[
  AirCondition(ipLabel: '68°F Air STP', siLabel: '20°C Air STP', densityLbFt3: 0.075, viscosityLbFtH: 0.0432),
  AirCondition(ipLabel: '55°F Air at 97% RH and 1 atm', siLabel: '13°C Air at 97% RH and 1 atm', densityLbFt3: 0.0759, viscosityLbFtH: 0.0428),
  AirCondition(ipLabel: '75°F Air at 50% RH and 1 atm', siLabel: '24°C Air at 50% RH and 1 atm', densityLbFt3: 0.0731, viscosityLbFtH: 0.0441),
  AirCondition(ipLabel: '100°F Air at 23% RH and 1 atm', siLabel: '38°C Air at 23% RH and 1 atm', densityLbFt3: 0.06982, viscosityLbFtH: 0.04572),
  AirCondition(ipLabel: '125°F Air at 11% RH and 1 atm', siLabel: '52°C Air at 11% RH and 1 atm', densityLbFt3: 0.06685, viscosityLbFtH: 0.04734),
];
