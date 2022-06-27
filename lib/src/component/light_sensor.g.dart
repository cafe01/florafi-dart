// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import 'light_sensor_base.dart';

class LightSensor extends LightSensorBase {
  @override
  final id = "light_sensor";
  @override
  final name = "Sensor de luminosidade";
  @override
  final measurementId = "light";
  @override
  final measurementName = "Luminosidade";
  @override
  final measurementUnit = "%";
  @override
  final measurementProperty = "intensity";
  LightSensor({required Room room})
      : super(room: room, schema: {
          "intensity": int,
          "min_intensity_day_alert": int,
          "max_intensity_night_alert": int
        });

  int? get intensity => getProperty("intensity") as int?;
  @override
  int? get measurement => getProperty("intensity") as int?;
  int? get minIntensityDayAlert =>
      getProperty("min_intensity_day_alert") as int?;
  @override
  int? get goodLowerBound => getProperty("min_intensity_day_alert") as int?;
  int? get maxIntensityNightAlert =>
      getProperty("max_intensity_night_alert") as int?;
  @override
  int? get goodUpperBound => getProperty("max_intensity_night_alert") as int?;
  set minIntensityDayAlert(int? value) =>
      setControl("min_intensity_day_alert", value);
  @override
  set goodLowerBound(num? value) =>
      setControl("min_intensity_day_alert", value);
  set maxIntensityNightAlert(int? value) =>
      setControl("max_intensity_night_alert", value);
  @override
  set goodUpperBound(num? value) =>
      setControl("max_intensity_night_alert", value);
}
