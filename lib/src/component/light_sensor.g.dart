// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';
import '../room.dart';

class LightSensor extends Sensor {
  @override
  final id = "light_sensor";
  @override
  final name = "Sensor de luminosidade";
  @override
  final measurementName = "Iluminação";
  LightSensor({required Room room}) : super(room: room);

  int? get intensity => getInt("intensity");
  int? get minIntensityDayAlert => getInt("min_intensity_day_alert");
  int? get maxIntensityNightAlert => getInt("max_intensity_night_alert");
  set minIntensityDayAlert(int? value) =>
      setControl("min_intensity_day_alert", value);
  set maxIntensityNightAlert(int? value) =>
      setControl("max_intensity_night_alert", value);
}
