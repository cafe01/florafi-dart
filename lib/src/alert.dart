import 'package:equatable/equatable.dart';

import 'component.dart';
import 'room.dart';

enum AlertType { info, warning, error }

class Alert extends Equatable {
  const Alert({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.room,
    required this.component,
  });

  static AlertType? resolveType(String type) {
    switch (type) {
      case "info":
        return AlertType.info;
      case "warning":
        return AlertType.warning;
      case "error":
        return AlertType.error;
      default:
        return null;
    }
  }

  final String id;
  final AlertType type;
  final int timestamp;
  final Room room;
  final Component component;

  bool get isActive {
    return timestamp > 0;
  }

  bool get isInfo => type == AlertType.info;
  bool get isWarning => type == AlertType.warning;
  bool get isError => type == AlertType.error;

  @override
  List<Object?> get props => [id, type, timestamp, room, component];
}
