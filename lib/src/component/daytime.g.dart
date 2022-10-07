// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import '../component.dart';

class Daytime extends Component {
  @override
  final id = "daytime";
  @override
  final name = "Fotoperíodo";
  Daytime({required super.device, required super.mqttId})
      : super(schema: {
          "is_daytime": bool,
          "start_hour": int,
          "duration": int,
          "start_delay": int
        });

  bool? get isDaytime => getProperty("is_daytime") as bool?;
  int? get startHour => getProperty("start_hour") as int?;
  int? get duration => getProperty("duration") as int?;
  int? get startDelay => getProperty("start_delay") as int?;
  set startHour(int? value) => setControl("start_hour", value);
  set duration(int? value) => setControl("duration", value);
  set startDelay(int? value) => setControl("start_delay", value);
}
