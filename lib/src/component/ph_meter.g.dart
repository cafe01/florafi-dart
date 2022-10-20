// This file was auto-generated
// Do NOT EDIT by hand

import 'phmeter_base.dart';

class PhMeter extends PhMeterBase {
  @override
  final id = "ph_meter";
  @override
  final name = "Medidor de pH";
  @override
  final measurementId = "ph";
  @override
  final measurementName = "pH";
  @override
  final measurementUnit = "";
  @override
  final measurementProperty = "current_value";
  PhMeter({required super.device, required super.mqttId})
      : super(schema: {
          "current_value": double,
          "last_calibration_time": int,
          "low_ph_warning_limit": double,
          "high_ph_warning_limit": double,
          "sensor_calibration_interval": int
        });

  double? get currentValue => getProperty("current_value") as double?;
  @override
  double? get measurement => getProperty("current_value") as double?;
  int? get lastCalibrationTime => getProperty("last_calibration_time") as int?;
  double? get lowPhWarningLimit =>
      getProperty("low_ph_warning_limit") as double?;
  @override
  double? get goodLowerBound => getProperty("low_ph_warning_limit") as double?;
  double? get highPhWarningLimit =>
      getProperty("high_ph_warning_limit") as double?;
  @override
  double? get goodUpperBound => getProperty("high_ph_warning_limit") as double?;
  int? get sensorCalibrationInterval =>
      getProperty("sensor_calibration_interval") as int?;
  set lowPhWarningLimit(double? value) =>
      setControl("low_ph_warning_limit", value);
  @override
  set goodLowerBound(num? value) => setControl("low_ph_warning_limit", value);
  set highPhWarningLimit(double? value) =>
      setControl("high_ph_warning_limit", value);
  @override
  set goodUpperBound(num? value) => setControl("high_ph_warning_limit", value);
  set sensorCalibrationInterval(int? value) =>
      setControl("sensor_calibration_interval", value);
}
