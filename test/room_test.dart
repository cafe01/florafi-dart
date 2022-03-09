import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

void main() {
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print(
        "${record.time} ${record.loggerName}.${record.level}: ${record.message}");
  });

  group("Room.resolveComponent()", () {
    late Farm farm;
    late Room room;

    setUp(() {
      farm = Farm();
      room = Room('r1', farm: farm);
    });

    test('returns null for unkown component.', () {
      expect(room.resolveComponent('unkownComponent'), null);
    });

    test('handles Daytime.', () {
      expect(room.daytime, null);
      expect(room.resolveComponent('daytime'), isA<Daytime>());
      expect(room.daytime, isA<Daytime>());
      expect(room.daytime, same(room.resolveComponent('daytime')));
    });

    test('handles Dehumidifier.', () {
      expect(room.dehumidifier, null);
      expect(room.resolveComponent('dehumidifier-relay'), isA<Dehumidifier>());
      expect(room.dehumidifier, isA<Dehumidifier>());
      expect(
          room.dehumidifier, same(room.resolveComponent('dehumidifier-relay')));
    });

    test('handles EbbflowDrain.', () {
      expect(room.ebbflowDrain, null);
      expect(room.resolveComponent('ebbflow-drain-relay'), isA<EbbflowDrain>());
      expect(room.ebbflowDrain, isA<EbbflowDrain>());
      expect(room.ebbflowDrain,
          same(room.resolveComponent('ebbflow-drain-relay')));
    });

    test('handles EbbflowFlood.', () {
      expect(room.ebbflowFlood, null);
      expect(room.resolveComponent('ebbflow-flood-relay'), isA<EbbflowFlood>());
      expect(room.ebbflowFlood, isA<EbbflowFlood>());
      expect(room.ebbflowFlood,
          same(room.resolveComponent('ebbflow-flood-relay')));
    });

    test('handles Ebbflow.', () {
      expect(room.ebbflow, null);
      expect(room.resolveComponent('ebbflow'), isA<Ebbflow>());
      expect(room.ebbflow, isA<Ebbflow>());
      expect(room.ebbflow, same(room.resolveComponent('ebbflow')));
    });

    test('handles Exaust.', () {
      expect(room.exaust, null);
      expect(room.resolveComponent('exaust-relay'), isA<Exaust>());
      expect(room.exaust, isA<Exaust>());
      expect(room.exaust, same(room.resolveComponent('exaust-relay')));
    });

    test('handles Humidifier.', () {
      expect(room.humidifier, null);
      expect(room.resolveComponent('humidifier-relay'), isA<Humidifier>());
      expect(room.humidifier, isA<Humidifier>());
      expect(room.humidifier, same(room.resolveComponent('humidifier-relay')));
    });

    test('handles Hygrometer.', () {
      expect(room.hygrometer, null);
      expect(room.resolveComponent('humidity'), isA<Hygrometer>());
      expect(room.hygrometer, isA<Hygrometer>());
      expect(room.hygrometer, same(room.resolveComponent('humidity')));
    });

    test('handles IntervalIrrigation.', () {
      expect(room.intervalIrrigation, null);
      expect(room.resolveComponent('interval-irrigation'),
          isA<IntervalIrrigation>());
      expect(room.intervalIrrigation, isA<IntervalIrrigation>());
      expect(room.intervalIrrigation,
          same(room.resolveComponent('interval-irrigation')));
    });

    test('handles LightSensor.', () {
      expect(room.lightSensor, null);
      expect(room.resolveComponent('light'), isA<LightSensor>());
      expect(room.lightSensor, isA<LightSensor>());
      expect(room.lightSensor, same(room.resolveComponent('light')));
    });

    test('handles Lighting.', () {
      expect(room.lighting, null);
      expect(room.resolveComponent('light-relay'), isA<Lighting>());
      expect(room.lighting, isA<Lighting>());
      expect(room.lighting, same(room.resolveComponent('light-relay')));
    });

    test('handles Thermometer.', () {
      expect(room.thermometer, null);
      expect(room.resolveComponent('temperature'), isA<Thermometer>());
      expect(room.thermometer, isA<Thermometer>());
      expect(room.thermometer, same(room.resolveComponent('temperature')));
    });
  });

  group("Room.removeComponent()", () {
    late Farm farm;
    late Room room;

    setUp(() {
      farm = Farm();
      room = Room('r1', farm: farm);
    });

    test('returns null for unkown component.', () {
      expect(room.removeComponent('unkownComponent'), null);
    });

    test('returns true when component existed.', () {
      room.resolveComponent("daytime");
      expect(room.removeComponent('daytime'), true);
      expect(room.daytime, null);
    });

    test("returns false when component did't exist.", () {
      expect(room.removeComponent('daytime'), false);
    });
  });

  group("Room.hasComponent()", () {
    late Farm farm;
    late Room room;

    setUp(() {
      farm = Farm();
      room = Room('r1', farm: farm);
    });

    test('returns null for unkown component.', () {
      expect(room.hasComponent('unkownComponent'), null);
    });

    test('returns true when component exists.', () {
      room.resolveComponent("daytime");
      expect(room.hasComponent('daytime'), true);
    });

    test("returns false when component dont exist.", () {
      expect(room.hasComponent('daytime'), false);
    });
  });
}
