import 'room.dart';

enum LogLevel { debug, info, warning, error }

class LogLine {
  LogLine(
      {required this.room,
      required this.level,
      required this.message,
      required this.time,
      required this.deviceId,
      this.componentId});

  factory LogLine.fromJson(
      Room room, LogLevel level, Map<String, dynamic> json) {
    final time = DateTime.fromMillisecondsSinceEpoch(
        (json['time'] as int) * 1000,
        isUtc: true);
    final message = json['message'] as String;
    final deviceId = json['device'] as String;
    final componentId = json['component'] as String?;
    if (componentId != null && room.hasComponent(componentId) is! bool) {
      throw UnknownComponentError(componentId);
    }

    return LogLine(
        room: room,
        level: level,
        time: time,
        message: message,
        deviceId: deviceId,
        componentId: componentId);
  }

  final Room room;
  final LogLevel level;
  final DateTime time;
  final String message;
  final String deviceId;
  final String? componentId;
}
