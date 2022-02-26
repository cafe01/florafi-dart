import 'dart:async';
import 'dart:convert';
import 'package:florafi/florafi.dart';

class FarmMessage {
  String topic;
  late List<String> topicParts;
  String data;
  bool retained;

  FarmMessage(this.topic, this.data, [this.retained = false]) {
    topicParts = topic.split("/");
  }

  String shiftTopic() {
    return topicParts.removeAt(0);
  }
}

class Farm {
  Map<String, Device> devices = {};
  Map<String, Room> rooms = {};
  Map<String, Alert> alerts = {};

  // late Stream<FarmEvent> _events;
  late StreamController<FarmEvent> _events;

  Stream<FarmEvent> get events {
    return _events.stream;
  }

  Farm() {
    // create events stream controller
    _events = StreamController<FarmEvent>.broadcast();
  }

  Room _discoverRoom(String id) {
    // return existing
    if (rooms.containsKey(id)) {
      return rooms[id]!;
    }

    // install
    final room = rooms[id] = Room(id);
    _events.add(FarmEvent(FarmEventType.roomInstall, room: room));
    return room;
  }

  Device _discoverDevice(String id) {
    // return existing
    if (devices.containsKey(id)) {
      return devices[id]!;
    }

    // install
    final device = devices[id] = Device(id);
    _events.add(FarmEvent(FarmEventType.deviceInstall, device: device));
    // TODO emit event

    return device;
  }

  void processMessage(String topic, String data, [bool retained = false]) {
    final message = FarmMessage(topic, data, retained);

    final messageType = message.shiftTopic();

    if (messageType == "florafi") {
      _processFlorafiMessage(message);
    } else if (messageType == "homie") {
      _processHomieMessage(message);
    } else {
      print("Unknown message topic '$topic'");
    }
  }

  void _processFlorafiMessage(FarmMessage message) {
    final subtopic = message.shiftTopic();

    if (subtopic == "room") {
      _processRoomMessage(message);
    } else if (subtopic == "device") {
      _processDeviceDiscoveryMessage(message);
    } else {
      print("[!] Unknown florafi message type '${message.topic}'");
    }
  }

  void _processDeviceDiscoveryMessage(FarmMessage message) {
    if (message.topicParts.length != 1 || message.topicParts[0].isEmpty) {
      print("[!] Malformed device discovery message: "
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
        print("[!] Received 'forget device' message "
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
      return print("[!] Invalid device discovery message. "
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
      return print(
          "[!] Invalid room message: missing room id. (topic: ${msg.topic})");
    }

    final roomId = msg.shiftTopic();

    // invalid: missing subtopic
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return print(
          "[!] Invalid room message: missing subtopic. (topic: ${msg.topic})");
    }

    final room = _discoverRoom(roomId);
    final subtopic = msg.shiftTopic();

    if (subtopic == "alert") {
      _processRoomAlertMessage(room, msg);
    }
  }

  void _processRoomAlertMessage(Room room, FarmMessage msg) {
    // <alertType>/<alertId>
    // invalid: missing type
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return print(
          "[!] Invalid alert message: missing type. (topic: ${msg.topic})");
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
        return print(
            "[!] Invalid alert message: invalid type. (topic: ${msg.topic})");
    }

    // invalid: missing id
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return print(
          "[!] Invalid alert message: missing id. (topic: ${msg.topic})");
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
    _events.add(FarmEvent(FarmEventType.alert, room: room, alert: alert));
  }

  void _processHomieMessage(FarmMessage msg) {
    final deviceId = msg.shiftTopic();

    // invalid
    if (deviceId.isEmpty) {
      return print(
          "[!] Invalid homie message: missing device id. (${msg.topic})");
    }

    // missing subtopic
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return print("[!] Invalid homie message: "
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
        _events.add(FarmEvent(FarmEventType.deviceState, device: device));
      }
    } else if (subtopics == r"$stats/uptime") {
      final uptime = int.tryParse(msg.data);
      if (uptime != null) {
        device.uptime = uptime;
        _events.add(FarmEvent(FarmEventType.deviceState, device: device));
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
      _events.add(FarmEvent(FarmEventType.deviceLoaded, device: device));
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
        print("[!] Ignored invalid device '${device.id}' state: ${msg.data}");
    }

    _events.add(FarmEvent(FarmEventType.deviceStatus, device: device));
    _events.add(FarmEvent(FarmEventType.deviceState, device: device));
  }

  void _processHomieConfigMessage(Device device, FarmMessage msg) {
    Map<String, dynamic>? config;

    try {
      config = jsonDecode(msg.data);
    } catch (e) {
      print("[!] error decoding device config: $e");
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
  }
}
