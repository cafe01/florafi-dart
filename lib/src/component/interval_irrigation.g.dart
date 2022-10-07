// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import 'relay.g.dart';

class IntervalIrrigation extends Relay {
  @override
  final id = "interval_irrigation";
  @override
  final name = "Irrigação intermitente";
  IntervalIrrigation({required super.device, required super.mqttId})
      : super(schema: {
          "day_interval": int,
          "night_interval": int,
          "duration": int,
          "duration_unit": String
        });

  int? get dayInterval => getProperty("day_interval") as int?;
  int? get nightInterval => getProperty("night_interval") as int?;
  int? get duration => getProperty("duration") as int?;
  String? get durationUnit => getProperty("duration_unit") as String?;
  set dayInterval(int? value) => setControl("day_interval", value);
  set nightInterval(int? value) => setControl("night_interval", value);
  set duration(int? value) => setControl("duration", value);
  set durationUnit(String? value) => setControl("duration_unit", value);
}
