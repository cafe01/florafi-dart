import 'package:florafi/src/component/room_components.g.dart';

import 'component/extension/datetime.ext.dart';
import 'alert.dart';
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

class Room with RoomComponents {
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
