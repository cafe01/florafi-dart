// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';
import '../room.dart';

class Hygrometer extends Sensor {
  @override
  final id = "hygrometer";
  @override
  final name = "Higrômetro";
  @override
  final measurementName = "Umidade";
  Hygrometer({required Room room}) : super(room: room);

  double? get lastValue => getDouble("last_value");
  int? get lowHumidityLimit => getInt("low_humidity_limit");
  int? get highHumidityLimit => getInt("high_humidity_limit");
  set lowHumidityLimit(int? value) => setControl("low_humidity_limit", value);
  set highHumidityLimit(int? value) => setControl("high_humidity_limit", value);
}
