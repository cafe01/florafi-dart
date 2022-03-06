// import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

void main() {
  group("Thermometer", () {
    late Farm farm;
    late Room room;
    late Thermometer component;

    setUp(() {
      farm = Farm();
      room = Room('r1', farm: farm);
      component = Thermometer(room);
    });

    test('has informational properties.', () {
      expect(component.isSensor, true);
      expect(component.name, "Termômetro");
      expect(component.measurementName, "Temperatura");
      expect(component.hasDevice, false);
    });

    test('handles lastValue.', () {
      expect(component.lastValue, null);
      component.consumeState("last_value", "20");
      expect(component.lastValue, 20);
    });

    test('handles lowTemperatureLimit.', () {
      expect(component.lowTemperatureLimit, null);
      component.consumeState("low_temperature_limit", "20");
      expect(component.lowTemperatureLimit, 20);
    });

    test('handles highTemperatureLimit.', () {
      expect(component.highTemperatureLimit, null);
      component.consumeState("high_temperature_limit", "20");
      expect(component.highTemperatureLimit, 20);
    });
  });
}
