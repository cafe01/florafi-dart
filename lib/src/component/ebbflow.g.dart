// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';
import '../room.dart';

class Ebbflow extends Component {
  Ebbflow(Room room) : super(room: room) {
    name = "Irrigação ebbflow";
  }

  bool? get isEmpty => getBool("is_empty");
  bool? get isFull => getBool("is_full");
  int? get lastEmpty => getInt("last_empty");
  int? get lastDrain => getInt("last_drain");
  int? get lastFlood => getInt("last_flood");
  int? get lastFull => getInt("last_full");
  int? get phase => getInt("phase");
  bool? get floodAutomation => getBool("flood_automation");
  int? get minEmptySeconds => getInt("min_empty_seconds");
  int? get minDrainSeconds => getInt("min_drain_seconds");
  int? get maxDrainMinutes => getInt("max_drain_minutes");
  int? get maxFloodMinutes => getInt("max_flood_minutes");
  int? get minFullSeconds => getInt("min_full_seconds");
  int? get maxFullSeconds => getInt("max_full_seconds");
  int? get maxUnfullMinutes => getInt("max_unfull_minutes");
  int? get dayInterval => getInt("day_interval");
  int? get nightInterval => getInt("night_interval");
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
