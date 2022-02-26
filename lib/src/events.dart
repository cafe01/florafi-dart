import 'device.dart';
import 'room.dart';

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
  FarmEvent(this.type, {this.room, this.device});

  FarmEventType type;
  Room? room;
  Device? device;
}
