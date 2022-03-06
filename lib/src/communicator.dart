enum CommunicatorQos { atMostOnce, atLeastOnce, exactlyOnce }

abstract class Communicator {
  final String server = "";
  final int port = 0;
  String username = "";
  String password = "";
  bool autoReconnect = true;

  int publish(String topic, String data,
      {CommunicatorQos qos = CommunicatorQos.atLeastOnce, bool retain = false});
}
