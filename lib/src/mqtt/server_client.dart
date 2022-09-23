import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient setup(
    {required String server,
    required String clientId,
    required int port,
    bool secure = true}) {
  final client = MqttServerClient.withPort(server, clientId, port);
  if (secure) client.secure = true;
  return client;
}
