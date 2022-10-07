import 'dart:io';

import 'package:async/async.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  // Logger.root.level = Level.WARNING;
  // Logger.root.onRecord.listen((record) {
  //   print(
  //       "${record.time} ${record.loggerName}.${record.level}: ${record.message}");
  // });

  group("getStatus()", () {
    late DeviceSetupClient setupClient;
    late StreamQueue<DeviceSetupStatus> setupState;

    Map<String, dynamic> deviceJson = {
      "name": "Device Name",
      "ap": "Device AP",
      "fw": "Firmware Name",
      "fwv": "Firmware Version",
    };

    Map<String, dynamic> wifiJson = {
      "scanning": true,
      "connected": true,
      "connecting": true,
      "failed": true,
      "ssid": "foobar",
      "ip": "",
      "ch": 1,
    };

    Map<String, dynamic> authJson = {
      "status": "pending",
      "reason": "",
    };

    Map<String, dynamic> clockJson = {
      "valid": false,
    };

    Map<String, dynamic> statusJson = {};

    setUp(() {
      final httpClient = MockClient((request) async {
        // get status
        if (request.method == "GET" && request.url.path == "/status") {
          return Response(
            jsonEncode(statusJson),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        throw SocketException("");
      });

      setupClient = DeviceSetupClient(httpClient: httpClient);
      setupState = StreamQueue<DeviceSetupStatus>(setupClient.status);
    });

    tearDown(() {
      setupState.cancel();
    });

    test('state.device', () async {
      statusJson = {"device": deviceJson};

      await setupClient.getStatus();
      final state = await setupState.next;

      expect(state.hasDevice, true);
      expect(state.connectionFailed, false);
      expect(state.device?.name, deviceJson["name"]);
      expect(state.device?.apName, deviceJson["ap"]);
      expect(state.device?.firmwareName, deviceJson["fw"]);
      expect(state.device?.firmwareVersion, deviceJson["fwv"]);

      expect(state.isCompleted, false);
    });

    test('state.wifi', () async {
      statusJson = {"wifi": wifiJson};

      await setupClient.getStatus();
      final state = await setupState.next;

      expect(state.connectionFailed, false);
      expect(state.wifi?.isScanning, true);
      expect(state.wifi?.isConnected, true);
      expect(state.wifi?.isConnecting, true);
      expect(state.wifi?.connectionFailed, true);
      expect(state.wifi?.ssid, wifiJson["ssid"]);
      expect(state.wifi?.ip, wifiJson["ip"]);
      expect(state.wifi?.channel, wifiJson["ch"]);

      expect(state.isWifiConfigured, false);
      expect(state.isCompleted, false);

      // networks
      wifiJson["aps"] = [
        {
          "ssid": "foo",
          "bssid": "foo_bssid",
          "ch": 1,
          "rssi": -75,
          "secure": true,
        }
      ];

      await setupClient.getStatus();
      final networks = (await setupState.next).wifi?.networks;

      expect(networks?.length, 1);
      expect(networks?.first.ssid, wifiJson["aps"][0]["ssid"]);
      expect(networks?.first.bssid, wifiJson["aps"][0]["bssid"]);
      expect(networks?.first.channel, wifiJson["aps"][0]["ch"]);
      expect(networks?.first.signal, 50);
      expect(networks?.first.isSecure, wifiJson["aps"][0]["secure"]);

      // complete wifi
      wifiJson["ip"] = "1.2.3.4";
      await setupClient.getStatus();

      final completedState = await setupState.next;
      expect(completedState.wifi?.ip, wifiJson["ip"]);
      expect(completedState.isWifiConfigured, true);
    });

    test('state.authentication', () async {
      statusJson = {"auth": authJson};

      // pending
      await setupClient.getStatus();
      expect((await setupState.next).authentication?.status.isPending, true);

      // joining
      authJson["status"] = "joining";
      await setupClient.getStatus();
      expect((await setupState.next).authentication?.status.isJoining, true);

      // joined
      authJson["status"] = "joined";
      await setupClient.getStatus();
      expect((await setupState.next).authentication?.status.isJoined, true);

      // failed
      authJson["status"] = "failed";
      authJson["reason"] = "unauthorized";
      await setupClient.getStatus();
      expect((await setupState.next).authentication?.status.isFailed, true);

      // reason: connectionFailed
      authJson["reason"] = "error";
      await setupClient.getStatus();
      expect((await setupState.next).authentication?.failedReason.requestError,
          true);

      // reason: unauthorized
      authJson["reason"] = "unauthorized";
      await setupClient.getStatus();
      expect((await setupState.next).authentication?.failedReason.unauthorized,
          true);
    });

    test('state.clock', () async {
      statusJson = {"clock": clockJson};

      // invalid time
      await setupClient.getStatus();
      expect((await setupState.next).clock?.hasValidTime, false);

      // valid
      clockJson["valid"] = true;
      await setupClient.getStatus();
      expect((await setupState.next).clock?.hasValidTime, true);
    });

    test('state.isCompleted', () async {
      statusJson = {
        "device": deviceJson,
        "wifi": wifiJson,
        "auth": authJson,
        "clock": clockJson,
      };

      wifiJson["ip"] = "";
      authJson["status"] = "pending";
      clockJson["valid"] = false;

      // nothing configured
      await setupClient.getStatus();
      DeviceSetupStatus state = await setupState.next;
      expect(state.isWifiConfigured, false);
      expect(state.isAuthenticationConfigured, false);
      expect(state.isClockConfigured, false);
      expect(state.isCompleted, false);

      // wifi configured
      wifiJson["ip"] = "1.2.3.4";
      await setupClient.getStatus();
      state = await setupState.next;
      expect(state.isWifiConfigured, true);
      expect(state.isAuthenticationConfigured, false);
      expect(state.isClockConfigured, false);
      expect(state.isCompleted, false);

      // auth configured
      authJson["status"] = "joined";
      await setupClient.getStatus();
      state = await setupState.next;
      expect(state.isWifiConfigured, true);
      expect(state.isAuthenticationConfigured, true);
      expect(state.isClockConfigured, false);
      expect(state.isCompleted, false);

      // clock configured
      clockJson["valid"] = true;
      await setupClient.getStatus();
      state = await setupState.next;
      expect(state.isWifiConfigured, true);
      expect(state.isAuthenticationConfigured, true);
      expect(state.isClockConfigured, true);
      expect(state.isCompleted, true);
    });
  });

  group("post commands", () {
    late DeviceSetupClient setupClient;
    Future<void> Function(Request request)? onPostConfig;

    setUp(() {
      final httpClient = MockClient((request) async {
        // post
        if (request.method == "POST") {
          final path = request.url.path;

          // not found
          if (!(path == "/config" || path == "/scan" || path == "/finish")) {
            throw SocketException("");
          }

          // /config
          if (path == "/config") {
            if (onPostConfig != null) await onPostConfig!(request);
          }

          return Response("", 200);
        }

        throw SocketException("");
      });

      setupClient = DeviceSetupClient(httpClient: httpClient);
    });

    test('sendConfig', () async {
      onPostConfig = (request) async {
        expect(request.headers["content-type"], "application/json");
        expect(request.body, r'{"foo":"bar"}');
      };

      await setupClient.sendConfig({"foo": "bar"});
    });
    test('scanNetworks', () async {
      await setupClient.scanNetworks();
    });

    test('sendFinish', () async {
      await setupClient.sendFinish();
    });
  });
}
