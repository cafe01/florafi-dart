import 'component/components.dart';
import 'farm.dart';

// final _log = Logger('Room');

class Room {
  Room(this.id, {required this.farm});

  String id;
  Farm farm;

  Daytime? daytime;
  Dehumidifier? dehumidifier;
  EbbflowFlood? ebbflowFlood;
  EbbflowDrain? ebbflowDrain;
  Ebbflow? ebbflow;
  Exaust? exaust;
  Humidifier? humidifier;
  Hygrometer? hygrometer;
  IntervalIrrigation? intervalIrrigation;
  LightSensor? lightSensor;
  Lighting? lighting;
  Thermometer? thermometer;

  Component? resolveComponent(String componentId) {
    switch (componentId) {
      case "daytime":
        return daytime ??= Daytime(room: this);
      case "dehumidifier-relay":
        return dehumidifier ??= Dehumidifier(room: this);
      case "ebbflow-drain-relay":
        return ebbflowDrain ??= EbbflowDrain(room: this);
      case "ebbflow-flood-relay":
        return ebbflowFlood ??= EbbflowFlood(room: this);
      case "ebbflow":
        return ebbflow ??= Ebbflow(room: this);
      case "exaust-relay":
        return exaust ??= Exaust(room: this);
      case "humidifier-relay":
        return humidifier ??= Humidifier(room: this);
      case "humidity":
        return hygrometer ??= Hygrometer(room: this);
      case "interval-irrigation":
        return intervalIrrigation ??= IntervalIrrigation(room: this);
      case "light":
        return lightSensor ??= LightSensor(room: this);
      case "light-relay":
        return lighting ??= Lighting(room: this);
      case "temperature":
        return thermometer ??= Thermometer(room: this);
      default:
        return null;
    }
  }

  bool? removeComponent(String componentId) {
    late final Component? component;
    switch (componentId) {
      case "daytime":
        component = daytime;
        daytime = null;
        break;
      case "dehumidifier-relay":
        component = dehumidifier;
        dehumidifier = null;
        break;
      case "ebbflow-drain-relay":
        component = ebbflowDrain;
        ebbflowDrain = null;
        break;
      case "ebbflow-flood-relay":
        component = ebbflowFlood;
        ebbflowFlood = null;
        break;
      case "ebbflow":
        component = ebbflow;
        ebbflow = null;
        break;
      case "exaust-relay":
        component = exaust;
        exaust = null;
        break;
      case "humidifier-relay":
        component = humidifier;
        humidifier = null;
        break;
      case "humidity":
        component = hygrometer;
        hygrometer = null;
        break;
      case "interval-irrigation":
        component = intervalIrrigation;
        intervalIrrigation = null;
        break;
      case "light":
        component = lightSensor;
        lightSensor = null;
        break;
      case "light-relay":
        component = lighting;
        lighting = null;
        break;
      case "temperature":
        component = thermometer;
        thermometer = null;
        break;
      default:
        return null;
    }

    return component != null;
  }
}
