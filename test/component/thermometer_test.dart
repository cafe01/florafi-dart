// import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

import '../test_communicator.dart';

void main() {
  group("Thermometer", () {
    late Farm farm;
    late TestCommunicator communicator;
    late Room room;
    late Thermometer component;

    setUp(() {
      farm = Farm();
      communicator = TestCommunicator();
      farm.communicator = communicator;
      room = Room('r1', farm: farm);
      component = Thermometer(room: room, mqttId: "thermometer");
    });

    test('has informational properties.', () {
      // expect(component.isSensor, true);
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

    test('can set lowTemperatureLimit.', () {
      component.lowTemperatureLimit = 10;
      expect(communicator.sentMessages.length, 0);
      component.consumeControl("low_temperature_limit", "control1");
      component.lowTemperatureLimit = 20;
      final msg = communicator.sentMessages[0];
      expect(msg.topic, "control1");
      expect(msg.message, "20");
    });

    test('can set highTemperatureLimit.', () {
      component.highTemperatureLimit = 10;
      expect(communicator.sentMessages.length, 0);
      component.consumeControl("high_temperature_limit", "control2");
      component.highTemperatureLimit = 20;
      final msg = communicator.sentMessages[0];
      expect(msg.topic, "control2");
      expect(msg.message, "20");
    });
  });
}
