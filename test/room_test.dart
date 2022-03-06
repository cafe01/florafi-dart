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

    test('handles Thermometer.', () {
      expect(room.thermometer, null);
      expect(room.resolveComponent('thermometer'), isA<Thermometer>());
      expect(room.resolveComponent('temperature'), isA<Thermometer>());
      expect(room.thermometer, isA<Thermometer>());
      expect(room.thermometer, same(room.resolveComponent('thermometer')));
    });
  });
}
