import 'dart:async';

import 'component.dart';
import 'component/components.g.dart';
import 'component/extension/datetime.ext.dart';
import 'alert.dart';
import 'device.dart';
import 'events.dart';
import 'farm.dart';
import 'log.dart';

part 'component/room_components.g.dart';

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
    farm.publish("florafi/room/$id/\$name", name, retain: true);
  }

  LogLine? lastLog;

  List<Alert> get alerts =>
      farm.alerts.values.where((a) => a.roomId == id).toList();

  List<Device> get devices =>
      farm.devices.values.where((d) => d.room == this).toList();

  Stream<FarmEvent> get events =>
      farm.events.where((event) => event.room == this);

  // components
  List<Component> get components {
    List<Component> list = [];
    for (final device in devices) {
      list.addAll(device.components);
    }

    return list;
  }

  Component? getComponent(String id) {
    for (final device in devices) {
      for (final component in device.components) {
        if (component.mqttId == id || component.id == id) return component;
      }
    }
    return null;
  }

  T? getComponentByType<T>() {
    for (final device in devices) {
      for (final component in device.components) {
        if (component is T) return component as T;
      }
    }
    return null;
  }

  bool hasComponent(String id) {
    return getComponent(id) != null;
  }

  // config
  bool consumeConfigMessage(String property, String value) {
    switch (property) {
      case "daytime/start":
        final seconds = int.tryParse(value);
        _dayStart = seconds == null ? null : Duration(seconds: seconds);
        return true;
      case "daytime/duration":
        final seconds = int.tryParse(value);
        _dayDuration = seconds == null ? null : Duration(seconds: seconds);
        return true;
      default:
        return false;
    }
  }

  void _setConfig(String property, String? value) {
    farm.publish("florafi/room/$id/config/$property", value ?? "",
        retain: true);
  }

  // daytime config
  bool get hasPhotoperiodConfig => _dayStart != null && _dayDuration != null;

  Duration? _dayStart;
  Duration? get dayStart => _dayStart;
  set dayStart(Duration? offsetFromMidnight) =>
      _setConfig("daytime/start", offsetFromMidnight?.inSeconds.toString());

  Duration? _dayDuration;
  Duration? get dayDuration => _dayDuration;
  set dayDuration(Duration? duration) =>
      _setConfig("daytime/duration", duration?.inSeconds.toString());

  Duration? get nightDuration => dayDuration == null
      ? null
      : Duration(seconds: Duration.secondsPerDay - dayDuration!.inSeconds);

  // daytime
  // DateTime get currentTime => farm.getClock().now().toUtc();

  bool? get isDaytime {
    // missing daytime configuration
    if (!hasPhotoperiodConfig) return null;

    // calculate
    final startSecond = _dayStart!.inSeconds;
    int endSecond = startSecond + _dayDuration!.inSeconds;

    // day overflow
    if (endSecond > Duration.secondsPerDay) {
      endSecond -= Duration.secondsPerDay;
    }

    final now = farm.getClock().now().toUtc();
    final currentSecond = now.difference(now.startOfDay()).inSeconds;

    return endSecond >= startSecond
        ? currentSecond >= startSecond && currentSecond < endSecond
        : currentSecond >= startSecond || currentSecond < endSecond;
  }

  StreamController<bool?>? _daytimeChangeController;
  Stream<bool?>? get onDaytimeChange => _daytimeChangeController?.stream;

  Timer? _daytimeChangeTimer;

  void enableDaytimeMonitor() {
    if (_daytimeChangeController != null) return;

    _daytimeChangeController = StreamController<bool?>.broadcast();
    bool? lastIsDaytime = isDaytime;
    _daytimeChangeTimer = Timer(const Duration(seconds: 1), () {
      final isDaytime = this.isDaytime;
      if (isDaytime != lastIsDaytime) {
        lastIsDaytime = isDaytime;
        _daytimeChangeController?.add(isDaytime);
      }
    });
  }

  void disableDaytimeMonitor() {
    _daytimeChangeTimer?.cancel();
    _daytimeChangeTimer = null;
    _daytimeChangeController?.close();
    _daytimeChangeController = null;
  }
}
