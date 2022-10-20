import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';
import 'package:florafi/extensions.dart';

void main() {
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
}
