class UserRecord {
  UserRecord({required this.id, required this.name, this.email});

  final int id;
  final String name;
  final String? email;

  factory UserRecord.fromJson(Map<String, dynamic> json) {
    return UserRecord(
      id: json["id"] as int,
      name: json["name"] as String,
      email: json["email"] as String?,
    );
  }
}
