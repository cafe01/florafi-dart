// florafi/room/q1/alert/warning/interval-irrigation-automation-disabled 1643471010

import 'dart:math';

import 'package:async/async.dart';
import 'package:florafi/src/device.dart';
import 'package:test/test.dart';
import 'package:florafi/florafi.dart';

void main() {
  group("_processHomieMessage()", () {
    late Farm farm;
    late StreamQueue<FarmEvent> events;

// homie/d1/$implementation/config {"name":"Ebbflow","wifi":{"ssid":"Spectorzinho"},"mqtt":{"host":"farm.florafi.net","port":10002,"ssl":false,"auth":true},"ota":{"enabled":true},"settings":{"invert_empty":false,"invert_full":true,"deactivated":false,"garden_room":"ap3q1b"}}
// homie/d1/$implementation/ota/enabled true

    final List<FarmMessage> messages = [
      FarmMessage('florafi/device/d1', '{"room":"Q1","deactivated":false}'),
    ];

    setUp(() {
      farm = Farm();
      events = StreamQueue<FarmEvent>(farm.events);

      for (var m in messages) {
        farm.processMessage(m.topic, m.data);
      }
    });

    test(r'handles $stats/uptime message.', () {
      final device = farm.devices["d1"];
      expect(device?.uptime, -1);
      farm.processMessage(r'homie/d1/$stats/uptime', '123');
      expect(device?.uptime, 123);
    });
  });
}
