import 'component/extension/datetime.ext.dart';
import 'alert.dart';
import 'component/components.dart';
import 'device.dart';
import 'events.dart';
import 'farm.dart';
import 'log.dart';

// final _log = Logger('Room');
class UnknownComponentError implements Exception {
  final String componentId;
  UnknownComponentError(this.componentId);
  @override
  String toString() {
    return "UnknownComponentError: $componentId";
  }
}

class Room {
  Room(this.id, {required this.farm});

  Farm farm;
  String id;
  String? name;

  String get label => name ?? id;

  rename(String name) {
    farm.publish("florafi/room/$id/\$name", name);
  }

  LogLine? lastLog;

  List<Alert> get alerts =>
      farm.alerts.values.where((a) => a.roomId == id).toList();

  List<Device> get devices =>
      farm.devices.values.where((d) => d.room == this).toList();

  Stream<FarmEvent> get events =>
      farm.events.where((event) => event.room == this);

  List<Component> get components {
    List<Component> list = [
      if (daytime != null) daytime!,
      if (ebbflow != null) ebbflow!,
      if (ebbflowFlood != null) ebbflowFlood!,
      if (ebbflowDrain != null) ebbflowDrain!,
      if (lighting != null) lighting!,
      if (intervalIrrigation != null) intervalIrrigation!,
      if (exaust != null) exaust!,
      if (dehumidifier != null) dehumidifier!,
      if (humidifier != null) humidifier!,
      if (thermometer != null) thermometer!,
      if (hygrometer != null) hygrometer!,
      if (lightSensor != null) lightSensor!,
    ];
    // if (daytime != null) list.add(daytime!);
    return list;
  }

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
  Phmeter? phmeter;

  bool? hasComponent(String componentId) {
    switch (componentId) {
      case "daytime":
        return daytime != null;
      case "dehumidifier-relay":
        return dehumidifier != null;
      case "ebbflow-drain-relay":
        return ebbflowDrain != null;
      case "ebbflow-flood-relay":
        return ebbflowFlood != null;
      case "ebbflow":
        return ebbflow != null;
      case "exaust-relay":
        return exaust != null;
      case "humidifier-relay":
        return humidifier != null;
      case "humidity":
        return hygrometer != null;
      case "interval-irrigation":
        return intervalIrrigation != null;
      case "light":
        return lightSensor != null;
      case "light-relay":
        return lighting != null;
      case "temperature":
        return thermometer != null;
      case "ph-meter":
        return phmeter != null;
      default:
        return null;
    }
  }

  Component getComponent(String componentId) {
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
      case "ph-meter":
        return phmeter ??= Phmeter(room: this);
      default:
        throw UnknownComponentError(componentId);
    }
  }

  Component? removeComponent(String componentId) {
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
      case "ph-meter":
        component = phmeter;
        phmeter = null;
        break;
      default:
        throw UnknownComponentError(componentId);
    }

    return component;
  }

  // daytime
  DateTime get currentTime => farm.clock.now().toUtc();

  bool get hasPhotoperiodConfig =>
      daytime?.startHour != null &&
      daytime?.startDelay != null &&
      daytime?.duration != null;

  bool? get isDaytime {
    // missing daytime configuration
    if (!hasPhotoperiodConfig) return null;

    final startHour = daytime!.startHour!;
    final startdelay = daytime!.startDelay!;
    final durationSeconds = daytime!.duration! * 60;

    // calculate
    final startSecond = Duration.secondsPerHour * startHour + startdelay;

    int endSecond = startSecond + durationSeconds;
    if (endSecond > Duration.secondsPerDay) {
      endSecond -= Duration.secondsPerDay;
    }

    final now = currentTime;
    final currentSecond = now.difference(now.startOfDay()).inSeconds;

    return endSecond >= startSecond
        ? currentSecond >= startSecond && currentSecond < endSecond
        : currentSecond >= startSecond || currentSecond < endSecond;
  }
}
