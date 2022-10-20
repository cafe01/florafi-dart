// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';

class Thermometer extends Sensor {
  @override
  final id = "thermometer";
  @override
  final name = "Termômetro";
  @override
  final measurementId = "temperature";
  @override
  final measurementName = "Temperatura";
  @override
  final measurementUnit = "ºC";
  @override
  final measurementProperty = "last_value";
  Thermometer({required super.device, required super.mqttId})
      : super(schema: {
          "last_value": double,
          "low_temperature_limit": int,
          "high_temperature_limit": int
        });

  double? get lastValue => getProperty("last_value") as double?;
  @override
  double? get measurement => getProperty("last_value") as double?;
  int? get lowTemperatureLimit => getProperty("low_temperature_limit") as int?;
  @override
  int? get goodLowerBound => getProperty("low_temperature_limit") as int?;
  int? get highTemperatureLimit =>
      getProperty("high_temperature_limit") as int?;
  @override
  int? get goodUpperBound => getProperty("high_temperature_limit") as int?;
  set lowTemperatureLimit(int? value) =>
      setControl("low_temperature_limit", value);
  @override
  set goodLowerBound(num? value) => setControl("low_temperature_limit", value);
  set highTemperatureLimit(int? value) =>
      setControl("high_temperature_limit", value);
  @override
  set goodUpperBound(num? value) => setControl("high_temperature_limit", value);
}
