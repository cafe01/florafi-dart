import 'farm.dart';
import 'room.dart';
import 'device.dart';
import 'alert.dart';
import 'log.dart';
import 'notification.dart';
import 'component.dart';

const kFarmConnectionEventTypes = [
  FarmEventType.farmConnecting,
  FarmEventType.farmConnected,
  FarmEventType.farmConnectError,
  FarmEventType.farmReconnect,
  FarmEventType.farmReconnected,
  FarmEventType.farmDisconnected,
];

enum FarmEventType {
  deviceInstall,
  deviceUpdate,
  deviceState,
  deviceStatus,
  deviceOtaStatus,
  deviceLoaded,
  deviceUninstall,

  roomInstall,
  roomComponentInstall,
  roomUpdate,
  roomState,
  roomAlert,
  roomNotification,
  roomLog,
  roomComponentUninstall,
  roomUninstall,

  farmConnecting,
  farmConnected,
  farmReady,
  farmDisconnected,
  farmReconnect,
  farmReconnected,
  farmConnectError,
}

class FarmEvent {
  const FarmEvent(
    this.type, {
    required this.farm,
    this.room,
    this.device,
    this.alert,
    this.notification,
    this.log,
    this.component,
    this.propertyId,
    this.propertyValue,
    this.fromRetainedMessage = false,
  });

  final FarmEventType type;
  final Farm farm;
  final Room? room;
  final Device? device;
  final Component? component;

  final Alert? alert;
  final Notification? notification;
  final LogLine? log;

  final String? propertyId;
  final Object? propertyValue;
  final bool fromRetainedMessage;

  @override
  String toString() {
    final details = [
      farm.name,
      if (room != null) "room: '${room!.label}'",
      if (device != null) "device: '${device!.id}'",
      if (component != null) "component: '${component!.id}'",
      if (alert != null) "alert: '${alert!.id}'",
      "retained: $fromRetainedMessage",
    ];
    return "${type.name}(${details.join(', ')})";
  }

  bool get isConnectionEvent => kFarmConnectionEventTypes.contains(type);
}
