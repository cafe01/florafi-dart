class Notification {
  Notification({required this.message, required this.roomId}) {
    time = DateTime.now();
  }

  late final DateTime time;
  final String message;
  final String roomId;
}
