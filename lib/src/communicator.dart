import 'dart:async';
import 'dart:typed_data';

import 'farm.dart' show FarmMessage;

enum CommunicatorQos { atMostOnce, atLeastOnce, exactlyOnce }

enum FarmConnectionState {
  disconnecting,

  disconnected,

  connecting,

  connected,

  faulted,

  unknown,
}

extension FarmConnectionStateX on FarmConnectionState {
  bool get isConnecting => this == FarmConnectionState.connecting;
  bool get isDisconnected => this == FarmConnectionState.disconnected;
}

typedef Callback = void Function();

class ConnectError implements Exception {
  final String message;
  ConnectError(this.message);
  @override
  String toString() {
    return "ConnectError: $message";
  }
}

abstract class Communicator {
  late final String server;
  late final int port;
  late final String? username;
  late final String? password;
  late final String clientId;
  // bool autoReconnect = true;

  late final Stream<FarmMessage> messages;

  // TODO make callbacks a list

  /// Client disconnect callback, called on unsolicited disconnect.
  /// This will not be called even if set if [autoConnect} is set,instead
  /// [onAutoReconnect] will be called.
  Callback? onDisconnected;

  /// Client connect callback, called on successful connect
  Callback? onConnected;

  /// Auto reconnect callback, if auto reconnect is selected this callback will
  /// be called before auto reconnect processing is invoked to allow the user to
  /// perform any pre auto reconnect actions.
  Callback? onAutoReconnect;

  /// Auto reconnected callback, if auto reconnect is selected this callback will
  /// be called after auto reconnect processing is completed to allow the user to
  /// perform any post auto reconnect actions.
  Callback? onAutoReconnected;

  Future<void> connect();
  void disconnect();

  bool get isConnected => false;
  bool get isConnecting => false;
  bool get isDisconnected => false;
  bool get isDisconnecting => false;

  FarmConnectionState get connectionState;

  int publish(String topic, String data,
      {CommunicatorQos qos = CommunicatorQos.atLeastOnce, bool retain = false});

  int publishBinary(String topic, Uint8List data,
      {CommunicatorQos qos = CommunicatorQos.atLeastOnce, bool retain = false});

  int? subscribe(String topic, CommunicatorQos qos);
  void unsubscribe(String topic);
}
