// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import 'relay.g.dart';

class Exaust extends Relay {
  @override
  final id = "exaust";
  @override
  final name = "Exaustor";
  Exaust({required super.device, required super.mqttId})
      : super(schema: {
          "daytime_enabled": bool,
          "nighttime_enabled": bool,
          "high_temperature_disabled": bool
        });

  bool? get daytimeEnabled => getProperty("daytime_enabled") as bool?;
  bool? get nighttimeEnabled => getProperty("nighttime_enabled") as bool?;
  bool? get highTemperatureDisabled =>
      getProperty("high_temperature_disabled") as bool?;
  set daytimeEnabled(bool? value) => setControl("daytime_enabled", value);
  set nighttimeEnabled(bool? value) => setControl("nighttime_enabled", value);
  set highTemperatureDisabled(bool? value) =>
      setControl("high_temperature_disabled", value);
}
