import 'package:test/test.dart';
import 'package:florafi/florafi.dart';
import 'package:florafi/extensions.dart';

void main() {
  group("Daytime", () {
    late Farm farm;

    setUp(() {
      farm = Farm();
      farm.processMessage(
          FarmMessage('florafi/room/r1/state/daytime/duration', '120'));
    });

    test('.dayDuration', () {
      final room = farm.rooms['r1']!;
      final daytime = room.daytime!;

      expect(daytime.dayDuration, isA<Duration>());
      expect(daytime.dayDuration?.inHours, 2);
    });

    test('.nightDuration', () {
      final room = farm.rooms['r1']!;
      final daytime = room.daytime!;

      expect(daytime.nightDuration, isA<Duration>());
      expect(daytime.nightDuration?.inHours, 22);
    });
  });
}
