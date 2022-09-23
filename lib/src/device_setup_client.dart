import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

class DeviceSetupStatus {
  DeviceSetupStatus(
      {required this.connectionFailed,
      this.device,
      this.wifi,
      this.authentication,
      this.clock});

  final bool connectionFailed;

  final DeviceInfo? device;
  final WifiState? wifi;
  final AuthenticationState? authentication;
  final ClockState? clock;

  bool get hasDevice => device != null;

  bool get isWifiConfigured =>
      wifi != null && wifi!.isConnected && wifi!.ip.isNotEmpty;

  bool get isAuthenticationConfigured =>
      authentication != null && authentication!.status.isJoined;

  bool get isClockConfigured => clock != null && clock!.hasValidTime;

  bool get isCompleted =>
      isWifiConfigured && isAuthenticationConfigured && isClockConfigured;
}

class DeviceInfo {
  DeviceInfo(
      {required this.name,
      required this.apName,
      required this.firmwareName,
      required this.firmwareVersion});

  final String name;
  final String apName;
  final String firmwareName;
  final String firmwareVersion;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      name: json["name"] as String? ?? "",
      apName: json["ap"] as String? ?? "",
      firmwareName: json["fw"] as String? ?? "",
      firmwareVersion: json["fwv"] as String? ?? "",
    );
  }
}

class WiFiNetwork {
  WiFiNetwork({
    required this.ssid,
    required this.bssid,
    required this.channel,
    required this.signal,
    required this.isSecure,
  });

  final String ssid;
  final String bssid;
  final int channel;
  final int signal;
  final bool isSecure;

  factory WiFiNetwork.fromJson(Map<String, dynamic> json) {
    final rssi = json["rssi"] as int? ?? -100;
    int signal;

    if (rssi <= -100) {
      signal = 0;
    } else if (rssi >= -50) {
      signal = 100;
    } else {
      signal = 2 * (rssi + 100);
    }

    return WiFiNetwork(
      ssid: json["ssid"] as String? ?? "",
      bssid: json["bssid"] as String? ?? "",
      channel: json["ch"] as int? ?? -1,
      signal: signal,
      isSecure: json["secure"] as bool? ?? false,
    );
  }
}

class WifiState {
  WifiState({
    required this.isScanning,
    required this.isConnected,
    required this.isConnecting,
    required this.connectionFailed,
    required this.connectionFailedCode,
    required this.failedSsid,
    required this.ssid,
    required this.ip,
    // required this.mask,
    // required this.gw,
    required this.channel,
    this.networks,
  });

  final bool isScanning;
  final bool isConnected;
  final bool isConnecting;
  final bool connectionFailed;
  final int connectionFailedCode;
  final String failedSsid;
  final String ssid;
  final String ip;
  final int channel;
  final List<WiFiNetwork>? networks;

  bool get badPassword => connectionFailedCode == 401;
  bool get noApFound => connectionFailedCode == 404;

  factory WifiState.fromJson(Map<String, dynamic> json) {
    List<WiFiNetwork>? networks;

    if (json["aps"] is List) {
      networks = List<Map<dynamic, dynamic>>.from(json["aps"])
          .map((jsonMap) =>
              WiFiNetwork.fromJson(Map<String, dynamic>.from(jsonMap)))
          .toList();
    }

    return WifiState(
      isScanning: json["scanning"] as bool? ?? false,
      isConnected: json["connected"] as bool? ?? false,
      isConnecting: json["connecting"] as bool? ?? false,
      connectionFailed: json["failed"] as bool? ?? false,
      connectionFailedCode: json["reason"] as int? ?? 0,
      failedSsid: json["failedSsid"] as String? ?? "",
      ssid: json["ssid"] as String? ?? "",
      ip: json["ip"] as String? ?? "",
      channel: json["ch"] as int? ?? 0,
      networks: networks,
    );
  }
}

enum AuthenticationJoinStatus { unknown, pending, joining, joined, failed }

class AuthenticationStatus {
  AuthenticationStatus(this.status);
  final String? status;
  bool get isPending => status == "pending";
  bool get isJoined => status == "joined";
  bool get isJoining => status == "joining";
  bool get isFailed => status == "failed";
  @override
  String toString() => status.toString();
}

class AuthenticationFailedReason {
  AuthenticationFailedReason(this.reason);
  final String? reason;

  bool get none => reason == "";
  bool get unauthorized => reason == "unauthorized";
  bool get requestError => reason == "error";
}

class AuthenticationState {
  AuthenticationState({
    required this.status,
    required this.failedReason,
  });

  final AuthenticationStatus status;
  final AuthenticationFailedReason failedReason;

  factory AuthenticationState.fromJson(Map<String, dynamic> json) {
    return AuthenticationState(
      status: AuthenticationStatus(json["status"] as String?),
      failedReason: AuthenticationFailedReason(json["reason"] as String?),
    );
  }
}

class ClockState {
  ClockState({required this.hasValidTime});
  final bool hasValidTime;

  factory ClockState.fromJson(Map<String, dynamic> json) {
    return ClockState(
      hasValidTime: json["valid"] as bool? ?? false,
    );
  }
}

class DeviceSetupClient {
  DeviceSetupClient({
    int pollInterval = 1000,
    String? deviceUrl,
    required http.Client httpClient,
  })  : _pollInterval = pollInterval,
        _http = httpClient,
        _deviceUrl = Uri.parse(deviceUrl ?? "http://192.168.4.1");

  final Uri _deviceUrl;
  final int _pollInterval;
  final http.Client _http;

  final _streamController = StreamController<DeviceSetupStatus>.broadcast();
  Stream<DeviceSetupStatus> get status => _streamController.stream;

  Timer? _pollTimer;

  bool get isPolling => _pollTimer != null;

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _streamController.close();
    _http.close();
  }

  void startPolling() {
    if (_pollTimer != null) {
      log("Already polling.", name: runtimeType.toString());
      return;
    }

    log("Status polling started.", name: runtimeType.toString());
    _pollTimer = Timer.periodic(
        Duration(milliseconds: _pollInterval), (_) => getStatus());
  }

  void stopPolling() {
    if (_pollTimer == null) {
      log("Not polling status.", name: runtimeType.toString());
    } else {
      log("Status polling stopped.", name: runtimeType.toString());
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> getStatus() async {
    try {
      final res = await _get("/status");
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      log("getStatus() response: ${res.body}");
      if (_streamController.isClosed) return;

      final device = DeviceInfo.fromJson(json["device"] ?? {});
      final wifi = WifiState.fromJson(json["wifi"] ?? {});
      final authentication = AuthenticationState.fromJson(json["auth"] ?? {});
      final clock = ClockState.fromJson(json["clock"] ?? {});

      _streamController.add(DeviceSetupStatus(
        connectionFailed: false,
        device: device,
        wifi: wifi,
        authentication: authentication,
        clock: clock,
      ));
    } catch (e, st) {
      log("getStatus() error",
          error: e, stackTrace: st, name: runtimeType.toString());
      if (_streamController.isClosed) return;
      _streamController.add(DeviceSetupStatus(connectionFailed: true));
    }
  }

  Future<void> scanNetworks() async {
    await _post("/scan");
  }

  Future<void> joinFarm(
      {required Uri apiUrl, required String joinSecret}) async {
    await sendConfig({
      "auth": {"apiUrl": apiUrl.toString(), "joinSecret": joinSecret}
    });
  }

  Future<void> sendConfig(Map<String, dynamic> json) async {
    await _post("/config", json: json);
  }

  Future<void> sendFinish() async {
    await _post("/finish");
  }

  Future<http.Response> _get(String path) async {
    final request = http.Request("GET", _deviceUrl.replace(path: path));
    request.persistentConnection = false;
    return http.Response.fromStream(await _http.send(request));
  }

  Future<http.Response> _post(String path, {Map<String, dynamic>? json}) async {
    final request = http.Request("POST", _deviceUrl.replace(path: path));
    request.persistentConnection = false;

    if (json != null) {
      request.bodyBytes = utf8.encode(jsonEncode(json));
      request.headers["content-type"] = "application/json";
    }

    return http.Response.fromStream(await _http.send(request));
  }
}
