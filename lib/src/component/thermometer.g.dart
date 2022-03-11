// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';
import '../room.dart';

class Thermometer extends Sensor {
  @override
  final id = "thermometer";
  @override
  final name = "Termômetro";
  @override
  final measurementName = "Temperatura";
  Thermometer({required Room room}) : super(room: room);

  double? get lastValue => getDouble("last_value");
  int? get lowTemperatureLimit => getInt("low_temperature_limit");
  int? get highTemperatureLimit => getInt("high_temperature_limit");
  set lowTemperatureLimit(int? value) =>
      setControl("low_temperature_limit", value);
  set highTemperatureLimit(int? value) =>
      setControl("high_temperature_limit", value);
}
