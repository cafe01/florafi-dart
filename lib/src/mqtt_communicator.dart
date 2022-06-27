import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert' show utf8;

import 'package:florafi/florafi.dart';
import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

final _log = Logger('MqttCommunicator');

class MqttCommunicator extends Communicator {
  late final MqttClient mqtt;

  final StreamController<FarmMessage> _messages =
      StreamController<FarmMessage>.broadcast();

  MqttCommunicator({
    required String server,
    required int port,
    String? username,
    String? password,
    String? clientIdentifier,
    bool autoReconnect = true,
    bool secure = true,
  }) {
    this.server = server;
    this.port = port;
    this.username = username;
    this.password = password;
    clientId = clientIdentifier ??
        "florafi_dart_" + Random().nextInt(1 << 32).toString();

    final client = mqtt = MqttServerClient.withPort(server, clientId, port);
    client.setProtocolV311();
    client.secure = secure;

    client.autoReconnect = autoReconnect;

    messages = _messages.stream;
  }

  MqttQos _toMqttQos(CommunicatorQos qos) {
    switch (qos) {
      case CommunicatorQos.atLeastOnce:
        return MqttQos.atLeastOnce;
      case CommunicatorQos.atMostOnce:
        return MqttQos.atMostOnce;
      case CommunicatorQos.exactlyOnce:
        return MqttQos.exactlyOnce;
    }
  }

  @override
  bool get isConnected =>
      mqtt.connectionStatus?.state == MqttConnectionState.connected;
  @override
  bool get isConnecting =>
      mqtt.connectionStatus?.state == MqttConnectionState.connecting;
  @override
  bool get isDisconnected =>
      mqtt.connectionStatus?.state == MqttConnectionState.disconnected;
  @override
  bool get isDisconnecting =>
      mqtt.connectionStatus?.state == MqttConnectionState.disconnecting;

  StreamSubscription? _mqttMessageSubscription;

  @override
  Future<void> connect() async {
    mqtt.onConnected = onConnected;
    mqtt.onDisconnected = onDisconnected;
    mqtt.onAutoReconnect = onAutoReconnect;
    mqtt.onAutoReconnected = onAutoReconnected;

    _log.fine("Connecting to $server:$port");

    try {
      await mqtt.connect(username, password);
    } on NoConnectionException catch (e) {
      _log.warning("connect() error: $e");
      mqtt.disconnect();
      throw ConnectError(e.toString());
    } on SocketException catch (e) {
      _log.warning("connect() error: $e");
      mqtt.disconnect();
      throw ConnectError(e.toString());
    }

    // stream farm messages
    _mqttMessageSubscription =
        mqtt.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> packets) {
      for (final received in packets) {
        final msg = received.payload as MqttPublishMessage;

        String? data;

        try {
          data = utf8.decode(msg.payload.message);
          _log.fine("received mqtt message on '${received.topic}': $data");
        } on FormatException catch (e) {
          _log.severe(
              "Error parsing mqtt message on '${received.topic}': ${msg.payload.message}");
        }

        if (data != null) {
          _messages.add(
              FarmMessage(received.topic, data, retained: msg.header!.retain));
        }
      }
    });
  }

  @override
  int publish(String topic, String data,
      {CommunicatorQos qos = CommunicatorQos.atLeastOnce,
      bool retain = false}) {
    final dataBuffer = MqttClientPayloadBuilder();
    dataBuffer.addUTF8String(data);
    return mqtt.publishMessage(topic, _toMqttQos(qos), dataBuffer.payload!,
        retain: retain);
  }

  @override
  int? subscribe(String topic, CommunicatorQos qos) {
    _log.fine("subscribing to $topic (qos = ${qos.index})");
    final subscription = mqtt.subscribe(topic, _toMqttQos(qos));
    return subscription?.messageIdentifier;
  }

  @override
  Future<void> disconnect() async {
    await _mqttMessageSubscription?.cancel();
    mqtt.disconnect();
  }
}
