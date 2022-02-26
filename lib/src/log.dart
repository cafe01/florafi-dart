enum LogLevel { debug, info, warning, error }

class LogLine {
  LogLine(
      {required this.roomId,
      required this.level,
      required this.message,
      required this.time,
      required this.deviceId,
      this.componentId});

  factory LogLine.fromJson(
      String roomId, LogLevel level, Map<String, dynamic> json) {
    final time = DateTime.fromMillisecondsSinceEpoch(
        (json['time'] as int) * 1000,
        isUtc: true);
    final message = json['message'] as String;
    final deviceId = json['device'] as String;
    final componentId = json['component'] as String?;

    return LogLine(
        roomId: roomId,
        level: level,
        time: time,
        message: message,
        deviceId: deviceId,
        componentId: componentId);
  }

  final String roomId;
  final LogLevel level;
  final DateTime time;
  final String message;
  final String deviceId;
  final String? componentId;
}
