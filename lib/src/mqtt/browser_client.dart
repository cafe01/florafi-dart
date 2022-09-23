import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient setup(
    {required String server,
    required String clientId,
    required int port,
    bool secure = true}) {
  String scheme;
  if (secure) {
    scheme = "wss://";
  } else {
    scheme = "ws://";
  }
  final client = MqttBrowserClient.withPort("$scheme$server", clientId, port);
  return client;
}
