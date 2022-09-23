class RoomRecord {
  RoomRecord({required this.id, required this.farmId, required this.name});

  final int id;
  final int farmId;
  final String name;

  factory RoomRecord.fromJson(Map<String, dynamic> json) {
    return RoomRecord(
      id: json["id"] as int,
      farmId: json["farmId"] as int,
      name: json["name"] as String,
    );
  }
}
