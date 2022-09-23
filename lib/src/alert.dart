enum AlertType { info, warning, error }

class Alert {
  Alert(
      {required this.id,
      required this.type,
      required this.timestamp,
      required this.roomId});

  final String id;
  final AlertType type;
  int timestamp;
  final String roomId;

  bool get isActive {
    return timestamp > 0;
  }

  bool get isInfo => type == AlertType.info;
  bool get isWarning => type == AlertType.warning;
  bool get isError => type == AlertType.error;
}
