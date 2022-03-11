// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';
import '../room.dart';

class Relay extends Component {
  Relay({required Room room}) : super(room: room) {
    id = "relay";
  }

  int? get lastOn => getInt("last_on");
  int? get lastOff => getInt("last_off");
  bool? get power => getBool("power");
  bool? get automation => getBool("automation");
  int? get cooldownDuration => getInt("cooldown_duration");
  set power(bool? value) => setControl("power", value);
  set automation(bool? value) => setControl("automation", value);
  set cooldownDuration(int? value) => setControl("cooldown_duration", value);
}
