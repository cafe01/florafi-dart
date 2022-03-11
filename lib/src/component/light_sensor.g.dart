// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import '../component.dart';

class LightSensor extends Sensor {
  @override
  final id = "light_sensor";
  @override
  final name = "Sensor de luminosidade";
  @override
  final measurementName = "Iluminação";
  LightSensor({required Room room})
      : super(room: room, schema: {
          "intensity": int,
          "min_intensity_day_alert": int,
          "max_intensity_night_alert": int
        });

  int? get intensity => getProperty("intensity") as int?;
  int? get minIntensityDayAlert =>
      getProperty("min_intensity_day_alert") as int?;
  int? get maxIntensityNightAlert =>
      getProperty("max_intensity_night_alert") as int?;
  set minIntensityDayAlert(int? value) =>
      setControl("min_intensity_day_alert", value);
  set maxIntensityNightAlert(int? value) =>
      setControl("max_intensity_night_alert", value);
}
