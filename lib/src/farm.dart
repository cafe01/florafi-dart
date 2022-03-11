import 'dart:async';
import 'dart:convert';
import 'package:florafi/florafi.dart';
import 'package:florafi/src/communicator.dart';
import 'package:florafi/src/notification.dart';
import 'package:logging/logging.dart';

class FarmMessage {
  String topic;
  late List<String> topicParts;
  String data;
  bool retained;

  FarmMessage(this.topic, this.data, {this.retained = false}) {
    topicParts = topic.split("/");
  }

  String shiftTopic() {
    return topicParts.removeAt(0);
  }
}

class Farm {
  final _log = Logger('Farm');

  Map<String, Device> devices = {};
  Map<String, Room> rooms = {};
  Map<String, Alert> alerts = {};

  late final StreamController<FarmEvent> _events =
      StreamController<FarmEvent>.broadcast();

  Stream<FarmEvent> get events {
    return _events.stream;
  }

  int logListSize = 0;
  final List<LogLine> logList = [];

  Communicator? communicator;

  final String name;
  final int id;

  Farm({this.name = "", this.id = 0, this.communicator});

  void _emit(FarmEventType eventType,
      {Room? room,
      Device? device,
      Alert? alert,
      Notification? notification,
      LogLine? log}) {
    final event = FarmEvent(eventType,
        farm: this,
        room: room,
        device: device,
        alert: alert,
        notification: notification,
        log: log);
    _events.add(event);
  }

  void _onConnected() {
    _emit(FarmEventType.farmConnected);
  }

  void _onDisconnected() {
    _emit(FarmEventType.farmDisconnected);
  }

  void _onAutoReconnect() {
    _emit(FarmEventType.farmReconnect);
  }

  void _onAutoReconnected() {
    _emit(FarmEventType.farmReconnected);
  }

  Future<void> connect() async {
    if (communicator == null) {
      throw StateError("set communicator before calling connect()");
    }
    communicator!.onConnected = _onConnected;
    communicator!.onDisconnected = _onDisconnected;
    communicator!.onAutoReconnect = _onAutoReconnect;
    communicator!.onAutoReconnected = _onAutoReconnected;
    try {
      await communicator!.connect();
    } on ConnectError {
      _emit(FarmEventType.farmConnectError);
    }
    communicator!.messages.listen((message) {
      processMessage(message);
    });
  }

  void publish(String topic, String message,
      {retain = false, qos = CommunicatorQos.atLeastOnce}) {
    if (communicator == null) {
      throw Exception("Can't publish() before connect()");
    }

    _log.fine("publishing to $topic: $message (retain: $retain, qos: $qos)");
    communicator!.publish(topic, message);
  }

  int? subscribe(String topic, [qos = CommunicatorQos.atLeastOnce]) {
    if (communicator == null) {
      throw Exception("Can't subscribe before connect()");
    }
    return communicator!.subscribe(topic, qos);
  }

  Room _discoverRoom(String id) {
    // return existing
    if (rooms.containsKey(id)) {
      return rooms[id]!;
    }

    // install
    final room = rooms[id] = Room(id, farm: this);
    _emit(FarmEventType.roomInstall, room: room);
    return room;
  }

  Device _discoverDevice(String id) {
    // return existing
    if (devices.containsKey(id)) {
      return devices[id]!;
    }

    // install
    final device = devices[id] = Device(id);
    _emit(FarmEventType.deviceInstall, device: device);

    return device;
  }

  void processMessage(FarmMessage message) {
    if (message.topicParts.isEmpty) {
      throw StateError("Invalid farm message: topicParts is empty! Wtf?!");
    }

    final messageType = message.shiftTopic();

    if (messageType == "florafi") {
      _processFlorafiMessage(message);
    } else if (messageType == "homie") {
      _processHomieMessage(message);
    } else {
      _log.warning("Unknown message topic '${message.topic}'");
    }
  }

  void _processFlorafiMessage(FarmMessage message) {
    if (message.topicParts.isEmpty) {
      _log.warning(
          "Ignoring invalid florafi message. (topic: ${message.topic})");
      return;
    }

    final subtopic = message.shiftTopic();

    if (subtopic == "room") {
      _processRoomMessage(message);
    } else if (subtopic == "device") {
      _processFlorafiDeviceMessage(message);
    } else {
      _log.warning("Unknown florafi message type '${message.topic}'");
    }
  }

  void _processFlorafiDeviceMessage(FarmMessage message) {
    if (message.topicParts.length != 1 || message.topicParts[0].isEmpty) {
      _log.warning("Malformed device discovery message: "
          "missing device id subtopic. (${message.topic}) (${message.topicParts.length})");
      return;
    }

    final deviceId = message.shiftTopic();

    // forget device
    if (message.data.isEmpty) {
      if (devices.containsKey(deviceId)) {
        devices.remove(deviceId);
        // TODO remove device from from room
        // emit event
      } else {
        _log.warning("Received 'forget device' message "
            "for unknown device '$deviceId'");
      }

      return;
    }

    // parse message
    final Map<String, dynamic> discoveryMsg =
        Map.castFrom(jsonDecode(message.data));

    final roomId = discoveryMsg["room"] as String?;
    final deactivated = discoveryMsg["deactivated"] as bool?;

    // invalid discovery message
    if (!discoveryMsg.containsKey("room") ||
        !discoveryMsg.containsKey("deactivated") ||
        deactivated == null) {
      return _log.warning("Invalid device discovery message. "
          "(${message.topic}: ${message.data})");
    }

    // discover room
    if (roomId != null && roomId.isNotEmpty) {
      _discoverRoom(roomId);
    }

    // discover device
    final device = _discoverDevice(deviceId);
    device.isDeactivated = deactivated;
  }

  void _processRoomMessage(FarmMessage msg) {
    // invalid: missing room id
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return _log.warning(
          "Invalid room message: missing room id. (topic: ${msg.topic})");
    }

    final roomId = msg.shiftTopic();

    // invalid: missing subtopic
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return _log.warning(
          "Invalid room message: missing subtopic. (topic: ${msg.topic})");
    }

    final room = _discoverRoom(roomId);
    final subtopic = msg.shiftTopic();

    switch (subtopic) {
      case "state":
        _processRoomStateMessage(room, msg);
        break;
      case "log":
        _processRoomLogMessage(room, msg);
        break;
      case "control":
        _processRoomControlMessage(room, msg);
        break;
      case "device":
        _processRoomDeviceMessage(room, msg);
        break;
      case "alert":
        _processRoomAlertMessage(room, msg);
        break;
      case "notification":
        _processRoomNotificationMessage(room, msg);
        break;
      default:
        _log.fine("Unknown room message type: $subtopic");
    }
  }

  void _processRoomStateMessage(Room room, FarmMessage msg) {
    // invalid topic
    if (msg.topicParts.length != 2 || msg.topicParts[1].isEmpty) {
      _log.warning("Invalid state message. (topic: ${msg.topic}");
      return;
    }

    // resolve component
    final componentId = msg.shiftTopic();

    if (room.hasComponent(componentId) == null) {
      _log.warning('Invalid state message: '
          'unknown component "$componentId" (topic: ${msg.topic})');
      return;
    }

    final component = room.getComponent(componentId);

    // consume
    final propertyId = msg.shiftTopic();
    component.consumeState(propertyId, msg.data);

    //  emit event
    _emit(FarmEventType.roomState, room: room);
  }

  void _processRoomControlMessage(Room room, FarmMessage msg) {
    // invalid topic
    if (msg.topicParts.length != 2 || msg.topicParts[1].isEmpty) {
      _log.warning("Invalid control message. (topic: ${msg.topic}");
      return;
    }

    // resolve component
    final componentId = msg.shiftTopic();

    if (room.hasComponent(componentId) == null) {
      _log.warning('Invalid control message: '
          'unknown component "$componentId" (topic: ${msg.topic})');
      return;
    }

    final component = room.getComponent(componentId);

    // consume
    final propertyId = msg.shiftTopic();
    component.consumeControl(propertyId, msg.data);
  }

  void _processRoomDeviceMessage(Room room, FarmMessage msg) {
    // invalid topic
    if (msg.topicParts.length != 1 || msg.topicParts[0].isEmpty) {
      _log.warning("Invalid device message. (topic: ${msg.topic}");
      return;
    }

    // resolve component
    final componentId = msg.shiftTopic();

    if (room.hasComponent(componentId) == null) {
      _log.warning('Invalid device message: '
          'unknown component "$componentId" (topic: ${msg.topic})');
      return;
    }

    final component = room.getComponent(componentId);

    // consume
    late final FarmEventType eventType;
    if (msg.data.isEmpty) {
      component.device = null;
      room.removeComponent(componentId);
      eventType = FarmEventType.roomComponentUninstall;
    } else {
      final deviceId = msg.data;
      final device = _discoverDevice(deviceId);
      component.device = device;
      eventType = FarmEventType.roomComponentInstall;
    }

    //  emit event
    _emit(eventType, room: room);
  }

  void _processRoomLogMessage(Room room, FarmMessage msg) {
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      _log.warning("Invalid log message: missing level. (topic: ${msg.topic})");
      return;
    }

    late LogLevel logLevel;

    switch (msg.shiftTopic()) {
      case "debug":
        logLevel = LogLevel.debug;
        break;
      case "info":
        logLevel = LogLevel.info;
        break;
      case "warning":
        logLevel = LogLevel.warning;
        break;
      case "error":
        logLevel = LogLevel.error;
        break;
      default:
        _log.warning(
            "Invalid log message: unkown level. (topic: ${msg.topic})");
        return;
    }

    // parse message
    late LogLine logLine;
    try {
      logLine = LogLine.fromJson(room.id, logLevel, jsonDecode(msg.data));
    } catch (e) {
      _log.severe("Error parsing log message: $e");
      return;
    }

    // store
    if (logListSize > 0) {
      if (logList.length + 1 > logListSize) {
        final removeCount = logList.length + 1 - logListSize;
        logList.removeRange(0, removeCount);
      }
      logList.add(logLine);
    }

    // emit
    _emit(FarmEventType.roomLog, room: room, log: logLine);
  }

  void _processRoomAlertMessage(Room room, FarmMessage msg) {
    // <alertType>/<alertId>
    // invalid: missing type
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return _log.warning(
          "Invalid alert message: missing type. (topic: ${msg.topic})");
    }

    late AlertType alertType;
    switch (msg.shiftTopic()) {
      case "info":
        alertType = AlertType.info;
        break;
      case "warning":
        alertType = AlertType.warning;
        break;
      case "error":
        alertType = AlertType.error;
        break;
      default:
        return _log.warning(
            "Invalid alert message: invalid type. (topic: ${msg.topic})");
    }

    // invalid: missing id
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return _log
          .warning("Invalid alert message: missing id. (topic: ${msg.topic})");
    }

    final alertId = msg.shiftTopic();
    final timestamp = int.tryParse(msg.data) ?? 0;
    final alert = Alert(
        id: alertId, type: alertType, timestamp: timestamp, roomId: room.id);

    // process alert
    final alertKey = "${room.id}.${alert.id}";
    if (alert.isActive) {
      alerts[alertKey] = alert;
    } else {
      alerts.remove(alertKey);
    }

    // emit
    _emit(FarmEventType.roomAlert, room: room, alert: alert);
  }

  void _processRoomNotificationMessage(Room room, FarmMessage msg) {
    final notification = Notification(message: msg.data, roomId: room.id);

    _emit(FarmEventType.roomNotification,
        room: room, notification: notification);
  }

  void _processHomieMessage(FarmMessage msg) {
    final deviceId = msg.shiftTopic();

    // invalid
    if (deviceId.isEmpty) {
      return _log
          .warning("Invalid homie message: missing device id. (${msg.topic})");
    }

    // missing subtopic
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return _log.warning("Invalid homie message: "
          "missing subtopic(s). ${msg.topic}");
    }

    // parse
    final device = _discoverDevice(deviceId);
    final subtopic = msg.topicParts[0];
    final subtopics = msg.topicParts.join("/");
    final deviceWasLodaded = device.isLoaded;

    if (subtopics == r"$stats/signal") {
      final signal = int.tryParse(msg.data);
      if (signal != null) {
        device.wifi.signal = signal;
        _emit(FarmEventType.deviceState, device: device);
      }
    } else if (subtopics == r"$stats/uptime") {
      final uptime = int.tryParse(msg.data);
      if (uptime != null) {
        device.uptime = uptime;
        _emit(FarmEventType.deviceState, device: device);
      }
    } else if (subtopics == r"$mac") {
      device.wifi.mac = msg.data;
    } else if (subtopics == r"$localip") {
      device.wifi.ip = msg.data;
    } else if (subtopics == r"$name") {
      device.name = msg.data;
    } else if (subtopic == r"$fw") {
      final fw = device.firmware;
      if (subtopics == r"$fw/name") {
        fw.name = msg.data;
      } else if (subtopics == r"$fw/version") {
        fw.version = msg.data;
      } else if (subtopics == r"$fw/checksum") {
        fw.checksum = msg.data;
      }
    } else if (subtopic == r"$state") {
      _processHomieStateMessage(device, msg);
    } else if (subtopics == r"$implementation/config") {
      _processHomieConfigMessage(device, msg);
    }

    // deviceLoaded event
    if (!deviceWasLodaded && device.isLoaded) {
      _emit(FarmEventType.deviceLoaded, device: device);
    }
  }

  void _processHomieStateMessage(Device device, FarmMessage msg) {
    switch (msg.data) {
      case "ready":
        device.status = DeviceStatus.ready;
        break;
      case "lost":
        device.status = DeviceStatus.lost;
        break;
      case "disconnected":
        device.status = DeviceStatus.disconnected;
        break;
      case "init":
        device.status = DeviceStatus.init;
        break;
      case "alert":
        device.status = DeviceStatus.alert;
        break;
      case "sleeping":
        device.status = DeviceStatus.sleeping;
        break;
      default:
        _log.warning(
            "Ignored invalid device '${device.id}' state: ${msg.data}");
    }

    _emit(FarmEventType.deviceStatus, device: device);
    _emit(FarmEventType.deviceState, device: device);
  }

  void _processHomieConfigMessage(Device device, FarmMessage msg) {
    Map<String, dynamic>? config;

    try {
      config = jsonDecode(msg.data);
    } catch (e) {
      _log.warning("error decoding device config: $e");
      return;
    }

    if (config == null) return;

    // name
    if (config.containsKey('name')) {
      device.name = config['name'] as String;
    }

    // wifi
    if (config.containsKey('wifi') && config['wifi']['ssid'] != null) {
      device.wifi.ssid = config['wifi']['ssid'] as String;
    }

    // mqtt
    if (config.containsKey('mqtt')) {
      final mqtt = config['mqtt'];
      device.mqtt.host = (mqtt['host'] as String?) ?? "";
      device.mqtt.port = (mqtt['port'] as int?) ?? 0;
      device.mqtt.ssl = (mqtt['ssl'] as bool?) ?? false;
    }

    // settings
    if (config.containsKey('settings')) {
      device.settings = Map<String, dynamic>.of(config['settings']);
    }

    _emit(FarmEventType.deviceState, device: device);
  }
}
