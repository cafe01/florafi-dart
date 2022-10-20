// import 'package:logging/logging.dart';
import 'package:clock/clock.dart';
import 'package:florafi/src/component/component_builder.g.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';
import 'package:florafi/extensions.dart';

void main() {
  late Farm farm;
  late Room room;
  late Ebbflow ebbflow;
  late Device device;

  setUp(() {
    farm = Farm();
    room = Room("r1", farm: farm);
    device = Device(farm: farm, id: 'd1');
    device.room = room;
    ebbflow = ComponentBuilder.fromId('ebbflow', device) as Ebbflow;
    device.components.add(ebbflow);
    farm.devices[device.id] = device;
  });

  group("Ebbflow.isConfigured", () {
    setUp(() {
      farm.setClock(null);
    });

    test('is false if missing dayInterval or nightInterval', () {
      expect(ebbflow.isConfigured, false);
      ebbflow.consumeState("day_interval", "10");
      expect(ebbflow.isConfigured, false);
      ebbflow.consumeState("night_interval", "10");
      expect(ebbflow.isConfigured, true);
    });
  });

  group("Ebbflow.lastEmptyTime", () {
    setUp(() {
      farm.setClock(null);
    });

    test('returns null or DateTime', () {
      expect(ebbflow.lastEmptyTime, null);
      ebbflow.consumeState("last_empty", "0");
      expect(ebbflow.lastEmptyTime,
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
      ebbflow.consumeState("last_empty", "1");
      expect(ebbflow.lastEmptyTime,
          DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true));
    });
  });

  group("Ebbflow.lastEmptyElapsed", () {
    setUp(() {
      farm.setClock(Clock.fixed(DateTime.utc(2022, 5, 11)));
    });

    test('returns null when timestamp is null or zero', () {
      expect(ebbflow.lastEmptyElapsed, null);
      ebbflow.consumeState("last_empty", "0");
      expect(ebbflow.lastEmptyElapsed, null);
    });

    test('returns Duration to now', () {
      final unixTime =
          farm.getClock().hoursAgo(1).millisecondsSinceEpoch ~/ 1000;
      ebbflow.consumeState("last_empty", "$unixTime");
      expect(ebbflow.lastEmptyElapsed, isA<Duration>());
      expect(ebbflow.lastEmptyElapsed, Duration(hours: 1));
    });
  });

  group("Ebbflow.currentPhaseElapsed", () {
    setUp(() {
      farm.setClock(Clock.fixed(DateTime.utc(2022, 5, 11)));
    });

    test('returns null when phase is null or zero', () {
      expect(ebbflow.currentPhaseElapsed, null);
      ebbflow.consumeState("phase", "0");
      expect(ebbflow.currentPhaseElapsed, null);
    });

    test('returns emptyDuration', () {
      final phase = 1;
      final unixTime =
          farm.getClock().hoursAgo(phase).millisecondsSinceEpoch ~/ 1000;
      ebbflow.consumeState("phase", "$phase");
      ebbflow.consumeState("last_empty", "$unixTime");
      expect(ebbflow.currentPhaseElapsed, Duration(hours: phase));
    });

    test('returns drainDuration', () {
      final phase = 2;
      final unixTime =
          farm.getClock().hoursAgo(phase).millisecondsSinceEpoch ~/ 1000;
      ebbflow.consumeState("phase", "$phase");
      ebbflow.consumeState("last_drain", "$unixTime");
      expect(ebbflow.currentPhaseElapsed, Duration(hours: phase));
    });

    test('returns floodDuration', () {
      final phase = 3;
      final unixTime =
          farm.getClock().hoursAgo(phase).millisecondsSinceEpoch ~/ 1000;
      ebbflow.consumeState("phase", "$phase");
      ebbflow.consumeState("last_flood", "$unixTime");
      expect(ebbflow.currentPhaseElapsed, Duration(hours: phase));
    });

    test('returns fullDuration', () {
      final phase = 4;
      final unixTime =
          farm.getClock().hoursAgo(phase).millisecondsSinceEpoch ~/ 1000;
      ebbflow.consumeState("phase", "$phase");
      ebbflow.consumeState("last_full", "$unixTime");
      expect(ebbflow.currentPhaseElapsed, Duration(hours: phase));
    });
  });
}
