// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';
import '../room.dart';

class LightSensor extends Sensor {
  LightSensor({required Room room}) : super(room: room) {
    id = "light_sensor";
    name = "Sensor de luminosidade";
    measurementName = "Iluminação";
  }

  int? get intensity => getInt("intensity");
  int? get minIntensityDayAlert => getInt("min_intensity_day_alert");
  int? get maxIntensityNightAlert => getInt("max_intensity_night_alert");
  set minIntensityDayAlert(int? value) =>
      setControl("min_intensity_day_alert", value);
  set maxIntensityNightAlert(int? value) =>
      setControl("max_intensity_night_alert", value);
}
