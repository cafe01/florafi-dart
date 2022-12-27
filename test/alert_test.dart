import 'package:async/async.dart';
import 'package:florafi/src/component/component_builder.g.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

import 'test_communicator.dart';

void main() {
  // late StreamQueue<FarmEvent> events;

  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print(
        "${record.time} ${record.loggerName}.${record.level}: ${record.message}");
  });

  group("Farm._processFlorafiDeviceMessage", () {
    late Farm farm;
    late TestCommunicator communicator;

    setUp(() {
      farm = Farm();
      communicator = farm.communicator = TestCommunicator();

      // test device
      farm.processMessage(FarmMessage('florafi/device/d1',
          '{"room":"1","deactivated":false, "components":["light"]}'));
    });

    test('subscribes to component topics', () {
      expect(
          communicator.subscriptions
              .containsKey("florafi/device/d1/component/light/#"),
          true);
    });
  });

  test("Alert.resolveType", () {
    expect(Alert.resolveType("info"), AlertType.info);
    expect(Alert.resolveType("warning"), AlertType.warning);
    expect(Alert.resolveType("error"), AlertType.error);
  });

  group("Farm._processComponentAlertMessage", () {
    late Farm farm;
    late StreamQueue<FarmEvent> events;
    // late TestCommunicator communicator;

    setUpAll(() async {
      farm = Farm();
      // communicator = farm.communicator = TestCommunicator();
      events = StreamQueue<FarmEvent>(farm.events);

      // test device
      farm.processMessage(FarmMessage('florafi/device/d1',
          '{"room":"1","deactivated":false, "components":["light"]}'));

      // drain
      events.skip(5);
    });

    tearDownAll(() async {
      await events.cancel();
    });

    test('add active alert to component', () async {
      farm.processMessage(FarmMessage(
          'florafi/device/d1/component/light/alert/test-alert',
          '{"timestamp":1, "type": "info"}'));

      final component = farm.devices["d1"]!.getComponentById("light")!;
      expect(component.alerts.length, 1);
      expect(component.alerts.first.isActive, true);
      expect(component.alerts.first.timestamp, 1);
      expect(component.alerts.first.type, AlertType.info);

      // farm event
      final event = await events.next;
      expect(event.type, FarmEventType.roomAlert);
      expect(event.alert, component.alerts.first);
    });

    test('update active alert timestamp', () async {
      farm.processMessage(FarmMessage(
          'florafi/device/d1/component/light/alert/test-alert',
          '{"timestamp":2, "type": "info"}'));

      final component = farm.devices["d1"]!.getComponentById("light")!;
      expect(component.alerts.length, 1);
      expect(component.alerts.first.id, "test-alert");
      expect(component.alerts.first.isActive, true);
      expect(component.alerts.first.timestamp, 2);
      expect(component.alerts.first.type, AlertType.info);

      final event = await events.next;
      expect(event.type, FarmEventType.roomAlert);
      expect(event.alert, component.alerts.first);
    });

    test('remove inactive alert from component', () async {
      farm.processMessage(FarmMessage(
          'florafi/device/d1/component/light/alert/test-alert',
          '{"timestamp":0, "type": "info"}'));

      final component = farm.devices["d1"]!.getComponentById("light")!;

      expect(component.alerts.length, 0);

      final event = await events.next;
      expect(event.type, FarmEventType.roomAlert);
      expect(event.alert?.isActive, false);
      expect(event.alert?.timestamp, 0);
      expect(event.alert?.id, "test-alert");
    });
  });
}
