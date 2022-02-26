import 'package:florafi/florafi.dart';

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
  FarmEvent(this.type, {this.room, this.device, this.alert, this.log});

  FarmEventType type;
  Room? room;
  Device? device;
  Alert? alert;
  LogLine? log;
}
