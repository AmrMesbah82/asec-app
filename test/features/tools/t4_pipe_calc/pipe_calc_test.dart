// Reference values below were read off McQuay PipeSizer 6.2 running the
// same inputs (½" pipe, 1.4 US gpm).

import 'package:flutter_test/flutter_test.dart';

import 'package:asec/features/tools/t4_pipe_calc/domain/pipe_calculator.dart';
import 'package:asec/features/tools/t4_pipe_calc/domain/pipe_data.dart';

PipeSize _size(String label) =>
    kPipeSizes.firstWhere((PipeSize s) => s.label == label);

PipeFluid _fluid(String label) =>
    kPipeFluids.firstWhere((PipeFluid f) => f.label == label);

void main() {
  group('½" Sch 40 steel, 50°F water, 1.4 gpm', () {
    final PipeResult r = PipeCalculator.calculate(
      type: PipeType.sch40Steel,
      size: _size('½"'),
      fluid: _fluid('50°F Water'),
      flowGpm: 1.4,
    )!;

    test('pipe section', () {
      expect(r.outsideDiameter, closeTo(0.84, 1e-9));
      expect(r.wallThickness, closeTo(0.109, 1e-9));
      expect(r.insideDiameter, closeTo(0.622, 1e-9));
      expect(r.insideArea, closeTo(0.304, 0.0005));
      expect(r.metalArea, closeTo(0.2502, 0.0002));
      expect(r.sectionModulus, closeTo(0.04071, 0.00003));
      expect(r.momentOfInertia, closeTo(0.0171, 0.00005));
      expect(r.radiusOfGyration, closeTo(0.2613, 0.00005));
      expect(r.weightOfPipe, closeTo(0.851, 0.0005));
      expect(r.weightWithFluid, closeTo(0.983, 0.0005));
    });

    test('flow', () {
      expect(r.velocity, closeTo(1.48, 0.005));
      expect(r.reynolds, closeTo(5436, 1));
      expect(r.frictionFactor, closeTo(0.03972, 0.000005));
      expect(r.headLoss, closeTo(2.602, 0.0005));
      expect(r.elbowLoss, closeTo(0.068, 0.0005));
      expect(PipeCalculator.energyFactor(_fluid('50°F Water')), closeTo(501.6, 0.05));
    });
  });

  test('laminar: 50% propylene glycol uses 64/Re', () {
    final PipeResult r = PipeCalculator.calculate(
      type: PipeType.sch40Steel,
      size: _size('½"'),
      fluid: _fluid('50% Propylene glycol'),
      flowGpm: 1.4,
    )!;
    expect(r.reynolds, closeTo(822, 1));
    expect(r.frictionFactor, closeTo(0.07782, 0.0001));
    expect(r.headLoss, closeTo(5.098, 0.003));
  });

  test('40% propylene glycol', () {
    final PipeResult r = PipeCalculator.calculate(
      type: PipeType.sch40Steel,
      size: _size('½"'),
      fluid: _fluid('40% Propylene glycol'),
      flowGpm: 1.4,
    )!;
    expect(r.reynolds, closeTo(1205, 1));
    expect(r.frictionFactor, closeTo(0.0531, 0.0001));
    expect(r.headLoss, closeTo(3.479, 0.003));
  });

  test('weights of other materials', () {
    final PipeResult sch10 = PipeCalculator.calculate(
      type: PipeType.sch10Steel,
      size: _size('½"'),
      fluid: kPipeFluids.first,
      flowGpm: 1.4,
    )!;
    expect(sch10.weightOfPipe, closeTo(0.671, 0.0005));
    expect(sch10.sectionModulus, closeTo(0.03408, 0.00003));

    final PipeResult abs80 = PipeCalculator.calculate(
      type: PipeType.sch80Abs,
      size: _size('½"'),
      fluid: kPipeFluids.first,
      flowGpm: 1.4,
    )!;
    expect(abs80.insideDiameter, closeTo(0.546, 1e-9));
    expect(abs80.weightOfPipe, closeTo(0.15, 0.0005));
    expect(abs80.momentOfInertia, closeTo(0.02008, 0.00001));
  });

  test('standard walls (corrected from the original)', () {
    expect(_size('3½"').sch10, 0.120);
    expect(_size('3½"').sch40, 0.226);
    expect(_size('24"').sch40, 0.688);
    expect(_size('24"').sch80, 1.219);
    expect(_size('12"').sch5, 0.156);
    expect(_size('28"').dimensionsFor(PipeType.sch40Steel), isNull);
    expect(_size('14"').dimensionsFor(PipeType.copperL), isNull);
    expect(_size('½"').dimensionsFor(PipeType.copperL)!.od, 0.625);
  });

  test('no data returns null; zero flow gives zero loss', () {
    expect(
      PipeCalculator.calculate(
        type: PipeType.sch5Steel,
        size: _size('⅛"'),
        fluid: kPipeFluids.first,
        flowGpm: 1,
      ),
      isNull,
    );
    final PipeResult r = PipeCalculator.calculate(
      type: PipeType.sch40Steel,
      size: _size('2"'),
      fluid: kPipeFluids.first,
      flowGpm: 0,
    )!;
    expect(r.velocity, 0);
    expect(r.headLoss, 0);
  });

  test('metric conversions', () {
    final PipeFluid water = _fluid('50°F Water');
    expect(PipeSi.density(water), closeTo(999.7, 0.1));
    // 2.602 ft/100 ft of 50°F water ≈ 255 Pa/m
    expect(PipeSi.headLossPaPerM(2.602, water), closeTo(255.1, 0.2));
  });
}
