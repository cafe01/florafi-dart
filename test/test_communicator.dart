import 'dart:typed_data';

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

  bool _isConnected = false;

  @override
  ConnectionState get connectionState {
    return _isConnected
        ? ConnectionState.connected
        : ConnectionState.disconnected;
  }

  @override
  int publish(String topic, String message,
      {CommunicatorQos qos = CommunicatorQos.atLeastOnce,
      bool retain = false}) {
    sentMessages.add(TestMessage(topic, message));
    return ++publishedCounter;
  }

  @override
  Future<void> connect() async {
    _isConnected = true;
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
    _isConnected = false;
    if (onDisconnected != null) {
      onDisconnected!();
    }
  }

  @override
  int publishBinary(String topic, Uint8List data,
      {CommunicatorQos qos = CommunicatorQos.atLeastOnce,
      bool retain = false}) {
    throw UnimplementedError();
  }
}
