// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';
import '../room.dart';

class Daytime extends Component {
  @override
  final id = "daytime";
  @override
  final name = "Fotoperíodo";
  Daytime({required Room room}) : super(room: room);

  bool? get isDaytime => getBool("is_daytime");
  int? get startHour => getInt("start_hour");
  int? get duration => getInt("duration");
  int? get startDelay => getInt("start_delay");
  set startHour(int? value) => setControl("start_hour", value);
  set duration(int? value) => setControl("duration", value);
  set startDelay(int? value) => setControl("start_delay", value);
}
