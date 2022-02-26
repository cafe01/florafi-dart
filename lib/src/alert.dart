enum AlertType { info, warning, error }

class Alert {
  Alert(
      {required this.id,
      required this.type,
      required this.timestamp,
      required this.roomId});

  final String id;
  final AlertType type;
  final int timestamp;
  final String roomId;

  bool get isActive {
    return timestamp > 0;
  }
}
