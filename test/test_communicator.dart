import 'package:florafi/src/communicator.dart';

class TestMessage {
  TestMessage(this.topic, this.message);
  String topic;
  String message;
}

class TestCommunicator extends Communicator {
  int publishedCounter = 0;
  List<TestMessage> sentMessages = [];
  int subscriptionId = 0;
  Map<String, CommunicatorQos> subscriptions = {};

  @override
  int publish(String topic, String message,
      {CommunicatorQos qos = CommunicatorQos.atLeastOnce,
      bool retain = false}) {
    sentMessages.add(TestMessage(topic, message));
    return ++publishedCounter;
  }

  @override
  Future<void> connect() async {
    if (onConnected != null) {
      onConnected!();
    }
  }

  @override
  int? subscribe(String topic, CommunicatorQos qos) {
    subscriptions[topic] = qos;
    return ++subscriptionId;
  }

  @override
  void disconnect() {
    if (onDisconnected != null) {
      onDisconnected!();
    }
  }
}
