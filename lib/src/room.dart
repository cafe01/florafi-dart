import 'component/components.dart';
import 'farm.dart';

// final _log = Logger('Room');

class Room {
  Room(this.id, {required this.farm});

  String id;
  Farm farm;

  Thermometer? thermometer;

  Component? resolveComponent(String componentId) {
    switch (componentId) {
      case "thermometer":
      case "temperature":
        return thermometer ??= Thermometer(this);
      default:
        return null;
    }
  }
}
