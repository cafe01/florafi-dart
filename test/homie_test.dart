import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

void main() {
  group("_processHomieMessage()", () {
    late Farm farm;
    late StreamQueue<FarmEvent> events;

// homie/d1/$implementation/ota/enabled true

    final configJson = '{"name":"MyDevice","wifi":{"ssid":"MyNetwork"},'
        '"mqtt":{"host":"farm.florafi.net","port":123,"ssl":true,"auth":true},'
        '"ota":{"enabled":true},'
        '"settings":{"boolSetting":false, "stringSetting":"foobar", "intSetting": 1234}}';

    final List<FarmMessage> messages = [
      FarmMessage('florafi/device/d1', '{"room":"","deactivated":false}'),
    ];

    setUp(() {
      farm = Farm();
      events = StreamQueue<FarmEvent>(farm.events);

      for (var m in messages) {
        farm.processMessage(m.topic, m.data);
      }

      events.skip(1); // skip FarmEventType.deviceInstall
    });

    test(r'handles $state message.', () async {
      final device = farm.devices["d1"];
      expect(device?.status, DeviceStatus.unknown);
      expect(device?.isOnline, false);

      farm.processMessage(r'homie/d1/$state', 'init');
      expect(device?.status, DeviceStatus.init);
      expect(device?.isOnline, true);

      var event = await events.next;
      expect(event.type, FarmEventType.deviceStatus);
      expect(event.device, equals(device));

      event = await events.next;
      expect(event.type, FarmEventType.deviceState);
      expect(event.device, equals(device));

      farm.processMessage(r'homie/d1/$state', 'disconnected');
      expect(device?.status, DeviceStatus.disconnected);
      expect(device?.isOnline, false);

      farm.processMessage(r'homie/d1/$state', 'ready');
      expect(device?.status, DeviceStatus.ready);
      expect(device?.isOnline, true);

      farm.processMessage(r'homie/d1/$state', 'lost');
      expect(device?.status, DeviceStatus.lost);
      expect(device?.isOnline, false);

      farm.processMessage(r'homie/d1/$state', 'alert');
      expect(device?.status, DeviceStatus.alert);
      expect(device?.isOnline, true);

      farm.processMessage(r'homie/d1/$state', 'sleeping');
      expect(device?.status, DeviceStatus.sleeping);
      expect(device?.isOnline, false);
    });

    test(r'handles $stats/uptime message.', () async {
      final device = farm.devices["d1"];
      expect(device?.uptime, -1);
      farm.processMessage(r'homie/d1/$stats/uptime', '123');
      expect(device?.uptime, 123);

      var event = await events.next;
      expect(event.type, FarmEventType.deviceState);
      expect(event.device, equals(device));
    });

    test(r'handles $name message.', () {
      final device = farm.devices["d1"];
      farm.processMessage(r'homie/d1/$name', 'Some Device');
      expect(device?.name, equals('Some Device'));
    });

    test(r'handles $mac message.', () {
      final device = farm.devices["d1"];
      farm.processMessage(r'homie/d1/$mac', '11:22:33:44:55:66');
      expect(device?.wifi.mac, '11:22:33:44:55:66');
      expect(device?.wifi.isLoaded, false);
    });

    test(r'handles $localip message.', () {
      final device = farm.devices["d1"];
      farm.processMessage(r'homie/d1/$localip', '1.2.3.4');
      expect(device?.wifi.ip, '1.2.3.4');
      expect(device?.wifi.isLoaded, false);
    });

    test(r'handles $stats/signal message.', () async {
      final device = farm.devices["d1"];
      farm.processMessage(r'homie/d1/$stats/signal', 'invalidPayload');
      expect(device?.wifi.signal, -1);

      farm.processMessage(r'homie/d1/$stats/signal', '78');
      expect(device?.wifi.signal, 78);

      expect(device?.wifi.isLoaded, false);

      var event = await events.next;
      expect(event.type, FarmEventType.deviceState);
      expect(event.device, equals(device));
    });

    test(r'handles $fw messages.', () {
      final device = farm.devices["d1"];

      farm.processMessage(r'homie/d1/$fw/name', 'fw-name');
      farm.processMessage(r'homie/d1/$fw/version', '1.2.3');
      expect(device?.firmware.name, 'fw-name');
      expect(device?.firmware.version, '1.2.3');
      expect(device?.firmware.isLoaded, false);

      farm.processMessage(r'homie/d1/$fw/checksum', 'abcd');
      expect(device?.firmware.checksum, 'abcd');
      expect(device?.firmware.isLoaded, true);
    });

    test(r'handles $implementation/config message.', () {
      final device = farm.devices["d1"];

      farm.processMessage(r'homie/d1/$implementation/config', configJson);

      expect(device?.name, 'MyDevice');
      expect(device?.wifi.ssid, 'MyNetwork');
      expect(device?.mqtt.host, 'farm.florafi.net');
      expect(device?.mqtt.port, 123);
      expect(device?.mqtt.ssl, true);
      expect(device?.settings["boolSetting"] as bool, false);
      expect(device?.settings["stringSetting"] as String, 'foobar');
      expect(device?.settings["intSetting"] as int, 1234);
    });

    test(r'satisfies device.isLodaded', () async {
      final device = farm.devices["d1"];

      farm.processMessage(r'homie/d1/$state', 'ready');
      farm.processMessage(r'homie/d1/$stats/uptime', '123');
      farm.processMessage(r'homie/d1/$name', 'Some Device');
      farm.processMessage(r'homie/d1/$mac', '11:22:33:44:55:66');
      farm.processMessage(r'homie/d1/$localip', '1.2.3.4');
      farm.processMessage(r'homie/d1/$stats/signal', '78');
      farm.processMessage(r'homie/d1/$fw/name', 'fw-name');
      farm.processMessage(r'homie/d1/$fw/version', '1.2.3');
      farm.processMessage(r'homie/d1/$fw/checksum', 'abcd');
      farm.processMessage(r'homie/d1/$implementation/config', configJson);

      expect(device?.isLoaded, true);

      final eventStream = events.rest
          .map((e) => e.type)
          .skipWhile((e) => e != FarmEventType.deviceLoaded);
      expect(eventStream, emits(FarmEventType.deviceLoaded));
    });
  });
}
