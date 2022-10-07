import '../component.dart';

abstract class PhmeterBase extends Sensor {
  PhmeterBase(
      {required super.device, required super.mqttId, Map<String, Type>? schema})
      : super(schema: schema);

  calibrate() {
    if (!device.isOnline) return;
    device.publishEndpoint("ph-meter/calibrate", "1");
  }

  resetCalibration() {
    if (!device.isOnline) return;
    device.publishEndpoint("ph-meter/reset_calibration", "1");
  }
}
