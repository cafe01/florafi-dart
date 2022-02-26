class DeviceWifiInfo {
  String ip = "";
  String mac = "";
  String ssid = "";
  int signal = -1;

  bool get isLoaded {
    return signal >= 0 && ip.isNotEmpty && mac.isNotEmpty && ssid.isNotEmpty;
  }
}

class DeviceMQTTInfo {
  String host = "";
  int port = 0;
  bool? ssl;

  bool get isLoaded {
    return host.isNotEmpty && port != 0 && ssl != null;
  }
}

class DeviceFirmwareInfo {
  String name = "";
  String version = "";
  String checksum = "";

  bool get isLoaded {
    return name.isNotEmpty && version.isNotEmpty && checksum.isNotEmpty;
  }
}

enum DeviceStatus { unknown, init, ready, disconnected, lost, sleeping, alert }

class Device {
  Device(this.id);

  String id;
  String name = "";

  bool isDeactivated = false;
  int uptime = -1;

  DeviceStatus status = DeviceStatus.unknown;

  final wifi = DeviceWifiInfo();
  final mqtt = DeviceMQTTInfo();
  final firmware = DeviceFirmwareInfo();
  Map<String, dynamic> settings = {};

  bool get isLoaded {
    return name.isNotEmpty &&
        wifi.isLoaded &&
        firmware.isLoaded &&
        status != DeviceStatus.unknown &&
        uptime != -1;
  }

  bool get isOnline {
    switch (status) {
      case DeviceStatus.init:
      case DeviceStatus.ready:
      case DeviceStatus.alert:
        return true;
      case DeviceStatus.unknown:
      case DeviceStatus.disconnected:
      case DeviceStatus.lost:
      case DeviceStatus.sleeping:
        return false;
    }
  }
}
