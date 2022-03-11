// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import '../component.dart';

class Thermometer extends Sensor {
  @override
  final id = "thermometer";
  @override
  final name = "Termômetro";
  @override
  final measurementName = "Temperatura";
  Thermometer({required Room room})
      : super(room: room, schema: {
          "last_value": double,
          "low_temperature_limit": int,
          "high_temperature_limit": int
        });

  double? get lastValue => getProperty("last_value") as double?;
  int? get lowTemperatureLimit => getProperty("low_temperature_limit") as int?;
  int? get highTemperatureLimit =>
      getProperty("high_temperature_limit") as int?;
  set lowTemperatureLimit(int? value) =>
      setControl("low_temperature_limit", value);
  set highTemperatureLimit(int? value) =>
      setControl("high_temperature_limit", value);
}
