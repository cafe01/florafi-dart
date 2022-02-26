import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

void main() {
  group("_processRoomLogMessage()", () {
    late Farm farm;
    late StreamQueue<FarmEvent> events;

    final logJson =
        '{"message":"Some message","time":1645894274,"device":"d1","component":"c1"}';

    setUp(() {
      farm = Farm();
      farm.logListSize = 3;
      events = StreamQueue<FarmEvent>(farm.events);
    });

    test(r'ignores invalid topic.', () {
      farm.processMessage('florafi/room/r1/log', logJson);
      farm.processMessage('florafi/room/r1/log/', logJson);
      expect(farm.logList.length, 0);
    });

    test(r'ignores invalid log level.', () {
      farm.processMessage('florafi/room/r1/log/invalid-level', logJson);
      expect(farm.logList.length, 0);
    });

    test(r'handles "debug" log.', () {
      farm.processMessage('florafi/room/r1/log/debug', logJson);
      expect(farm.logList.length, 1);
      final logLine = farm.logList[0];
      expect(logLine.level, LogLevel.debug);
      expect(logLine.message, "Some message");
      expect(logLine.roomId, "r1");
      expect(logLine.deviceId, "d1");
      expect(logLine.componentId, "c1");
      expect(logLine.time,
          DateTime.fromMillisecondsSinceEpoch(1645894274 * 1000, isUtc: true));
    });

    test(r'handles "info" log.', () {
      farm.processMessage('florafi/room/r1/log/info', logJson);
      expect(farm.logList.length, 1);
      expect(farm.logList[0].level, LogLevel.info);
    });

    test(r'handles "warning" log.', () {
      farm.processMessage('florafi/room/r1/log/warning', logJson);
      expect(farm.logList.length, 1);
      expect(farm.logList[0].level, LogLevel.warning);
    });

    test(r'handles "error" log.', () {
      farm.processMessage('florafi/room/r1/log/error', logJson);
      expect(farm.logList.length, 1);
      expect(farm.logList[0].level, LogLevel.error);
    });

    test('handles log storage.', () {
      farm.logListSize = 0;
      farm.processMessage('florafi/room/r1/log/debug', logJson);
      expect(farm.logList.length, 0);

      farm.logListSize = 2;
      farm.processMessage('florafi/room/r1/log/debug', logJson);
      expect(farm.logList.length, 1);
      farm.processMessage('florafi/room/r1/log/info', logJson);
      expect(farm.logList.length, 2);
      farm.processMessage('florafi/room/r1/log/warning', logJson);
      expect(farm.logList.length, 2);
    });

    test(r'emits "log" event.', () async {
      farm.processMessage('florafi/room/r1/log/error', logJson);
      events.skip(1); // skip roomInstall
      final event = await events.next;
      expect(event.type, FarmEventType.log);
      expect(event.log, farm.logList[0]);
      expect(event.room?.id, "r1");
    });
  });
}
