// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import 'relay.g.dart';

class Lighting extends Relay {
  @override
  final id = "lighting";
  @override
  final name = "Iluminação";
  Lighting({required super.room, required super.mqttId})
      : super(schema: {"high_temperature_limit": int});

  int? get highTemperatureLimit =>
      getProperty("high_temperature_limit") as int?;
  set highTemperatureLimit(int? value) =>
      setControl("high_temperature_limit", value);
}
