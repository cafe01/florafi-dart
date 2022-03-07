// This file was auto-generated
// Do NOT EDIT by hand

import '../component.dart';
import '../room.dart';
import 'relay.g.dart';

class ThresholdRelay extends Relay {
  ThresholdRelay({required Room room}) : super(room: room);

  int? get deactivationThreshold => getInt("deactivation_threshold");
  int? get activationThreshold => getInt("activation_threshold");
  set deactivationThreshold(int? value) =>
      setControl("deactivation_threshold", value);
  set activationThreshold(int? value) =>
      setControl("activation_threshold", value);
}
