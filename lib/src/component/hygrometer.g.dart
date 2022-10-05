// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import '../component.dart';

class Hygrometer extends Sensor {
  @override
  final id = "hygrometer";
  @override
  final name = "Higrômetro";
  @override
  final measurementId = "humidity";
  @override
  final measurementName = "Umidade";
  @override
  final measurementUnit = "%";
  @override
  final measurementProperty = "last_value";
  Hygrometer({required super.room, required super.mqttId})
      : super(schema: {
          "last_value": double,
          "low_humidity_limit": int,
          "high_humidity_limit": int
        });

  double? get lastValue => getProperty("last_value") as double?;
  @override
  double? get measurement => getProperty("last_value") as double?;
  int? get lowHumidityLimit => getProperty("low_humidity_limit") as int?;
  @override
  int? get goodLowerBound => getProperty("low_humidity_limit") as int?;
  int? get highHumidityLimit => getProperty("high_humidity_limit") as int?;
  @override
  int? get goodUpperBound => getProperty("high_humidity_limit") as int?;
  set lowHumidityLimit(int? value) => setControl("low_humidity_limit", value);
  @override
  set goodLowerBound(num? value) => setControl("low_humidity_limit", value);
  set highHumidityLimit(int? value) => setControl("high_humidity_limit", value);
  @override
  set goodUpperBound(num? value) => setControl("high_humidity_limit", value);
}
