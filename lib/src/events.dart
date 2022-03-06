import 'package:florafi/florafi.dart';
import 'package:florafi/src/notification.dart';

enum FarmEventType {
  deviceInstall,
  deviceUninstall,
  deviceState,
  deviceStatus,
  deviceLoaded,

  roomInstall,
  roomUninstall,

  roomState,

  alert,
  notification,
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
