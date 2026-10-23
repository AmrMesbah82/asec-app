// Reference values below were read off the "Plumbing & Fire Calculator"
// (DPME) running the same inputs.

import 'package:flutter_test/flutter_test.dart';

import 'package:asec/features/tools/t5_plumbing_fire/domain/fire_gas.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/hot_water.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/storm_water.dart';

void main() {
  group('Storm water (rate 2 in/h)', () {
    StormResult run(double area, int slope) =>
        StormWater.calculate(roofAreaM2: area, rateIndex: 2, slopeIndex: slope);

    test('500 m², 1 % slope', () {
      final StormResult r = run(500, 1);
      expect(r.verticalLeader, 4);
      expect(r.horizontalLeader, 6); // 5" table result, stocked as 6"
      expect(r.gutterSize, 10);
      expect(r.gutterRatio, closeTo(0.748503, 1e-6));
      expect(r.gutterCount, 1);
    });

    test('200 m² across the four slopes', () {
      expect(run(200, 0).horizontalLeader, 6);
      expect(run(200, 1).horizontalLeader, 4);
      expect(run(200, 2).horizontalLeader, 3);
      expect(run(200, 3).horizontalLeader, 3);
      expect(run(200, 1).verticalLeader, 3);
      expect(run(200, 1).gutterSize, 8); // 7" stocked as 8"
      expect(run(200, 1).gutterRatio, closeTo(0.78125, 1e-9));
    });

    test('gutters at other areas', () {
      expect(run(20, 1).gutterSize, 3);
      expect(run(20, 1).gutterRatio, closeTo(0.645161, 1e-6));
      expect(run(50, 1).gutterSize, 4);
      expect(run(100, 1).gutterSize, 6);
      expect(run(100, 1).gutterRatio, closeTo(0.862069, 1e-6));
      expect(run(300, 1).gutterSize, 8);
      expect(run(1000, 1).gutterSize, 10);
      expect(run(1000, 1).gutterCount, 2);
      expect(run(150, 1).verticalLeader, 2.5);
      expect(run(1000, 1).verticalLeader, 6);
      expect(run(1000, 1).horizontalLeader, 8);
    });

    test('actual gutter', () {
      expect(StormWater.gutterSizeForCount(roofAreaM2: 1000, rateIndex: 2, count: 3), 8);
      // 6" gutters hold 178 m² each at 2 in/h → 1000 m² needs 6.
      expect(StormWater.gutterCountForSize(roofAreaM2: 1000, rateIndex: 2, diameter: 6), 6);
      expect(StormWater.gutterCountTooSmall(roofAreaM2: 5000, rateIndex: 2, count: 2), isTrue);
    });

    test('1.5 in/h tables are the 1 in/h tables ÷ 1.5', () {
      expect(kVerticalLeaderTables[1].first.maxArea, closeTo(202 / 1.5, 0.001));
      expect(kHorizontalLeaderTables[1][1].first.maxArea, closeTo(305 / 1.5, 0.001));
    });
  });

  group('Hot water', () {
    test('apartment, 10 kitchen sinks, 10 → 60 °C', () {
      final HotWaterResult r = HotWater.calculate(
        building: kHotWaterBuildings.first,
        fixtures: <HotWaterFixture, int>{HotWaterFixture.kitchenSink: 10},
        inletC: 10,
        outletC: 60,
      );
      expect(r.totalDemand, closeTo(379, 1e-9));
      expect(r.demandFactor, 0.3);
      expect(r.probableDemand, closeTo(113.7, 1e-9));
      expect(r.storageFactor, 1.25);
      expect(r.tankCapacity, 143);
      expect(r.power, 9);
    });

    test('power for other temperature rises', () {
      HotWaterResult run(double inlet) => HotWater.calculate(
            building: kHotWaterBuildings.first,
            fixtures: <HotWaterFixture, int>{HotWaterFixture.kitchenSink: 10},
            inletC: inlet,
            outletC: 60,
          );
      expect(run(20).power, 7);
      expect(run(15).power, 8);
    });
  });

  group('FM-200 (21 °C)', () {
    test('50 m² × 3 m', () {
      final Fm200Result r = Fm200.calculate(areaM2: 50, heightM: 3, ambientC: 21);
      expect(r.volume, 150);
      expect(r.agentWeight, closeTo(82.17, 0.005));
      expect(r.takeWeight, 83);
      expect(r.cylinder!.partNumber, '90-100200-001');
      expect(r.cylinder!.one!.nozzleSize, 2);
      expect(r.cylinder!.one!.sections.single.pipeSize, 2.5);
      expect(r.cylinder!.one!.sections.single.maxLengthFt, 36);
    });

    test('cylinder ranges', () {
      String part(double v) => Fm200.calculate(areaM2: v, heightM: 1, ambientC: 21).cylinder!.partNumber;
      expect(part(7.3), '90-100010-001');
      expect(part(14.6), '90-100020-001');
      expect(part(27.4), '90-100040-001');
      expect(part(54.8), '90-100070-001');
      expect(Fm200.calculate(areaM2: 365, heightM: 1, ambientC: 21).cylinder!.four!.sections.first.pipeSize, 4);
      expect(Fm200.calculate(areaM2: 1000, heightM: 1, ambientC: 21).cylinder, isNull);
    });

    test('layouts that do not exist are null', () {
      expect(kFm200Cylinders[1].four, isNull); // 20 lb: no 4-nozzle row
      expect(kFm200Cylinders[0].two, isNull);
      expect(kFm200Cylinders[7].one, isNull);
    });
  });

  group('CO₂', () {
    test('matches the original', () {
      final Co2Result a = Co2.calculate(areaM2: 50, heightM: 3);
      expect(a.weight, closeTo(199.5, 1e-9));
      expect(a.cylinders, 5);
      final Co2Result b = Co2.calculate(areaM2: 200, heightM: 4);
      expect(b.weight, closeTo(1064, 1e-9));
      expect(b.cylinders, 24);
      final Co2Result c = Co2.calculate(areaM2: 10, heightM: 2.5);
      expect(c.weight, closeTo(40, 1e-9));
      expect(c.cylinders, 1);
    });
  });
}
