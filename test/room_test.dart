import 'package:clock/clock.dart';
import 'package:florafi/src/component/component_builder.g.dart';
import 'package:florafi/src/component/extension/daytime.ext.dart';
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

  group("Daytime config", () {
    late Farm farm;
    late Room room;

    setUp(() {
      farm = Farm(clock: Clock.fixed(DateTime.utc(2022, 5, 11, 3)));
      room = farm.rooms["r1"] = Room("r1", farm: farm);

      farm.processMessage(FarmMessage('florafi/room/r1/config/daytime/duration',
          Duration(hours: 2).inSeconds.toString()));
    });

    test('.dayDuration', () {
      expect(room.dayDuration, isA<Duration>());
      expect(room.dayDuration?.inHours, 2);
    });

    test('.nightDuration', () {
      expect(room.nightDuration, isA<Duration>());
      expect(room.nightDuration?.inHours, 22);
    });
  });

  group("Daytime on Room extension", () {
    late Farm farm;
    late Room room;

    final now = DateTime.utc(2022, 5, 11, 12);
    final dayDuration = Duration(hours: 12);

    final oneSecond = Duration(seconds: 1);
    final oneHour = Duration(hours: 1);
    final oneDay = Duration(days: 1);

    setUp(() {
      farm = Farm(clock: Clock.fixed(now));
      room = farm.rooms["r1"] = Room("r1", farm: farm);

      // start
      farm.processMessage(FarmMessage('florafi/room/r1/config/daytime/start',
          (now.hour * 60 * 60).toString()));

      // duration
      farm.processMessage(FarmMessage('florafi/room/r1/config/daytime/duration',
          dayDuration.inSeconds.toString()));
    });

    test('.dayStartTime', () {
      expect(room.dayStartTime, isA<DateTime>());
      expect(room.dayStartTime?.isAtSameMomentAs(now), true);
    });

    test('.nightStartTime', () {
      expect(room.nightStartTime, isA<DateTime>());
      expect(room.nightStartTime?.isAtSameMomentAs(now.add(dayDuration)), true);

      farm.setClock(Clock.fixed(now.subtract(oneHour)));
      expect(room.nightStartTime?.toString(),
          now.subtract(oneDay).add(dayDuration).toString());
    });

    test('.isDaytime', () {
      expect(room.isDaytime, true);

      farm.setClock(Clock.fixed(now.add(dayDuration)));
      expect(room.isDaytime, false);

      farm.setClock(Clock.fixed(now.add(dayDuration).subtract(oneSecond)));
      expect(room.isDaytime, true);
    });

    test('.dayElapsed', () {
      farm.setClock(Clock.fixed(now));
      expect(room.dayElapsed?.inSeconds, 0);
      farm.setClock(Clock.fixed(now.add(oneHour)));
      expect(room.dayElapsed?.inSeconds, oneHour.inSeconds);
    });

    test('.dayRemaining', () {
      farm.setClock(Clock.fixed(now));
      expect(room.dayRemaining?.inSeconds, dayDuration.inSeconds);

      farm.setClock(Clock.fixed(now.add(oneHour)));
      expect(room.dayRemaining?.inSeconds,
          dayDuration.inSeconds - oneHour.inSeconds);
    });

    test('.nightElapsed', () {
      farm.setClock(Clock.fixed(now.add(dayDuration)));
      expect(room.nightElapsed?.inSeconds, 0);
      farm.setClock(Clock.fixed(now.add(dayDuration).add(oneHour)));
      expect(room.nightElapsed?.inSeconds, oneHour.inSeconds);
    });

    test('.nightRemaining', () {
      farm.setClock(Clock.fixed(now.add(dayDuration)));
      expect(room.nightRemaining?.inSeconds, room.nightDuration?.inSeconds);

      farm.setClock(Clock.fixed(now.add(dayDuration).add(oneHour)));
      expect(room.nightRemaining?.inSeconds,
          room.nightDuration!.inSeconds - oneHour.inSeconds);
    });

    test('.dayProgress', () {
      farm.setClock(Clock.fixed(now));
      expect(room.dayProgress, 0);

      farm.setClock(
          Clock.fixed(now.add(Duration(seconds: dayDuration.inSeconds ~/ 2))));
      expect(room.dayProgress, 0.5);
    });

    test('.nightProgress', () {
      farm.setClock(Clock.fixed(now.add(dayDuration)));
      expect(room.nightProgress, 0);

      farm.setClock(Clock.fixed(
          now.subtract(Duration(hours: room.nightDuration!.inHours ~/ 2))));
      expect(room.nightProgress, 0.5);
    });

    test('.phaseStartTime', () {
      farm.setClock(Clock.fixed(now));
      expect(room.phaseStartTime, room.dayStartTime);

      farm.setClock(Clock.fixed(now.add(dayDuration)));
      expect(room.phaseStartTime, room.nightStartTime);
    });

    test('.phaseProgress', () {
      farm.setClock(Clock.fixed(now));
      expect(room.phaseProgress, room.dayProgress);

      farm.setClock(Clock.fixed(now.add(dayDuration)));
      expect(room.phaseProgress, room.nightProgress);
    });
  });
}
