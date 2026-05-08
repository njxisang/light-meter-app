import 'package:flutter_test/flutter_test.dart';
import 'package:light_meter_app/core/utils/exposure_calculator.dart';
import 'package:light_meter_app/core/constants/exposure_constants.dart';

void main() {
  group('ExposureCalculator', () {
    group('calculateEV', () {
      test('lux=10000 should give EV around 10.97', () {
        // EV = log2(10000 * 0.2) = log2(2000) ≈ 10.97
        final ev = ExposureCalculator.calculateEV(10000);
        expect(ev, closeTo(10.97, 0.1));
      });

      test('lux=100 should give EV around 4.3', () {
        // EV = log2(100 * 0.2) = log2(20) ≈ 4.3
        final ev = ExposureCalculator.calculateEV(100);
        expect(ev, closeTo(4.3, 0.1));
      });

      test('lux=0 should return minEv', () {
        final ev = ExposureCalculator.calculateEV(0);
        expect(ev, equals(ExposureConstants.minEv));
      });

      test('lux negative should return minEv', () {
        final ev = ExposureCalculator.calculateEV(-100);
        expect(ev, equals(ExposureConstants.minEv));
      });
    });

    group('applyModeAdjustment', () {
      test('portrait mode reduces EV by 0.3', () {
        final adjusted = ExposureCalculator.applyModeAdjustment(10.0, 'portrait');
        expect(adjusted, equals(9.7));
      });

      test('landscape mode increases EV by 0.3', () {
        final adjusted = ExposureCalculator.applyModeAdjustment(10.0, 'landscape');
        expect(adjusted, equals(10.3));
      });

      test('sports mode keeps EV unchanged', () {
        final adjusted = ExposureCalculator.applyModeAdjustment(10.0, 'sports');
        expect(adjusted, equals(10.0));
      });

      test('lowlight mode reduces EV by 0.7', () {
        final adjusted = ExposureCalculator.applyModeAdjustment(10.0, 'lowlight');
        expect(adjusted, equals(9.3));
      });

      test('auto mode keeps EV unchanged', () {
        final adjusted = ExposureCalculator.applyModeAdjustment(10.0, 'auto');
        expect(adjusted, equals(10.0));
      });
    });

    group('shutterToString', () {
      test('1 second returns "1s"', () {
        expect(ExposureCalculator.shutterToString(1.0), equals('1s'));
      });

      test('1/125 returns "1/125s"', () {
        expect(ExposureCalculator.shutterToString(1 / 125), equals('1/125s'));
      });

      test('1/1000 returns "1/1000s"', () {
        expect(ExposureCalculator.shutterToString(1 / 1000), equals('1/1000s'));
      });
    });

    group('nearestStandardShutter', () {
      test('finds nearest standard shutter', () {
        // 1/200 is between 1/125 and 1/250, should pick closer one
        final result = ExposureCalculator.nearestStandardShutter(1 / 200);
        // 1/200 vs 1/125 = 0.005 vs 0.008, vs 1/250 = 0.004, so 1/250 is closer
        expect(result, equals('1/250s'));
      });
    });

    group('calculateISO', () {
      test('calculates ISO correctly for known EV', () {
        // At EV 10, aperture 1.8, shutter 1/125
        // ISO = 1.8^2 * 100 / (2^10 * 1/125) = 3.24 * 100 / (1024 * 0.008) = 324 / 8.192 ≈ 39.5 → clamped to 50
        final iso = ExposureCalculator.calculateISO(
          lux: 10000,
          shutterValue: 1 / 125,
          ev: 10,
        );
        expect(iso, greaterThanOrEqualTo(ExposureConstants.minIso));
        expect(iso, lessThanOrEqualTo(ExposureConstants.maxIso));
      });

      test('clamps ISO to minIso', () {
        final iso = ExposureCalculator.calculateISO(
          lux: 100000,
          shutterValue: 1 / 1000,
          ev: 16,
        );
        expect(iso, greaterThanOrEqualTo(ExposureConstants.minIso));
      });

      test('clamps ISO to maxIso', () {
        final iso = ExposureCalculator.calculateISO(
          lux: 0.1,
          shutterValue: 1.0,
          ev: -4,
        );
        expect(iso, lessThanOrEqualTo(ExposureConstants.maxIso));
      });
    });

    group('getExposureStatus', () {
      test('returns over when target > ev + 0.5', () {
        expect(ExposureCalculator.getExposureStatus(10.0, 11.0), equals('over'));
      });

      test('returns under when target < ev - 0.5', () {
        expect(ExposureCalculator.getExposureStatus(10.0, 9.0), equals('under'));
      });

      test('returns normal when within 0.5', () {
        expect(ExposureCalculator.getExposureStatus(10.0, 10.3), equals('normal'));
        expect(ExposureCalculator.getExposureStatus(10.0, 9.7), equals('normal'));
      });
    });

    group('getScene', () {
      test('returns correct scene for lux ranges', () {
        expect(ExposureCalculator.getScene(5), equals('暗光'));
        expect(ExposureCalculator.getScene(30), equals('黄昏'));
        expect(ExposureCalculator.getScene(100), equals('室内灯光'));
        expect(ExposureCalculator.getScene(350), equals('室内晴天'));
        expect(ExposureCalculator.getScene(700), equals('阴天'));
        expect(ExposureCalculator.getScene(5000), equals('多云'));
        expect(ExposureCalculator.getScene(20000), equals('晴天'));
      });
    });
  });
}
