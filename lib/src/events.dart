import 'package:florafi/florafi.dart';
import 'package:florafi/src/notification.dart';

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
  roomComponentUninstall,
  roomUninstall,

  log,

  farmConnect,
  farmReconnect,
  farmDisconnect,
  farmOffline,
  farmConnectError,
}

class FarmEvent {
  FarmEvent(this.type,
      {this.room, this.device, this.alert, this.notification, this.log});

  FarmEventType type;
  Room? room;
  Device? device;
  Alert? alert;
  Notification? notification;
  LogLine? log;
}
