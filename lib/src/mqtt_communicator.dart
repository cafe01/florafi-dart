import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:florafi/florafi.dart';
import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt/server_client.dart'
    if (dart.library.html) 'mqtt/browser_client.dart' as mqttsetup;
import 'package:typed_data/typed_data.dart';

final _log = Logger('MqttCommunicator');

final _maxIntId = pow(2, 32).toInt();

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
        "florafi_dart_" + Random().nextInt(_maxIntId).toString();

    mqtt = mqttsetup.setup(
        server: server, clientId: clientId, port: port, secure: secure);

    mqtt.setProtocolV311();
    mqtt.autoReconnect = autoReconnect;

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
  ConnectionState get connectionState {
    switch (mqtt.connectionStatus?.state) {
      case MqttConnectionState.connected:
        return ConnectionState.connected;
      case MqttConnectionState.connecting:
        return ConnectionState.connecting;
      case MqttConnectionState.disconnected:
        return ConnectionState.disconnected;
      case MqttConnectionState.disconnecting:
        return ConnectionState.disconnecting;
      case MqttConnectionState.faulted:
        return ConnectionState.faulted;
      default:
        return ConnectionState.unknown;
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
    mqtt.onConnected ??= onConnected;
    mqtt.onDisconnected ??= onDisconnected;
    mqtt.onAutoReconnect ??= onAutoReconnect;
    mqtt.onAutoReconnected ??= onAutoReconnected;

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
    _mqttMessageSubscription?.cancel();
    _mqttMessageSubscription =
        mqtt.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> packets) {
      for (final received in packets) {
        final msg = received.payload as MqttPublishMessage;

        String? data;

        try {
          data = utf8.decode(msg.payload.message);
          _log.fine("received mqtt message on '${received.topic}': $data");
        } on FormatException {
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
  int publishBinary(String topic, Uint8List data,
      {CommunicatorQos qos = CommunicatorQos.atLeastOnce,
      bool retain = false}) {
    final dataBuffer = Uint8Buffer();
    dataBuffer.addAll(data);
    return mqtt.publishMessage(topic, _toMqttQos(qos), dataBuffer,
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
    _mqttMessageSubscription = null;
    mqtt.disconnect();
  }
}
