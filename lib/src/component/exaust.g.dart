// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';
import '../room.dart';
import 'relay.g.dart';

class Exaust extends Relay {
  @override
  final id = "exaust";
  @override
  final name = "Exaustor";
  Exaust({required Room room}) : super(room: room);

  bool? get daytimeEnabled => getBool("daytime_enabled");
  bool? get nighttimeEnabled => getBool("nighttime_enabled");
  bool? get highTemperatureDisabled => getBool("high_temperature_disabled");
  set daytimeEnabled(bool? value) => setControl("daytime_enabled", value);
  set nighttimeEnabled(bool? value) => setControl("nighttime_enabled", value);
  set highTemperatureDisabled(bool? value) =>
      setControl("high_temperature_disabled", value);
}
