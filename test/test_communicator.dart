import 'package:florafi/src/communicator.dart';

class TestMessage {
  TestMessage(this.topic, this.message);
  String topic;
  String message;
}

class TestCommunicator extends Communicator {
  List<TestMessage> sentMessages = [];

  @override
  int publish(String topic, String message,
      {CommunicatorQos qos = CommunicatorQos.atLeastOnce,
      bool retain = false}) {
    sentMessages.add(TestMessage(topic, message));
    return sentMessages.length;
  }
}
