import '../component.dart';

abstract class LightSensorBase extends Sensor {
  LightSensorBase(
      {required super.room, required super.mqttId, Map<String, Type>? schema})
      : super(schema: schema);

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
