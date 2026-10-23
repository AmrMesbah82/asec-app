// Reference values below were read off the original Windows programs
// (Fridgetech FDuct.exe and McQuay DuctSizer 6.4) running the same inputs.

import 'package:flutter_test/flutter_test.dart';

import 'package:asec/features/tools/t3_duct_calc/domain/duct_calculator.dart';
import 'package:asec/features/tools/t3_duct_calc/domain/duct_data.dart';
import 'package:asec/features/tools/t3_duct_calc/domain/duct_sizer_calculator.dart';

/// Within [rel] relative, or within half a display step of [decimals].
Matcher near(double expected, {int decimals = 1, double rel = 6e-4}) {
  double step = 1;
  for (int i = 0; i < decimals; i++) {
    step /= 10;
  }
  final double tol = (expected.abs() * rel) > step ? expected.abs() * rel : step * 0.51;
  return closeTo(expected, tol);
}

void main() {
  group('Round duct (FDuct)', () {
    test('spiral, 1000 l/s, 1000 m', () {
      final List<RoundDuctRow> rows = DuctCalculator.roundTable(
        flowLs: 1000,
        lengthM: 1000,
        type: RoundDuctType.spiral,
      );
      final Map<int, double> total = <int, double>{
        80: 6273315.6, 100: 1959590.8, 150: 239567.1, 200: 54640.6,
        300: 6972.8, 400: 1650.8, 500: 546.2, 630: 175.4, 1000: 18.5,
      };
      for (final RoundDuctRow r in rows) {
        if (total.containsKey(r.diameterMm)) {
          expect(r.totalPressureDrop, near(total[r.diameterMm]!), reason: '${r.diameterMm} mm');
        }
      }
      final RoundDuctRow d80 = rows.first;
      expect(d80.velocity, near(198.94, decimals: 2));
      expect(d80.velocityPressure, near(23826.3));
      // 90/0.5, 90/1, 60/0.5, 60/1, 45/0.5, 45/1, 30/0.5, 30/1
      const List<double> bends80 = <double>[17154.9, 5241.8, 13380.9, 4088.6, 10293.0, 3145.1, 7719.7, 2358.8];
      for (int i = 0; i < bends80.length; i++) {
        expect(d80.bendLosses![i], near(bends80[i]), reason: kBendTypes[i].label);
      }
      final RoundDuctRow d300 = rows.firstWhere((RoundDuctRow r) => r.diameterMm == 300);
      expect(d300.bendLosses![0], near(115.7));
      expect(d300.bendLosses![1], near(44.6));
    });

    test('flexible, 1000 l/s, 1000 m', () {
      final List<RoundDuctRow> rows = DuctCalculator.roundTable(
        flowLs: 1000,
        lengthM: 1000,
        type: RoundDuctType.flexible,
      );
      expect(rows.first.totalPressureDrop, near(18733867.3));
      expect(rows[5].totalPressureDrop, near(133778.5)); // 200 mm
      expect(rows.first.bendLosses, isNull);
    });

    test('small flow, 183.7 l/s, 1 m', () {
      final List<RoundDuctRow> rows = DuctCalculator.roundTable(
        flowLs: 183.7,
        lengthM: 1,
        type: RoundDuctType.spiral,
      );
      expect(rows[0].pressureDropPerMetre, near(222.5, rel: 1e-3));
      expect(rows[1].pressureDropPerMetre, near(70.9));
      expect(rows[0].velocity, near(36.55, decimals: 2));
    });
  });

  group('Rectangular duct (FDuct)', () {
    test('1000 l/s, 1000 m', () {
      final List<List<double>> cases = <List<double>>[
        // a, b, De, V, total dP, Pv
        <double>[100, 300, 185, 33.33, 80709.1, 668.9],
        <double>[212, 212, 233, 22.25, 24817.5, 298.0],
        <double>[400, 150, 264, 16.67, 13407.0, 167.2],
        <double>[500, 500, 551, 4.00, 339.6, 9.6],
        <double>[80, 80, 88, 156.25, 3792023.2, 14697.3],
      ];
      for (final List<double> c in cases) {
        final RectDuctResult r = DuctCalculator.rectangular(
          flowLs: 1000,
          sideAMm: c[0],
          sideBMm: c[1],
          lengthM: 1000,
        );
        final String id = '${c[0]}x${c[1]}';
        expect(r.equivalentDiameterMm.round(), c[2].round(), reason: id);
        expect(r.velocity, near(c[3], decimals: 2), reason: id);
        expect(r.totalPressureDrop, near(c[4]), reason: id);
        expect(r.velocityPressure, near(c[5]), reason: id);
      }
    });
  });

  test('Flow conversions', () {
    final Map<FlowUnit, double> a = DuctCalculator.convertFlow(183.7, FlowUnit.litresPerSecond);
    expect(a[FlowUnit.cubicMetresPerMinute], near(11.02, decimals: 2));
    expect(a[FlowUnit.cubicMetresPerHour], near(661.32, decimals: 2));
    final Map<FlowUnit, double> b = DuctCalculator.convertFlow(183.7, FlowUnit.cubicMetresPerHour);
    expect(b[FlowUnit.litresPerSecond], near(51.03, decimals: 2));
  });

  group('Duct sizer (DuctSizer, 68°F air, IP)', () {
    const AirCondition air = AirCondition(
      ipLabel: '68°F Air STP',
      siLabel: '20°C Air STP',
      densityLbFt3: 0.075,
      viscosityLbFtH: 0.0432,
    );

    test('flow + head loss → diameter', () {
      // cfm, in.WC/100ft → D, area, V, f, Pv, head loss
      final List<List<double>> cases = <List<double>>[
        <double>[1000, 0.1, 13.9, 1.0538, 948.9, 0.02042, 0.0561, 0.099],
        <double>[200, 0.08, 7.9, 0.3404, 587.5, 0.02494, 0.0215, 0.082],
        <double>[50, 0.5, 3.3, 0.0594, 841.8, 0.02994, 0.0442, 0.481],
      ];
      for (final List<double> c in cases) {
        final SizerResult r = DuctSizerCalculator.solve(
          given: <SizerField, double>{SizerField.flow: c[0], SizerField.headLoss: c[1]},
          air: air,
          units: SizerUnits.ip,
        );
        final String id = '${c[0]} cfm';
        expect(r.fields[SizerField.diameter], near(c[2]), reason: id);
        expect(r.flowArea, near(c[3], decimals: 4), reason: id);
        expect(r.velocity, near(c[4]), reason: id);
        expect(r.frictionFactor, near(c[5], decimals: 5), reason: id);
        expect(r.velocityPressure, near(c[6], decimals: 4), reason: id);
        expect(r.headLoss, near(c[7], decimals: 3), reason: id);
      }
    });

    test('flow + velocity → diameter, then back again', () {
      final SizerResult a = DuctSizerCalculator.solve(
        given: <SizerField, double>{SizerField.flow: 1000, SizerField.velocity: 1000},
        air: air,
        units: SizerUnits.ip,
      );
      final double d = a.fields[SizerField.diameter]!;
      expect(d, near(13.5)); // √(4·1 ft²/π) = 13.54 in → 13.5
      final SizerResult b = DuctSizerCalculator.solve(
        given: <SizerField, double>{SizerField.diameter: d, SizerField.headLoss: a.headLoss},
        air: air,
        units: SizerUnits.ip,
      );
      expect(b.fields[SizerField.flow], near(1000, rel: 1e-6));
    });

    test('equivalent rectangle', () {
      final SizerResult r = DuctSizerCalculator.solve(
        given: <SizerField, double>{SizerField.flow: 1000, SizerField.headLoss: 0.1},
        air: air,
        units: SizerUnits.ip,
        sideA: 10,
      );
      expect(r.rectEquivalentDiameter, near(r.fields[SizerField.diameter]!, decimals: 3));
      expect(DuctSizerCalculator.huebscher(10, r.rectSideB!), near(13.9, decimals: 3));
    });

    test('metric units round-trip', () {
      final SizerResult ip = DuctSizerCalculator.solve(
        given: <SizerField, double>{SizerField.flow: 1000, SizerField.diameter: 14},
        air: air,
        units: SizerUnits.ip,
      );
      final SizerResult si = DuctSizerCalculator.solve(
        given: <SizerField, double>{SizerField.flow: 471.947443, SizerField.diameter: 355.6},
        air: air,
        units: SizerUnits.si,
      );
      expect(si.velocity, near(ip.velocity * 0.00508, decimals: 4));
      expect(si.headLoss, near(ip.headLoss * 249.0889 / 30.48, decimals: 4));
      expect(si.reynolds, near(ip.reynolds, rel: 1e-9));
    });

    test('needs exactly two positive values', () {
      expect(
        () => DuctSizerCalculator.solve(
          given: <SizerField, double>{SizerField.flow: 1000},
          air: air,
          units: SizerUnits.ip,
        ),
        throwsA(isA<DuctSizerException>()),
      );
      expect(
        () => DuctSizerCalculator.solve(
          given: <SizerField, double>{SizerField.flow: 0, SizerField.velocity: 900},
          air: air,
          units: SizerUnits.ip,
        ),
        throwsA(isA<DuctSizerException>()),
      );
    });
  });
}
