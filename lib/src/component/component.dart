import 'package:logging/logging.dart';

import '../device.dart';
import '../room.dart';

final _log = Logger("Component");

abstract class Component {
  Component({required this.room});
  Room room;
  Device? device;
  late final String name;
  final Map<String, String> _state = {};
  final Map<String, String> _control = {};

  bool get hasDevice => device != null;

  void consumeState(String prop, String value) {
    if (value.isEmpty) {
      _state.remove(prop);
    } else {
      _state[prop] = value;
    }
  }

  void consumeControl(String name, String endpoint) {
    if (endpoint.isEmpty) {
      _control.remove(name);
    } else {
      _control[name] = endpoint;
    }
  }

  int? getInt(String prop) {
    return int.tryParse(_state[prop] ?? "");
  }

  bool? getBool(String prop) {
    final value = _state[prop];
    if (value == null) {
      return null;
    }

    if (value == "1" || value.toLowerCase() == "on") {
      return true;
    }

    return false;
  }

  String? getString(String prop) {
    return _state[prop];
  }

  void setControl(String prop, Object? value) {
    String? endpoint = _control[prop];
    if (endpoint == null) {
      _log.warning("Unknown control '$prop'");
      return;
    }

    String payload = "";
    if (value != null) {
      payload = value.toString();
    }

    room.farm.publish(endpoint, payload);
  }
}

mixin Sensor {
  final isSensor = true;
  late final String measurementName;
}
