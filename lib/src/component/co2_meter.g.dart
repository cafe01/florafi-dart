// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import '../component.dart';

class Co2Meter extends Sensor {
  @override
  final id = "co2_meter";
  @override
  final name = "Medidor de CO2";
  @override
  final measurementId = "co2";
  @override
  final measurementName = "Nível de CO2";
  @override
  final measurementUnit = "ppm";
  Co2Meter({required Room room})
      : super(room: room, schema: {
          "measurement": int,
          "good_lower_bound": int,
          "good_upper_bound": int
        });

  @override
  int? get measurement => getProperty("measurement") as int?;
  @override
  int? get goodLowerBound => getProperty("good_lower_bound") as int?;
  @override
  int? get goodUpperBound => getProperty("good_upper_bound") as int?;
  @override
  set goodLowerBound(num? value) => setControl("good_lower_bound", value);
  @override
  set goodUpperBound(num? value) => setControl("good_upper_bound", value);
}
