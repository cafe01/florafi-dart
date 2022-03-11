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
  final measurementName = "Umidade";
  Hygrometer({required Room room})
      : super(room: room, schema: {
          "last_value": double,
          "low_humidity_limit": int,
          "high_humidity_limit": int
        });

  double? get lastValue => getProperty("last_value") as double?;
  int? get lowHumidityLimit => getProperty("low_humidity_limit") as int?;
  int? get highHumidityLimit => getProperty("high_humidity_limit") as int?;
  set lowHumidityLimit(int? value) => setControl("low_humidity_limit", value);
  set highHumidityLimit(int? value) => setControl("high_humidity_limit", value);
}
