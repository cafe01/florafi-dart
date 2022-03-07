// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';
import '../room.dart';

class Hygrometer extends Sensor {
  Hygrometer(Room room) : super(room: room) {
    name = "Higrômetro";
    measurementName = "Umidade";
  }

  double? get lastValue => getDouble("last_value");
  int? get lowHumidityLimit => getInt("low_humidity_limit");
  int? get highHumidityLimit => getInt("high_humidity_limit");
  set lowHumidityLimit(int? value) => setControl("low_humidity_limit", value);
  set highHumidityLimit(int? value) => setControl("high_humidity_limit", value);
}
