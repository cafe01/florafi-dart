import 'package:florafi/src/cloud/farm_record.dart';

class FarmJoinTokenRecord {
  FarmJoinTokenRecord({
    required this.id,
    required this.farmId,
    this.userId,
    required this.readOnly,
    required this.createdAt,
    this.jwt,
    this.farm,
  });

  final int id;
  final int farmId;
  final int? userId;
  final String? jwt;
  final bool readOnly;
  final DateTime createdAt;
  final FarmRecord? farm;

  factory FarmJoinTokenRecord.fromJson(Map<String, dynamic> json) {
    FarmRecord? farm;
    if (json.containsKey("farm")) {
      farm = FarmRecord.fromJson(json["farm"]);
    }

    // print(json);
    return FarmJoinTokenRecord(
        id: json["id"] as int,
        farmId: json["farmId"] as int,
        userId: json["userId"] as int?,
        jwt: json["jwt"] as String?,
        readOnly: json["readOnly"] as bool,
        createdAt: DateTime.parse(json["createdAt"]),
        farm: farm);
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "farmId": farmId,
      "userId": userId,
      "jwt": jwt,
      "readOnly": readOnly,
      "createdAt": createdAt.toIso8601String(),
    };
  }
}
