// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import '../component.dart';

class VpdMeter extends Sensor {
  @override
  final id = "vpd_meter";
  @override
  final name = "Medidor VPD";
  @override
  final measurementId = "vpd";
  @override
  final measurementName = "VPD";
  @override
  final measurementUnit = "pa";
  VpdMeter({required super.device, required super.mqttId})
      : super(schema: {
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
