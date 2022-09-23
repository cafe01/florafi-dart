class FarmRecord {
  FarmRecord({required this.id, required this.ownerId, required this.name});

  final int id;
  final int ownerId;
  final String name;

  factory FarmRecord.fromJson(Map<String, dynamic> json) {
    return FarmRecord(
      id: json["id"] as int,
      ownerId: json["ownerId"] as int,
      name: json["name"] as String,
    );
  }
}
