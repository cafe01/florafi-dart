// import 'package:florafi/florafi.dart';
import 'package:logging/logging.dart';

import 'alert.dart';
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
  Component(
      {required this.device, required this.mqttId, Map<String, Type>? schema}) {
    if (schema != null) {
      _schema.addAll(schema);
    }
  }
  // Room room;
  Device device;
  String get id;
  String get name;
  String mqttId;

  final Map<String, Type> _schema = {};
  final Map<String, Object?> _state = {};

  Stream<FarmEvent> get events =>
      device.farm.events.where((event) => event.component == this);

  Iterable<Alert> get alerts =>
      device.farm.alerts.values.where((alert) => alert.component == this);

  bool get isOnline => device.isOnline;

  Room? get room => device.room;
  bool get hasRoom => device.room != null;

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

  void setControl(String prop, Object? value) {
    // prop type
    final propType = _schema[prop];
    if (propType == null) {
      _log.warning("can't setControl(): '$id' doesn't have prop '$prop'");
      return;
    }

    // cast double to int
    if (value is double && propType == int) {
      _log.info(
          "setControl(): '$id.$prop': casting from double($value) to int(${value.round()})");
      value = value.round();
    }

    // wrong type
    if (value != null && value.runtimeType != propType) {
      _log.warning(
          "can't setControl(): '$id.$prop' is a $propType, not '${value.runtimeType}'");
      return;
    }

    // prepare payload
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

    // publish
    final endpoint = "florafi-endpoint/${device.id}/$mqttId/$prop";
    device.farm.publish(endpoint, payload);
  }
}

abstract class Sensor extends Component {
  Sensor(
      {required super.device, required super.mqttId, Map<String, Type>? schema})
      : super(schema: {...?schema});

  String get measurementId;
  String get measurementName;
  String get measurementUnit => "";
  String get measurementProperty => "measurement";
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
