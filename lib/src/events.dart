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
      this.log});

  FarmEventType type;
  Farm? farm;
  Room? room;
  Device? device;
  Alert? alert;
  Notification? notification;
  LogLine? log;
}
