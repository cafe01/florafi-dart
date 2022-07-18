// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import '../component.dart';

class ReservoirMeter extends Sensor {
  @override
  final id = "reservoir_meter";
  @override
  final name = "Medidor de reservatório";
  @override
  final measurementId = "reservoirLevel";
  @override
  final measurementName = "Nível do reservatório";
  @override
  final measurementUnit = "%";
  @override
  final measurementProperty = "level_percent";
  ReservoirMeter({required Room room})
      : super(room: room, schema: {
          "level_percent": int,
          "distance_cm": int,
          "low_alert_limit": int,
          "overflow_alert_limit": int,
          "maintenance_action": int,
          "empty_distance_cm": int,
          "full_distance_cm": int
        });

  int? get levelPercent => getProperty("level_percent") as int?;
  @override
  int? get measurement => getProperty("level_percent") as int?;
  int? get distanceCm => getProperty("distance_cm") as int?;
  int? get lowAlertLimit => getProperty("low_alert_limit") as int?;
  @override
  int? get goodLowerBound => getProperty("low_alert_limit") as int?;
  int? get overflowAlertLimit => getProperty("overflow_alert_limit") as int?;
  @override
  int? get goodUpperBound => getProperty("overflow_alert_limit") as int?;
  int? get maintenanceAction => getProperty("maintenance_action") as int?;
  int? get emptyDistanceCm => getProperty("empty_distance_cm") as int?;
  int? get fullDistanceCm => getProperty("full_distance_cm") as int?;
  set lowAlertLimit(int? value) => setControl("low_alert_limit", value);
  @override
  set goodLowerBound(num? value) => setControl("low_alert_limit", value);
  set overflowAlertLimit(int? value) =>
      setControl("overflow_alert_limit", value);
  @override
  set goodUpperBound(num? value) => setControl("overflow_alert_limit", value);
  set maintenanceAction(int? value) => setControl("maintenance_action", value);
  set emptyDistanceCm(int? value) => setControl("empty_distance_cm", value);
  set fullDistanceCm(int? value) => setControl("full_distance_cm", value);
}
