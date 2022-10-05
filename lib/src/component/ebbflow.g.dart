// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import '../component.dart';

class Ebbflow extends Component {
  @override
  final id = "ebbflow";
  @override
  final name = "Irrigação ebbflow";
  Ebbflow({required super.room, required super.mqttId})
      : super(schema: {
          "is_empty": bool,
          "is_full": bool,
          "last_empty": int,
          "last_drain": int,
          "last_flood": int,
          "last_full": int,
          "phase": int,
          "flood_automation": bool,
          "min_empty_seconds": int,
          "min_drain_seconds": int,
          "max_drain_minutes": int,
          "max_flood_minutes": int,
          "min_full_seconds": int,
          "max_full_seconds": int,
          "max_unfull_minutes": int,
          "day_interval": int,
          "night_interval": int
        });

  bool? get isEmpty => getProperty("is_empty") as bool?;
  bool? get isFull => getProperty("is_full") as bool?;
  int? get lastEmpty => getProperty("last_empty") as int?;
  int? get lastDrain => getProperty("last_drain") as int?;
  int? get lastFlood => getProperty("last_flood") as int?;
  int? get lastFull => getProperty("last_full") as int?;
  int? get phase => getProperty("phase") as int?;
  bool? get floodAutomation => getProperty("flood_automation") as bool?;
  int? get minEmptySeconds => getProperty("min_empty_seconds") as int?;
  int? get minDrainSeconds => getProperty("min_drain_seconds") as int?;
  int? get maxDrainMinutes => getProperty("max_drain_minutes") as int?;
  int? get maxFloodMinutes => getProperty("max_flood_minutes") as int?;
  int? get minFullSeconds => getProperty("min_full_seconds") as int?;
  int? get maxFullSeconds => getProperty("max_full_seconds") as int?;
  int? get maxUnfullMinutes => getProperty("max_unfull_minutes") as int?;
  int? get dayInterval => getProperty("day_interval") as int?;
  int? get nightInterval => getProperty("night_interval") as int?;
  set phase(int? value) => setControl("phase", value);
  set floodAutomation(bool? value) => setControl("flood_automation", value);
  set minEmptySeconds(int? value) => setControl("min_empty_seconds", value);
  set minDrainSeconds(int? value) => setControl("min_drain_seconds", value);
  set maxDrainMinutes(int? value) => setControl("max_drain_minutes", value);
  set maxFloodMinutes(int? value) => setControl("max_flood_minutes", value);
  set minFullSeconds(int? value) => setControl("min_full_seconds", value);
  set maxFullSeconds(int? value) => setControl("max_full_seconds", value);
  set maxUnfullMinutes(int? value) => setControl("max_unfull_minutes", value);
  set dayInterval(int? value) => setControl("day_interval", value);
  set nightInterval(int? value) => setControl("night_interval", value);
}
