import '../room.dart';
import '../component.dart';

abstract class LightSensorBase extends Sensor {
  LightSensorBase({required Room room, Map<String, Type>? schema})
      : super(room: room, schema: schema);

  @override
  bool get isGoodMeasurement {
    final value = measurement;
    final lowerBound = goodLowerBound;
    final upperBound = goodUpperBound;
    final isDaytime = room.daytime?.isDaytime;
    if (value != null && isDaytime != null) {
      if (lowerBound != null && isDaytime && value < lowerBound) return false;
      if (upperBound != null && !isDaytime && value > upperBound) return false;
    }
    return true;
  }
}
