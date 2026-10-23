/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: hot_water.dart
/// Purpose: Water heater sizing by the fixture-demand method (ASHRAE
///          "hot water demand per fixture for various types of buildings"):
///          total possible demand → probable max demand → storage tank →
///          heater power.
/// Author: ASEC team
/// Created: 22/10/2026
///
/// Pure Dart, works offline. Values recovered from the "Plumbing & Fire
/// Calculator" (DPME) and checked against its screen:
///   total     = Σ quantity × L/h per fixture (for the building type)
///   probable  = total × demand factor
///   tank (L)  = ⌈probable × storage factor⌉
///   power kW  = ⌈tank × 4.184 × (outlet − inlet) / 3600⌉
library;

import 'dart:math' as math;

enum HotWaterFixture {
  privateLavatory('Private lavatory'),
  publicLavatory('Public lavatory'),
  bathtub('Bathtub'),
  footBasin('Foot basin'),
  kitchenSink('Kitchen sink'),
  laundry('Laundry, stationary tub'),
  pantrySink('Pantry sink'),
  shower('Shower');

  const HotWaterFixture(this.label);
  final String label;
}

class HotWaterBuilding {
  const HotWaterBuilding({
    required this.label,
    required this.demandFactor,
    required this.storageFactor,
    required this.litresPerHour,
  });

  final String label;
  final double demandFactor;
  final double storageFactor;

  /// L/h per fixture, in [HotWaterFixture] order. 0 = not used in this
  /// building type.
  final List<double> litresPerHour;

  double demandOf(HotWaterFixture f) => litresPerHour[f.index];
}

const List<HotWaterBuilding> kHotWaterBuildings = <HotWaterBuilding>[
  HotWaterBuilding(label: 'Apartment houses', demandFactor: 0.30, storageFactor: 1.25, litresPerHour: <double>[7.6, 15.1, 75.7, 11.4, 37.9, 75.7, 18.9, 113.6]),
  HotWaterBuilding(label: 'Club', demandFactor: 0.30, storageFactor: 0.90, litresPerHour: <double>[7.6, 22.7, 75.7, 11.4, 75.7, 106, 37.9, 567.8]),
  HotWaterBuilding(label: 'Gymnasium', demandFactor: 0.40, storageFactor: 1.00, litresPerHour: <double>[7.6, 30.3, 113.6, 45.4, 0, 0, 0, 851.6]),
  HotWaterBuilding(label: 'Hospital', demandFactor: 0.25, storageFactor: 0.60, litresPerHour: <double>[7.6, 22.7, 75.7, 11.4, 75.7, 106, 37.9, 283.9]),
  HotWaterBuilding(label: 'Hotel', demandFactor: 0.25, storageFactor: 0.80, litresPerHour: <double>[7.6, 30.3, 75.7, 11.4, 113.6, 106, 37.9, 283.9]),
  HotWaterBuilding(label: 'Industrial plant', demandFactor: 0.40, storageFactor: 1.00, litresPerHour: <double>[7.6, 45.4, 0, 45.4, 75.7, 0, 0, 851.6]),
  HotWaterBuilding(label: 'Office building', demandFactor: 0.30, storageFactor: 2.00, litresPerHour: <double>[7.6, 22.7, 0, 0, 75.7, 0, 37.9, 113.6]),
  HotWaterBuilding(label: 'Private residence', demandFactor: 0.30, storageFactor: 0.70, litresPerHour: <double>[7.6, 0, 75.7, 11.4, 37.9, 75.7, 18.9, 113.6]),
  HotWaterBuilding(label: 'School', demandFactor: 0.40, storageFactor: 1.00, litresPerHour: <double>[7.6, 56.8, 0, 11.4, 75.7, 0, 37.9, 851.6]),
];

/// The original allows at most 8 fixture lines.
const int kMaxFixtureLines = 8;

class HotWaterResult {
  const HotWaterResult({
    required this.totalDemand,
    required this.demandFactor,
    required this.probableDemand,
    required this.storageFactor,
    required this.tankCapacity,
    required this.power,
  });

  /// L/h
  final double totalDemand;
  final double demandFactor;

  /// L/h
  final double probableDemand;
  final double storageFactor;

  /// L
  final double tankCapacity;

  /// kW
  final double power;
}

class HotWater {
  const HotWater._();

  static const double specificHeat = 4.184; // kJ/(kg·K), 1 L ≈ 1 kg

  static HotWaterResult calculate({
    required HotWaterBuilding building,
    required Map<HotWaterFixture, int> fixtures,
    required double inletC,
    required double outletC,
  }) {
    double total = 0;
    fixtures.forEach((HotWaterFixture f, int qty) {
      total += building.demandOf(f) * qty;
    });
    final double probable = total * building.demandFactor;
    final double tank = (probable * building.storageFactor).ceilToDouble();
    final double rise = math.max(0, outletC - inletC).toDouble();
    final double power = (tank * specificHeat * rise / 3600).ceilToDouble();
    return HotWaterResult(
      totalDemand: total,
      demandFactor: building.demandFactor,
      probableDemand: probable,
      storageFactor: building.storageFactor,
      tankCapacity: tank,
      power: power,
    );
  }
}
