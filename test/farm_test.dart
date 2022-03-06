import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

import 'test_communicator.dart';

void main() {
  group("Farm.communicator", () {
    late Farm farm;
    late TestCommunicator communicator;
    // late StreamQueue<FarmEvent> events;

    setUp(() {
      farm = Farm();
      communicator = TestCommunicator();
      farm.communicator = communicator;
      // events = StreamQueue<FarmEvent>(farm.events);
      // events.skip(1); // roomInstall
    });

    test('handles publish()', () {
      farm.publish("t1", "m1");
      var msg = communicator.sentMessages.removeAt(0);
      expect(msg.topic, "t1");
      expect(msg.message, "m1");
    });
  });
}
