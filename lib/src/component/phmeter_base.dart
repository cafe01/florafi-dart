import '../component.dart';

abstract class PhmeterBase extends Sensor {
  PhmeterBase(
      {required super.room, required super.mqttId, Map<String, Type>? schema})
      : super(schema: schema);

  calibrate() {
    if (device == null || !device!.isOnline) return;
    final topic = "florafi-endpoint/${device!.id}/ph-meter/calibrate";
    room.farm.publish(topic, "1");
  }

  resetCalibration() {
    if (device == null || !device!.isOnline) return;
    final topic = "florafi-endpoint/${device!.id}/ph-meter/reset_calibration";
    room.farm.publish(topic, "1");
  }
}
