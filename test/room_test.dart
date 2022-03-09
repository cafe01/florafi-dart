import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

void main() {
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print(
        "${record.time} ${record.loggerName}.${record.level}: ${record.message}");
  });

  group("Room.getComponent()", () {
    late Farm farm;
    late Room room;

    setUp(() {
      farm = Farm();
      room = Room('r1', farm: farm);
    });

    test('throws expection for unkown component.', () {
      mustThrow() => room.getComponent('unkownComponent');
      expect(mustThrow, throwsA(isA<UnknownComponentError>()));
    });

    test('handles Daytime.', () {
      expect(room.daytime, null);
      expect(room.getComponent('daytime'), isA<Daytime>());
      expect(room.daytime, isA<Daytime>());
      expect(room.daytime, same(room.getComponent('daytime')));
    });

    test('handles Dehumidifier.', () {
      expect(room.dehumidifier, null);
      expect(room.getComponent('dehumidifier-relay'), isA<Dehumidifier>());
      expect(room.dehumidifier, isA<Dehumidifier>());
      expect(room.dehumidifier, same(room.getComponent('dehumidifier-relay')));
    });

    test('handles EbbflowDrain.', () {
      expect(room.ebbflowDrain, null);
      expect(room.getComponent('ebbflow-drain-relay'), isA<EbbflowDrain>());
      expect(room.ebbflowDrain, isA<EbbflowDrain>());
      expect(room.ebbflowDrain, same(room.getComponent('ebbflow-drain-relay')));
    });

    test('handles EbbflowFlood.', () {
      expect(room.ebbflowFlood, null);
      expect(room.getComponent('ebbflow-flood-relay'), isA<EbbflowFlood>());
      expect(room.ebbflowFlood, isA<EbbflowFlood>());
      expect(room.ebbflowFlood, same(room.getComponent('ebbflow-flood-relay')));
    });

    test('handles Ebbflow.', () {
      expect(room.ebbflow, null);
      expect(room.getComponent('ebbflow'), isA<Ebbflow>());
      expect(room.ebbflow, isA<Ebbflow>());
      expect(room.ebbflow, same(room.getComponent('ebbflow')));
    });

    test('handles Exaust.', () {
      expect(room.exaust, null);
      expect(room.getComponent('exaust-relay'), isA<Exaust>());
      expect(room.exaust, isA<Exaust>());
      expect(room.exaust, same(room.getComponent('exaust-relay')));
    });

    test('handles Humidifier.', () {
      expect(room.humidifier, null);
      expect(room.getComponent('humidifier-relay'), isA<Humidifier>());
      expect(room.humidifier, isA<Humidifier>());
      expect(room.humidifier, same(room.getComponent('humidifier-relay')));
    });

    test('handles Hygrometer.', () {
      expect(room.hygrometer, null);
      expect(room.getComponent('humidity'), isA<Hygrometer>());
      expect(room.hygrometer, isA<Hygrometer>());
      expect(room.hygrometer, same(room.getComponent('humidity')));
    });

    test('handles IntervalIrrigation.', () {
      expect(room.intervalIrrigation, null);
      expect(
          room.getComponent('interval-irrigation'), isA<IntervalIrrigation>());
      expect(room.intervalIrrigation, isA<IntervalIrrigation>());
      expect(room.intervalIrrigation,
          same(room.getComponent('interval-irrigation')));
    });

    test('handles LightSensor.', () {
      expect(room.lightSensor, null);
      expect(room.getComponent('light'), isA<LightSensor>());
      expect(room.lightSensor, isA<LightSensor>());
      expect(room.lightSensor, same(room.getComponent('light')));
    });

    test('handles Lighting.', () {
      expect(room.lighting, null);
      expect(room.getComponent('light-relay'), isA<Lighting>());
      expect(room.lighting, isA<Lighting>());
      expect(room.lighting, same(room.getComponent('light-relay')));
    });

    test('handles Thermometer.', () {
      expect(room.thermometer, null);
      expect(room.getComponent('temperature'), isA<Thermometer>());
      expect(room.thermometer, isA<Thermometer>());
      expect(room.thermometer, same(room.getComponent('temperature')));
    });
  });

  group("Room.removeComponent()", () {
    late Farm farm;
    late Room room;

    setUp(() {
      farm = Farm();
      room = Room('r1', farm: farm);
    });

    test('throws expection for unkown component.', () {
      mustThrow() => room.removeComponent('unkownComponent');
      expect(mustThrow, throwsA(isA<UnknownComponentError>()));
    });

    test('returns true when component existed.', () {
      room.getComponent("daytime");
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
      room.getComponent("daytime");
      expect(room.hasComponent('daytime'), true);
    });

    test("returns false when component dont exist.", () {
      expect(room.hasComponent('daytime'), false);
    });
  });
}
