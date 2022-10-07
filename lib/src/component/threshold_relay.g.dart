// This file was auto-generated
// Do NOT EDIT by hand

import '../room.dart';
import 'relay.g.dart';

abstract class ThresholdRelay extends Relay {
  ThresholdRelay(
      {required super.device, required super.mqttId, Map<String, Type>? schema})
      : super(schema: {
          "deactivation_threshold": int,
          "activation_threshold": int,
          ...?schema
        });

  int? get deactivationThreshold =>
      getProperty("deactivation_threshold") as int?;
  int? get activationThreshold => getProperty("activation_threshold") as int?;
  set deactivationThreshold(int? value) =>
      setControl("deactivation_threshold", value);
  set activationThreshold(int? value) =>
      setControl("activation_threshold", value);
}
