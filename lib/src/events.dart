import 'farm.dart';
import 'room.dart';
import 'device.dart';
import 'alert.dart';
import 'log.dart';
import 'notification.dart';
import 'component.dart';

enum FarmEventType {
  deviceInstall,
  deviceState,
  deviceStatus,
  deviceLoaded,
  deviceUninstall,

  roomInstall,
  roomComponentInstall,
  roomState,
  roomAlert,
  roomNotification,
  roomLog,
  roomComponentUninstall,
  roomUninstall,

  farmConnected,
  farmDisconnected,
  farmReconnect,
  farmReconnected,
  farmConnectError,
}

class FarmEvent {
  FarmEvent(this.type,
      {this.farm,
      this.room,
      this.device,
      this.alert,
      this.notification,
      this.log,
      this.component,
      this.propertyId,
      this.propertyValue});

  FarmEventType type;
  Farm? farm;
  Room? room;
  Device? device;
  Alert? alert;
  Notification? notification;
  LogLine? log;

  Component? component;
  String? propertyId;
  Object? propertyValue;
}
