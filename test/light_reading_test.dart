import 'package:flutter_test/flutter_test.dart';
import 'package:light_meter_app/domain/models/light_reading.dart';

void main() {
  group('LightReading', () {
    test('fromLux creates reading with current timestamp', () {
      final reading = LightReading.fromLux(500);
      expect(reading.lux, equals(500));
      expect(reading.accuracy, equals(0));
      expect(reading.timestamp, isNotNull);
    });

    test('isValid returns true for normal lux range', () {
      expect(LightReading.fromLux(100).isValid, isTrue);
      expect(LightReading.fromLux(50000).isValid, isTrue);
    });

    test('isValid returns false for zero or negative lux', () {
      expect(LightReading.fromLux(0).isValid, isFalse);
      expect(LightReading.fromLux(-100).isValid, isFalse);
    });

    test('isValid returns false for extremely high lux', () {
      expect(LightReading.fromLux(1000000).isValid, isFalse);
    });
  });
}
