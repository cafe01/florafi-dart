// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import '../component.dart';

abstract class Relay extends Component {
  Relay({required super.room, required super.mqttId, Map<String, Type>? schema})
      : super(schema: {
          "last_on": int,
          "last_off": int,
          "power": bool,
          "automation": bool,
          "cooldown_duration": int,
          ...?schema
        });

  int? get lastOn => getProperty("last_on") as int?;
  int? get lastOff => getProperty("last_off") as int?;
  bool? get power => getProperty("power") as bool?;
  bool? get automation => getProperty("automation") as bool?;
  int? get cooldownDuration => getProperty("cooldown_duration") as int?;
  set power(bool? value) => setControl("power", value);
  set automation(bool? value) => setControl("automation", value);
  set cooldownDuration(int? value) => setControl("cooldown_duration", value);
}
