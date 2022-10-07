import 'package:florafi/src/component/component_builder.g.dart';
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
    late Device device;

    setUp(() {
      farm = Farm();
      device = Device(farm: farm, id: 'd1');
      farm.devices[device.id] = device;
      room = Room('r1', farm: farm);
    });

    test('return null for unknown/inexistent component', () {
      expect(room.getComponent('unkownComponent'), null);
      expect(room.getComponent('thermometer'), null);
    });

    test('return device component', () {
      device.components.add(ComponentBuilder.fromId("thermometer", device));
      expect(room.getComponent('thermometer'), null);
      device.room = room;
      expect(room.getComponent('thermometer'), isA<Thermometer>());
    });
  });

  group("Room.getComponentByType()", () {
    late Farm farm;
    late Room room;
    late Device device;

    setUp(() {
      farm = Farm();
      device = Device(farm: farm, id: 'd1');
      farm.devices[device.id] = device;
      room = Room('r1', farm: farm);
    });

    test('return null for inexistent component', () {
      expect(room.getComponentByType<Thermometer>(), null);
    });

    test('return device component', () {
      device.components.add(ComponentBuilder.fromId("thermometer", device));
      device.room = room;
      expect(room.getComponentByType<Thermometer>(), isA<Thermometer>());
    });
  });

  group("Room.hasComponent()", () {
    late Farm farm;
    late Room room;

    setUp(() {
      farm = Farm();
      room = Room('r1', farm: farm);
    });

    // test('returns null for unkown component.', () {
    //   expect(room.hasComponent('unkownComponent'), null);
    // });

    // test('returns true when component exists.', () {
    //   room.getComponent("daytime");
    //   expect(room.hasComponent('daytime'), true);
    // });

    // test("returns false when component dont exist.", () {
    //   expect(room.hasComponent('daytime'), false);
    // });
  });
}
