import '../room.dart';
import '../component.dart';

abstract class PhmeterBase extends Sensor {
  PhmeterBase({required Room room, Map<String, Type>? schema})
      : super(room: room, schema: schema);

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
