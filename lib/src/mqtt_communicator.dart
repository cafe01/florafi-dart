import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert' show utf8;

import 'package:florafi/florafi.dart';
import 'package:florafi/src/communicator.dart';
import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

final _log = Logger('MqttCommunicator');

class MqttCommunicator extends Communicator {
  late final MqttClient mqtt;

  final StreamController<FarmMessage> _messages =
      StreamController<FarmMessage>.broadcast();

  MqttCommunicator(
      {required String server,
      required int port,
      required String username,
      required String password,
      String? clientIdentifier,
      bool autoReconnect = true}) {
    this.server = server;
    this.port = port;
    this.username = username;
    this.password = password;
    clientId = clientIdentifier ?? Random().nextInt(1 << 32).toString();

    final client = mqtt = MqttServerClient.withPort(server, clientId, port);
    client.setProtocolV311();
    client.secure = true;

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

  StreamSubscription? _messageSubscription;

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
      _log.fine("connect() error: $e");
      mqtt.disconnect();
      throw ConnectError(e.toString());
    } on SocketException catch (e) {
      _log.fine("connect() error: $e");
      mqtt.disconnect();
      throw ConnectError(e.toString());
    }

    // stream farm messages
    _messageSubscription =
        mqtt.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> packets) {
      for (final received in packets) {
        _log.fine("received message on topic '${received.topic}'");
        final msg = received.payload as MqttPublishMessage;
        final data = utf8.decode(msg.payload.message);
        _messages.add(
            FarmMessage(received.topic, data, retained: msg.header!.retain));
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
    await _messageSubscription?.cancel();
    mqtt.disconnect();
  }
}
