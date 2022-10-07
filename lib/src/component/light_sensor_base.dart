import '../component.dart';

abstract class LightSensorBase extends Sensor {
  LightSensorBase(
      {required super.device, required super.mqttId, Map<String, Type>? schema})
      : super(schema: schema);

  @override
  bool get isGoodMeasurement {
    final isDaytime = device.room?.isDaytime;
    final value = measurement;
    final lowerBound = goodLowerBound;
    final upperBound = goodUpperBound;
    if (value != null && isDaytime != null) {
      if (lowerBound != null && isDaytime && value < lowerBound) return false;
      if (upperBound != null && !isDaytime && value > upperBound) return false;
    }
    return true;
  }
}
