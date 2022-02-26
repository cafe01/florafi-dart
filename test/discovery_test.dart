import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

void main() {
  Logger.root.level = Level.SEVERE;
  Logger.root.onRecord.listen((record) {
    print(
        "${record.time} ${record.loggerName}.${record.level}: ${record.message}");
  });

  group("Device discovery", () {
    late Farm farm;
    late StreamQueue<FarmEvent> events;

    final List<FarmMessage> messages = [
      FarmMessage('florafi/device/d1', '{"room":"Q1","deactivated":false}'),
      FarmMessage('florafi/device/d2', '{"room":"Q1","deactivated":true}'),
      FarmMessage('florafi/device/d3', '{"room":"Q2","deactivated":false}'),
    ];

    setUp(() {
      farm = Farm();
      events = StreamQueue<FarmEvent>(farm.events);

      for (var m in messages) {
        farm.processMessage(m.topic, m.data);
      }
    });

    test('emits install events', () async {
      // events generated by 1st message
      var event = await events.next;
      expect(event.type, equals(FarmEventType.roomInstall));
      expect(event.room?.id, "Q1");
      expect(event.device, null);

      event = await events.next;
      expect(event.type, equals(FarmEventType.deviceInstall));
      expect(event.room, null);
      expect(event.device?.id, "d1");

      // 2nd message
      event = await events.next;
      expect(event.type, equals(FarmEventType.deviceInstall));
      expect(event.device?.id, "d2");

      // 3rd message
      event = await events.next;
      expect(event.type, equals(FarmEventType.roomInstall));
      expect(event.room?.id, "Q2");

      event = await events.next;
      expect(event.type, equals(FarmEventType.deviceInstall));
      expect(event.device?.id, "d3");
    });

    test('found 3 devices', () {
      expect(farm.devices.length, equals(3));
    });

    test('found 2 rooms', () {
      expect(farm.rooms.length, equals(2));
    });

    test('handles device "deactivated" flag.', () {
      expect(farm.devices["d1"]?.isDeactivated, equals(false));
      expect(farm.devices["d2"]?.isDeactivated, equals(true));
      expect(farm.devices["d3"]?.isDeactivated, equals(false));
    });

    test('handles updated "deactivated" flag.', () {
      final data = '{"room":"Q1","deactivated":true}';
      farm.processMessage('florafi/device/d1', data);
      expect(farm.devices["d1"]?.isDeactivated, equals(true));
    });

    test('handles updated "room" flag.', () {
      final data = '{"room":"Q3","deactivated":false}';
      farm.processMessage('florafi/device/d1', data);
      expect(farm.devices.length, equals(3));
      expect(farm.rooms.length, equals(3));
    });

    test('handles "forget device" (empty) message.', () {
      farm.processMessage('florafi/device/d1', '');
      expect(farm.devices.length, equals(2));
      expect(farm.devices.containsKey("d1"), equals(false));
      expect(farm.rooms.length, equals(2));
    });

    test('handles malformed topic.', () {
      final data = '{"room":"toBeIgnored","deactivated":false}';
      farm.processMessage('florafi/device', data);
      farm.processMessage('florafi/device/', data);
      farm.processMessage('florafi/device/d4/', data);
      farm.processMessage('florafi/device/d5/trailingSubTopic', data);

      expect(farm.devices.length, equals(3));
      expect(farm.rooms.length, equals(2));
    });

    test('handles malformed message (missing "room" key).', () {
      final data = '{"deactivated":false}';
      farm.processMessage('florafi/device/d4', data);

      expect(farm.devices.length, equals(3));
      expect(farm.rooms.length, equals(2));
    });

    test('handles malformed message (missing "deactivated" key).', () {
      final data = '{"room": "toBeIgnored"}';
      farm.processMessage('florafi/device/d4', data);

      expect(farm.devices.length, equals(3));
      expect(farm.rooms.length, equals(2));
    });

    test('handles empty "room" key.', () {
      final data = '{"room":"","deactivated":false}';
      farm.processMessage('florafi/device/d4', data);

      expect(farm.devices.length, equals(4));
      expect(farm.rooms.length, equals(2));
    });

    test('handles null "room" key.', () {
      final data = '{"room":null,"deactivated":false}';
      farm.processMessage('florafi/device/d4', data);

      expect(farm.devices.length, equals(4));
      expect(farm.rooms.length, equals(2));
    });
  });
}
