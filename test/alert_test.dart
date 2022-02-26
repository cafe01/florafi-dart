import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

void main() {
  group("_processRoomAlertMessage()", () {
    late Farm farm;
    late StreamQueue<FarmEvent> events;

    setUp(() {
      farm = Farm();
      events = StreamQueue<FarmEvent>(farm.events);
    });

    test(r'ignores invalid topic.', () {
      farm.processMessage('florafi/room/r1/alert', '123');
      farm.processMessage('florafi/room/r1/alert/', '123');
      farm.processMessage('florafi/room/r1/alert/info', '123');
      farm.processMessage('florafi/room/r1/alert/info/', '123');

      expect(farm.alerts.length, 0);
    });

    test(r'ignores invalid type.', () {
      farm.processMessage(
          'florafi/room/r1/alert/invalid-type/some-alert', '123');
      expect(farm.alerts.length, 0);
    });

    test(r'handles info alert.', () {
      farm.processMessage('florafi/room/r1/alert/info/info-alert', '123');
      expect(farm.alerts.containsKey('r1.info-alert'), true);
      expect(farm.alerts.length, 1);
      final alert = farm.alerts["r1.info-alert"];
      expect(alert?.roomId, 'r1');
      expect(alert?.id, 'info-alert');
      expect(alert?.type, AlertType.info);
      expect(alert?.timestamp, 123);
      expect(alert?.isActive, true);
    });

    test(r'handles warning alert.', () {
      farm.processMessage('florafi/room/r1/alert/warning/warning-alert', '123');
      expect(farm.alerts.containsKey('r1.warning-alert'), true);
      expect(farm.alerts.length, 1);
      expect(farm.alerts["r1.warning-alert"]?.type, AlertType.warning);
    });

    test(r'handles error alert.', () {
      farm.processMessage('florafi/room/r1/alert/error/error-alert', '123');
      expect(farm.alerts.containsKey('r1.error-alert'), true);
      expect(farm.alerts.length, 1);
      expect(farm.alerts["r1.error-alert"]?.type, AlertType.error);
    });

    test(r'handles alert dismiss.', () {
      farm.processMessage('florafi/room/r1/alert/error/error-alert', '123');
      expect(farm.alerts.containsKey('r1.error-alert'), true);
      expect(farm.alerts.length, 1);

      farm.processMessage('florafi/room/r1/alert/error/error-alert', '');
      expect(farm.alerts.containsKey('r1.error-alert'), false);
      expect(farm.alerts.length, 0);
    });

    test(r'emits alert events.', () async {
      farm.processMessage('florafi/room/r1/alert/error/error-alert', '123');
      expect(farm.alerts.containsKey('r1.error-alert'), true);
      expect(farm.alerts.length, 1);

      events.skip(1); // skip roomInstall event
      var event = await events.next;

      expect(event.type, FarmEventType.alert);
      expect(event.room?.id, "r1");
      expect(event.alert?.id, "error-alert");
      expect(event.alert?.isActive, true);

      farm.processMessage('florafi/room/r1/alert/error/error-alert', '');

      event = await events.next;
      expect(event.type, FarmEventType.alert);
      expect(event.room?.id, "r1");
      expect(event.alert?.id, "error-alert");
      expect(event.alert?.isActive, false);
    });
  });
}
