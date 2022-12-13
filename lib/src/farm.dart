import 'dart:async';
import 'dart:convert';
import 'package:clock/clock.dart';
import 'package:logging/logging.dart';

import 'communicator.dart';
import 'component/component_builder.g.dart';
import 'events.dart';
import 'device.dart';
import 'room.dart';
import 'alert.dart';
import 'log.dart';
import 'notification.dart';
import 'component.dart';

typedef FarmEventSubscription = StreamSubscription<FarmEvent>;

class FarmMessage {
  FarmMessage(String topic, this.data, {this.retained = false}) {
    _topic = topic;
  }

  late String _topic;
  String get topic => _topic;
  set topic(String newTopic) {
    _topic = newTopic;
    _topicParts = null;
  }

  String data;
  bool retained;

  List<String>? _topicParts;
  List<String> get topicParts {
    _topicParts ??= _topic.split("/");
    return _topicParts!;
  }

  String shiftTopic() {
    return topicParts.removeAt(0);
  }
}

class Farm {
  late final Logger _log;

  Map<String, Device> devices = {};
  Map<String, Room> rooms = {};
  Map<String, Alert> alerts = {};

  late final StreamController<FarmEvent> _events =
      StreamController<FarmEvent>.broadcast();

  Stream<FarmEvent> get events {
    return _events.stream;
  }

  Stream<FarmEvent> get connectionEvents {
    const Set<FarmEventType> events = {
      FarmEventType.farmConnected,
      FarmEventType.farmConnectError,
      FarmEventType.farmDisconnected,
      FarmEventType.farmReconnect,
      FarmEventType.farmReconnected,
    };

    return _events.stream.where((event) => events.contains(event.type));
  }

  int logListSize = 0;
  final List<LogLine> logList = [];

  Communicator? communicator;

  String name;
  final int id;

  final bool isReadOnly;

  bool isReady = false;
  Timer? _isReadyTimer;

  bool get isConnected => communicator?.isConnected == true;
  bool get isConnecting => communicator?.isConnecting == true;
  bool get isDisconnected => communicator?.isDisconnected == true;
  bool get isDisconnecting => communicator?.isDisconnecting == true;

  ConnectionState get connectionState {
    return communicator == null
        ? ConnectionState.unknown
        : communicator!.connectionState;
  }

  bool autoDiscoverRoom;

  FarmMessage? _lastMessage;
  FarmMessage? get lastMessage => _lastMessage;

  int _messageCount = 0;

  Clock? _clock;
  void setClock(Clock? clock) => _clock = clock;
  Clock getClock() => _clock ?? clock;
  DateTime currentTime() => getClock().now();

  Farm({
    this.name = "",
    this.id = 0,
    Clock? clock,
    this.communicator,
    this.autoDiscoverRoom = true,
    this.isReadOnly = false,
  }) : _clock = clock {
    _log = Logger('Farm[$id]');
  }

  void _emit(
    FarmEventType eventType, {
    Room? room,
    Device? device,
    Alert? alert,
    Notification? notification,
    LogLine? log,
    Component? component,
    String? propertyId,
    Object? propertyValue,
  }) {
    final event = FarmEvent(
      eventType,
      farm: this,
      room: room,
      device: device,
      alert: alert,
      notification: notification,
      log: log,
      component: component,
      propertyId: propertyId,
      propertyValue: propertyValue,
      fromRetainedMessage: _lastMessage?.retained ?? false,
    );
    // _log.info("event: $event");
    _events.add(event);
  }

  void _handleIsReady({debounce = true}) {
    if (isReady) return;

    markReady() {
      _log.fine(
          "'$name' is ready with ${rooms.values.length} rooms (debounce=$debounce)");
      isReady = true;
      _log.info("Farm '$name' ready! ($_messageCount messages)");
      _emit(FarmEventType.farmReady);
    }

    _isReadyTimer?.cancel();
    if (debounce) {
      _isReadyTimer = Timer(Duration(milliseconds: 500), markReady);
    } else {
      markReady();
    }
  }

  void _onConnected() {
    _log.info("Connected. ($name)");

    subscribe("florafi/device/+");
    for (final device in devices.values) {
      _subscribeHomieTopics(device.id);
    }
    for (final room in rooms.values) {
      _subscribeRoom(room.id);
    }

    _emit(FarmEventType.farmConnected);
    _handleIsReady();
  }

  void _onDisconnected() async {
    isReady = false;
    _log.info("Disconnected. ($name)");
    _emit(FarmEventType.farmDisconnected);
  }

  void _onAutoReconnect() {
    isReady = false;
    _log.info("Auto-reconnecting... ($name)");
    _emit(FarmEventType.farmReconnect);
  }

  void _onAutoReconnected() {
    _log.info("Auto-reconnected. ($name)");
    _emit(FarmEventType.farmReconnected);
  }

  StreamSubscription<FarmMessage>? _communicatorSubscription;

  Future<void> connect() async {
    if (communicator == null) {
      throw StateError("set communicator before calling connect()");
    }

    communicator!.onConnected ??= _onConnected;
    communicator!.onDisconnected ??= _onDisconnected;
    communicator!.onAutoReconnect ??= _onAutoReconnect;
    communicator!.onAutoReconnected ??= _onAutoReconnected;

    // not disconnected
    if (!isDisconnected) {
      _log.warning("Ignoring connect(): not disconnected.");
      return;
    }
    // if (isConnected) {
    //   _log.warning("Can't connect(): already connected.");
    //   return;
    // }

    // if (isConnecting) {
    //   _log.warning("Can't connect(): already connecting.");
    //   return;
    // }

    try {
      _emit(FarmEventType.farmConnecting);
      await communicator!.connect();
    } on ConnectError {
      _emit(FarmEventType.farmConnectError);
    }

    _communicatorSubscription ??= communicator!.messages.listen((message) {
      // _log.info("msg on ${message.topic}");
      processMessage(message);
    });
  }

  Future<void> disconnect() async {
    // await _communicatorSubscription?.cancel();
    // _communicatorSubscription == null;
    communicator?.disconnect();
  }

  void publish(String topic, String message,
      {retain = false, qos = CommunicatorQos.atLeastOnce}) {
    if (communicator == null) {
      _log.warning("Can't publish() before connect()");
      return;
    }

    _log.fine("publishing to $topic: $message (retain: $retain, qos: $qos)");
    communicator!.publish(topic, message, qos: qos, retain: retain);
  }

  int? subscribe(String topic, [qos = CommunicatorQos.atLeastOnce]) {
    if (communicator == null) {
      _log.warning("Can't subscribe before connect()");
      return null;
    }
    _log.info("subscribing to '$topic' qos($qos)");
    return communicator!.subscribe(topic, qos);
  }

  Room installRoom(String id, {String? name}) {
    // return existing
    if (rooms.containsKey(id)) {
      return rooms[id]!;
    }

    // install
    final room = rooms[id] = Room(id, farm: this);
    room.name = name;
    _emit(FarmEventType.roomInstall, room: room);
    if (communicator != null && isConnected) {
      _subscribeRoom(room.id);
    }
    return room;
  }

  void _subscribeRoom(String roomId) {
    subscribe("florafi/room/$roomId/\$name");
    subscribe("florafi/room/$roomId/config/#");
    subscribe("florafi/room/$roomId/alert/#");
  }

  void uninstallRoom(String id) {
    final room = rooms.remove(id);

    // unknown room
    if (room == null) {
      return;
    }

    // uninstall
    _emit(FarmEventType.roomUninstall, room: room);

    // unsubscribe
    // if (communicator != null && isConnected) {
    //   // subscribe("florafi/room/${room.id}/#");
    // }
  }

  void _subscribeHomieTopics(String deviceId) {
    subscribe("homie/$deviceId/+");
    subscribe("homie/$deviceId/\$stats/+");
    subscribe("homie/$deviceId/\$fw/+");
    subscribe("homie/$deviceId/\$implementation/config");
    subscribe("homie/$deviceId/\$implementation/ota/+");
  }

  void processMessage(FarmMessage message) {
    _messageCount++;
    if (message.topicParts.isEmpty) {
      _log.severe(
          "Invalid farm message: topicParts is empty! (topic: ${message.topic})");
      return;
    }

    _lastMessage = message;
    _handleIsReady(debounce: message.retained);

    final messageType = message.shiftTopic();

    if (messageType == "florafi") {
      _processFlorafiMessage(message);
    } else if (messageType == "homie") {
      _processHomieMessage(message);
    } else {
      _log.fine("Unknown message topic '${message.topic}'");
    }
  }

  void _processFlorafiMessage(FarmMessage message) {
    if (message.topicParts.isEmpty) {
      _log.fine("Ignoring invalid florafi message. (topic: ${message.topic})");
      return;
    }

    final subtopic = message.shiftTopic();

    if (subtopic == "room") {
      _processRoomMessage(message);
    } else if (subtopic == "device") {
      _processFlorafiDeviceMessage(message);
    } else {
      _log.fine("Unknown florafi message type '${message.topic}'");
    }
  }

  void _processFlorafiDeviceMessage(FarmMessage message) {
    if (message.topicParts.length != 1 || message.topicParts[0].isEmpty) {
      _log.fine("Malformed device discovery message: "
          "missing device id subtopic. (${message.topic}) (${message.topicParts.length})");
      return;
    }

    final deviceId = message.shiftTopic();

    // forget device
    if (message.data.isEmpty) {
      final device = devices[deviceId];
      if (device != null) {
        // forget
        devices.remove(deviceId);
        _emit(FarmEventType.deviceUninstall, device: device);

        // notify room
        if (device.room != null) {
          _emit(FarmEventType.roomUpdate, room: device.room);
        }
      } else {
        _log.fine("Received 'forget device' message "
            "for unknown device '$deviceId'");
      }

      return;
    }

    // parse message
    final discoveryMsg = Map<String, dynamic>.from(jsonDecode(message.data));

    final roomId = discoveryMsg["room"] as String?;
    final deactivated = discoveryMsg["deactivated"] as bool?;

    // invalid discovery message
    if (!discoveryMsg.containsKey("room") ||
        !discoveryMsg.containsKey("deactivated") ||
        deactivated == null) {
      return _log.fine("Invalid device discovery message. "
          "(${message.topic}: ${message.data})");
    }

    _log.info(
        "Device '$deviceId' advertisement room($roomId) deactivated($deactivated) components(${discoveryMsg["components"]})");

    // first device install
    bool isNewDevice = !devices.containsKey(deviceId);
    Device device;

    if (isNewDevice) {
      device = devices[deviceId] = Device(id: deviceId, farm: this);
    } else {
      device = devices[deviceId]!;
    }

    // set properties
    device.isDeactivated = deactivated;

    // subscribe homie topics
    if (communicator != null) _subscribeHomieTopics(device.id);

    // discover room
    Room? previousRoom = device.room;

    if (roomId != null && roomId.isNotEmpty) {
      if (autoDiscoverRoom) device.room = installRoom(roomId);
    } else {
      device.room = null;
    }

    // notify rooms
    if (previousRoom != device.room) {
      // emit roomUpdate
      if (previousRoom != null) {
        _emit(FarmEventType.roomUpdate, room: previousRoom, device: device);
      }

      if (device.room != null) {
        _emit(FarmEventType.roomUpdate, room: device.room, device: device);
      }
    }

    // parse components advertisement
    final List<String> componentIds = [];
    final componentsAdvertisement = discoveryMsg["components"];
    if (componentsAdvertisement == null) {
      _log.warning(
          "Legacy device ($deviceId) advertisement: missing 'components'");
    } else if (componentsAdvertisement is! List) {
      _log.warning(
          "Invalid device ($deviceId) advertisement: 'components' is not a list! (its: ${componentsAdvertisement.runtimeType})");
    } else {
      componentIds.addAll(List<String>.from(discoveryMsg["components"]));
    }

    // uninstall components
    final removedComponents = device.components
        .where((c) => !componentIds.contains(c.mqttId))
        .toList();

    for (final component in removedComponents) {
      // remove from device
      device.components.removeWhere((c) => c == component);
      // notify room
      if (device.room != null) {
        _emit(FarmEventType.roomComponentUninstall,
            room: device.room, device: device, component: component);
      }
    }

    // install components
    for (final mqttId in componentIds) {
      // invalid
      if (!ComponentBuilder.isValidId(mqttId)) {
        _log.severe("Device '$deviceId' advertised unknown '$mqttId'.");
        continue;
      }
      // already installed
      final alreadyInstalled =
          !device.components.indexWhere((c) => c.mqttId == mqttId).isNegative;
      if (alreadyInstalled) continue;

      // add component to device
      device.components.add(ComponentBuilder.fromId(mqttId, device));
    }

    // subscribe to room component states
    if (device.room != null) {
      for (final component in device.components) {
        subscribe(
            "florafi/room/${device.room!.id}/state/${component.mqttId}/#");
      }
    }

    // emit device event
    if (isNewDevice) {
      _emit(FarmEventType.deviceInstall, device: device);
    } else {
      _emit(FarmEventType.deviceUpdate, device: device);
    }
  }

  void _processRoomMessage(FarmMessage msg) {
    // invalid: missing room id
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return _log
          .fine("Invalid room message: missing room id. (topic: ${msg.topic})");
    }

    final roomId = msg.shiftTopic();

    // invalid: missing subtopic
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return _log.fine(
          "Invalid room message: missing subtopic. (topic: ${msg.topic})");
    }

    final room = installRoom(roomId);
    final subtopic = msg.shiftTopic();

    switch (subtopic) {
      case "state":
        _processRoomStateMessage(room, msg);
        break;
      case "log":
        _processRoomLogMessage(room, msg);
        break;
      case "config":
        _processRoomConfigMessage(room, msg);
        break;
      // case "device":
      //   _processRoomDeviceMessage(room, msg);
      //   break;
      case "alert":
        _processRoomAlertMessage(room, msg);
        break;
      case "notification":
        _processRoomNotificationMessage(room, msg);
        break;
      case r"$name":
        room.name = msg.data;
        _emit(FarmEventType.roomUpdate, room: room);
        break;
      default:
        _log.fine("Unknown room message type: $subtopic");
    }
  }

  void _processRoomStateMessage(Room room, FarmMessage msg) {
    // invalid topic
    if (msg.topicParts.length != 2 || msg.topicParts[1].isEmpty) {
      _log.fine("Invalid state message. (topic: ${msg.topic}");
      return;
    }

    // resolve component
    final componentId = msg.shiftTopic();

    // validate id
    if (!ComponentBuilder.isValidId(componentId)) {
      _log.fine('Invalid state message: '
          'unknown component "$componentId" (topic: ${msg.topic})');
      return;
    }

    // get room component
    final component = room.getComponent(componentId);
    if (component == null) {
      _log.warning(
          "Ignoring room state message: room '${room.id}' does not have component '$componentId'");
      return;
    }

    // consume
    final propertyId = msg.shiftTopic();
    if (!component.hasProperty(propertyId)) {
      _log.fine('Invalid state message: '
          'unknown component property "$componentId.$propertyId" (topic: ${msg.topic})');
      return;
    }

    final propertyValue = component.consumeState(propertyId, msg.data);

    //  emit event
    _emit(FarmEventType.roomState,
        room: room,
        component: component,
        propertyId: propertyId,
        propertyValue: propertyValue);
  }

  // void _processRoomDeviceMessage(Room room, FarmMessage msg) {
  //   // invalid topic
  //   if (msg.topicParts.length != 1 || msg.topicParts[0].isEmpty) {
  //     _log.fine("Invalid device message. (topic: ${msg.topic}");
  //     return;
  //   }

  //   // validate component
  //   final componentId = msg.shiftTopic();
  //   final roomHasComponent = room.hasComponent(componentId);

  //   if (roomHasComponent == null) {
  //     _log.fine('Invalid device message: '
  //         'unknown component "$componentId" (topic: ${msg.topic})');
  //     return;
  //   }

  //   updateDeviceComponentList(Device? device) {
  //     if (device == null) return;
  //     device.components =
  //         room.components.where((e) => e.device == device).toList();
  //     _emit(FarmEventType.deviceUpdate, device: device);
  //   }

  //   // Device? device;

  //   // uninstall component
  //   if (msg.data.isEmpty) {
  //     // component gone already
  //     if (!roomHasComponent) return;

  //     // remove component from room
  //     final component = room.removeComponent(componentId)!;
  //     _emit(FarmEventType.roomComponentUninstall, room: room);
  //     updateDeviceComponentList(component.device);
  //     component.device = null;
  //     return;
  //   }

  //   // install component
  //   final device = devices[msg.data];

  //   // garbage reference from unknown (forgotten) device
  //   if (device == null) {
  //     _log.info("Cleaning garbage device ref at '${msg.topic}'");
  //     publish(msg.topic, "", retain: true);
  //     return;
  //   }

  //   final component = room.getComponent(componentId);
  //   _log.info("Installing component $componentId (${msg.topic}: ${msg.data})");
  //   _emit(FarmEventType.roomComponentInstall, room: room);
  //   if (component.device != device) {
  //     updateDeviceComponentList(component.device);
  //     component.device = device;
  //     updateDeviceComponentList(device);
  //   }
  // }

  void _processRoomLogMessage(Room room, FarmMessage msg) {
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      _log.fine("Invalid log message: missing level. (topic: ${msg.topic})");
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
        _log.fine("Invalid log message: unkown level. (topic: ${msg.topic})");
        return;
    }

    // parse message
    late LogLine logLine;
    try {
      logLine = LogLine.fromJson(room, logLevel, jsonDecode(msg.data));
    } catch (e) {
      _log.severe("Error parsing log message: $e");
      return;
    }

    // store
    room.lastLog = logLine;

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

  void _processRoomConfigMessage(Room room, FarmMessage msg) {
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      _log.fine(
          "Invalid room config message: missing property. (topic: ${msg.topic})");
      return;
    }

    final property = msg.topicParts.join("/");

    if (!room.consumeConfigMessage(property, msg.data)) {
      _log.warning(
          "unhandled room '${room.label}' config! ('$property' = '${msg.data}')");
      return;
    }

    // emit
    _emit(FarmEventType.roomUpdate, room: room);
  }

  void _processRoomAlertMessage(Room room, FarmMessage msg) {
    // <alertType>/<alertId>
    // invalid: missing type
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return _log
          .fine("Invalid alert message: missing type. (topic: ${msg.topic})");
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
        return _log
            .fine("Invalid alert message: invalid type. (topic: ${msg.topic})");
    }

    // invalid: missing id
    if (msg.topicParts.isEmpty || msg.topicParts[0].isEmpty) {
      return _log
          .warning("Invalid alert message: missing id. (topic: ${msg.topic})");
    }

    final alertId = msg.shiftTopic();
    final timestamp = int.tryParse(msg.data) ?? 0;

    // process alert
    final alertKey = "${room.id}.$alertId";
    Alert? alert;

    if (alerts.containsKey(alertKey)) {
      // changed
      if (alerts[alertKey]!.timestamp != timestamp) {
        alert = alerts[alertKey]!;
        alert.timestamp = timestamp;
      }
    } else if (timestamp > 0) {
      alert = alerts[alertKey] = Alert(
          id: alertId, type: alertType, timestamp: timestamp, roomId: room.id);
    }

    if (alert != null) {
      if (!alert.isActive) alerts.remove(alertKey);
      _emit(FarmEventType.roomAlert, room: room, alert: alert);
    }
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
      return _log.fine("Invalid homie message: "
          "missing subtopic(s). ${msg.topic}");
    }

    // unknown device
    final device = devices[deviceId];
    if (device == null) {
      _log.warning("Ignoring homie message for unknown device '$deviceId'");
      return;
    }

    // parse
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
    } else if (subtopics == r"$implementation/ota/status") {
      _processHomieOtaStatusMessage(device, msg);
    }

    // deviceLoaded event
    if (!deviceWasLodaded && device.isLoaded) {
      _emit(FarmEventType.deviceLoaded, device: device);
    }
  }

  void _processHomieStateMessage(Device device, FarmMessage msg) {
    final previousStatus = device.status;

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
        _log.fine("Ignored invalid device '${device.id}' state: ${msg.data}");
    }

    // if (device.room != null && previousStatus != device.status) {
    //   _emit(FarmEventType.roomUpdate, room: device.room);
    // }

    _emit(FarmEventType.deviceStatus, device: device, room: device.room);
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
    if (!msg.retained) _emit(FarmEventType.deviceState, device: device);
  }

  void _processHomieOtaStatusMessage(Device device, FarmMessage msg) {
    final parts = msg.data.split(" ");
    if (parts.isEmpty) {
      _log.warning("empty OTA status message for device '${device.id}'");
      return;
    }

    // code
    final statusCode = int.tryParse(parts.first);
    if (statusCode == null) {
      _log.warning("invalid OTA status code for device '${device.id}'");
      return;
    }

    // progress
    int progress = 0;

    if (statusCode == 206) {
      if (parts.length != 2) {
        _log.warning("invalid OTA progress message for device '${device.id}'");
        return;
      }

      final progressString = parts[1];
      final progressData = progressString.split("/");

      if (progressData.length != 2) {
        _log.warning("invalid OTA progress message for device '${device.id}'");
        return;
      }

      final receivedBytes = int.tryParse(progressData[0]);
      final totalBytes = int.tryParse(progressData[1]);

      if (receivedBytes == null || totalBytes == null) {
        _log.warning("invalid OTA progress message for device '${device.id}'");
        return;
      }

      progress = (receivedBytes / totalBytes * 100).round();
    }

    if (statusCode == 200) {
      progress = 100;
    }

    // ota status object
    device.otaStatus = OtaStatus(code: statusCode, progress: progress);
    _emit(FarmEventType.deviceOtaStatus, room: device.room, device: device);
  }
}
