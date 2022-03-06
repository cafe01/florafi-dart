import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

void main() {
  group("_processRoomNotificationMessage()", () {
    late Farm farm;
    late StreamQueue<FarmEvent> events;

    setUp(() {
      farm = Farm();
      events = StreamQueue<FarmEvent>(farm.events);
      events.skip(1); // roomInstall
    });

    test(r'just works.', () async {
      farm.processMessage('florafi/room/r1/notification', 'foobar');
      final event = await events.next;
      final notification = event.notification;
      expect(event.room?.id, 'r1');
      expect(notification?.roomId, 'r1');
      expect(notification?.message, 'foobar');
      expect(notification?.time is DateTime, true);
      expect(notification?.time.isUtc, false);
    });
  });
}
