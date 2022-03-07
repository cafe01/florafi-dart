// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';
import '../room.dart';
import 'relay.g.dart';

class IntervalIrrigation extends Relay {
  IntervalIrrigation({required Room room}) : super(room: room) {
    name = "Irrigação intermitente";
  }

  int? get dayInterval => getInt("day_interval");
  int? get nightInterval => getInt("night_interval");
  int? get duration => getInt("duration");
  String? get durationUnit => getString("duration_unit");
  set dayInterval(int? value) => setControl("day_interval", value);
  set nightInterval(int? value) => setControl("night_interval", value);
  set duration(int? value) => setControl("duration", value);
  set durationUnit(String? value) => setControl("duration_unit", value);
}
