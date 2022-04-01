import 'package:logging/logging.dart';

import 'device.dart';
import 'events.dart';
import 'room.dart';

final _log = Logger("Component");

class UnknownPropertyError implements Exception {
  final String componentId;
  final String propertyId;
  UnknownPropertyError(this.componentId, this.propertyId);
  @override
  String toString() {
    return "UnknownPropertyError: '$componentId.$propertyId'.";
  }
}

abstract class Component {
  Component({required this.room, Map<String, Type>? schema}) {
    if (schema != null) {
      _schema.addAll(schema);
    }
  }
  Room room;
  Device? device;
  String get id;
  String get name;

  Stream<FarmEvent> get events =>
      room.events.where((event) => event.component == this);

  final Map<String, Type> _schema = {};
  final Map<String, Object?> _state = {};
  final Map<String, String> _control = {};

  bool get hasDevice => device != null;
  bool get isOnline => device?.isOnline ?? false;

  bool hasProperty(String propertyId) {
    return _schema.containsKey(propertyId);
  }

  Object? getProperty(String propertyId) {
    if (!hasProperty(propertyId)) {
      throw UnknownPropertyError(id, propertyId);
    }
    return _state[propertyId];
  }

  Object? consumeState(String propertyId, String value) {
    final type = _schema[propertyId];
    if (type == null) {
      throw UnknownPropertyError(id, propertyId);
    }

    value = value.trim();
    if (value.isEmpty) {
      _state.remove(propertyId);
      return null;
    }

    Object? parsedValue;

    if (type == int) {
      parsedValue = int.tryParse(value);
    } else if (type == double) {
      parsedValue = double.tryParse(value);
    } else if (type == bool) {
      parsedValue =
          (value == "1" || value.toLowerCase() == "on") ? true : false;
    } else {
      parsedValue = value;
    }

    _state[propertyId] = parsedValue;

    return parsedValue;
  }

  void consumeControl(String name, String endpoint) {
    if (endpoint.isEmpty) {
      _control.remove(name);
    } else {
      _control[name] = endpoint;
    }
  }

  void setControl(String prop, Object? value) {
    String? endpoint = _control[prop];
    if (endpoint == null) {
      _log.warning("Unknown control '$prop'");
      return;
    }

    late String payload;
    if (value == null) {
      payload = "";
    } else if (value is bool) {
      payload = value ? "1" : "0";
    } else if (value is double) {
      payload = value.toStringAsFixed(2);
    } else {
      payload = value.toString();
    }

    room.farm.publish(endpoint, payload);
  }
}

abstract class Sensor extends Component {
  Sensor({required Room room, Map<String, Type>? schema})
      : super(room: room, schema: {...?schema});
  final isSensor = true;
  String get measurementId;
  String get measurementName;
  String get measurementUnit => "";
  String get measurementProperty;
  num? get measurement;
  num? get goodUpperBound;
  num? get goodLowerBound;
  set goodUpperBound(num? value);
  set goodLowerBound(num? value);

  bool get isGoodMeasurement {
    final value = measurement;
    final lowerBound = goodLowerBound;
    final upperBound = goodUpperBound;
    if (value != null) {
      if (lowerBound != null && value < lowerBound) return false;
      if (upperBound != null && value > upperBound) return false;
    }
    return true;
  }
}
