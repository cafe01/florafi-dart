import 'dart:convert';
import 'dart:io';
import 'package:florafi/src/cloud/farm_join_token_record.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'package:logging/logging.dart';

import '../florafi.dart';

import 'cloud/user_record.dart';
import 'cloud/room_record.dart';

final _log = Logger("FloraCloud");

class UnauthorizedError implements Exception {
  final int code;
  final String? reason;
  UnauthorizedError(this.code, this.reason);
}

class FloraCloudError implements Exception {
  final int code;
  final String? reason;
  FloraCloudError(this.code, this.reason);
  @override
  String toString() {
    return "FloraCloudError: $code (${reason ?? ''})";
  }
}

class UnauthenticatedError implements Exception {}

class ForbiddenError implements Exception {}

class FarmTicket {
  final int farmId;
  final String farmName;
  final String host;
  final int port;
  final int tlsPort;
  final int wssPort;
  final String username;
  final String password;
  final bool isReadOnly;
  final bool isAdmin;
  final String? joinSecret;

  FarmTicket(
    this.farmId,
    this.farmName,
    this.host,
    this.port,
    this.tlsPort,
    this.wssPort,
    this.username,
    this.password,
    this.isReadOnly,
    this.isAdmin,
    this.joinSecret,
  );

  factory FarmTicket.fromJson(Map<String, dynamic> data) {
    return FarmTicket(
      data['farmId'] as int? ?? 0,
      data['farmName'] as String? ?? "",
      data['host'] as String? ?? "",
      data['port'] as int? ?? 0,
      data['tlsPort'] as int? ?? 0,
      data['wssPort'] as int? ?? 0,
      data['username'] as String? ?? "",
      data['password'] as String? ?? "",
      data['isReadOnly'] as bool? ?? false,
      data['isAdmin'] as bool? ?? false,
      data['joinSecret'] as String?,
    );
  }
}

class AccessToken {
  AccessToken(
    this.token, {
    this.invalidthreshold = const Duration(seconds: 30),
  }) {
    final splitToken = token.split(".");
    if (splitToken.length != 3) {
      throw FormatException('Invalid token');
    }
    try {
      // Payload is always the index 1
      final payloadBase64 = splitToken[1];
      // Base64 should be multiple of 4. Normalize the payload before decode it
      final normalizedPayload = base64.normalize(payloadBase64);
      // Decode payload, the result is a String
      final payloadString = utf8.decode(base64.decode(normalizedPayload));
      // Parse the String to a Map<String, dynamic>
      final decodedPayload = jsonDecode(payloadString);

      // expiration date
      final expTimestamp = decodedPayload["exp"] as int;
      expirationDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
    } catch (error) {
      throw FormatException('Invalid token payload ($error)');
    }
  }

  String token;
  late DateTime expirationDate;
  Duration invalidthreshold;

  Duration get remainingTime => expirationDate.difference(DateTime.now());
  bool get isExpired => remainingTime <= invalidthreshold;
}

class QueryFilter {
  QueryFilter({this.where, this.limit, this.skip, this.order, this.include});

  final Map<String, dynamic>? where;
  final int? limit;
  final int? skip;
  final List<String>? order;
  final List<String>? include;

  String toJson() {
    Map<String, dynamic> json = {
      "where": where,
      "include": include,
      "order": order,
      "limit": limit,
      "skip": skip,
    };

    json.removeWhere((key, value) => value == null);
    return jsonEncode(json);
  }

  String toString() {
    return "QueryFilter(${toJson()})";
  }
}

class FloraCloud {
  FloraCloud({String? apiUrl}) {
    apiUrl ??= "https://api.florafi.net";
    baseUrl = Uri.parse(apiUrl);
  }

  late final Uri baseUrl;
  final apiHost = "api.florafi.net";

  AccessToken? accessToken;
  String? refreshToken;

  bool get hasCredential => (accessToken ?? refreshToken) != null;

  Uri _buildUrl(String path, {Map<String, dynamic>? queryParameters}) {
    final pathSegments = baseUrl.pathSegments.toList();
    pathSegments.addAll(path.split("/"));
    return Uri(
        scheme: baseUrl.scheme,
        host: baseUrl.host,
        port: baseUrl.port,
        pathSegments: pathSegments,
        queryParameters: queryParameters);
  }

  Future<void> _refreshAccessToken() async {
    if (refreshToken == null) {
      _log.warning("missing refresh token");
      return;
    }

    final res = await post("auth/refresh-access-token",
        json: {"refreshToken": refreshToken}, authenticated: false);

    // success
    if (res.statusCode == HttpStatus.ok) {
      _log.fine("Refreshed access token");
      final data = jsonDecode(res.body);
      final token = data["accessToken"] as String?;
      if (token == null) throw Exception("API didn't return access token");
      accessToken = AccessToken(token);
      return;
    }

    // failed
    refreshToken = null;
  }

  // low-level api request methods
  Future<http.Response> request(
    http.Request request, {
    authenticated = true,
    timeout = const Duration(seconds: 10),
  }) async {
    // authenticated request
    if (authenticated) {
      if (accessToken == null || accessToken!.isExpired) {
        if (refreshToken == null) {
          _log.warning(
              "Can't do authenticated request: missing or expired accessToken + missing refreshToken.");
          throw UnauthenticatedError();
        }

        // try again
        await _refreshAccessToken();
        return this
            .request(request, authenticated: authenticated, timeout: timeout);
      }

      request.headers["Authorization"] = "Bearer ${accessToken!.token}";
    }

    // send request
    _log.fine(request.toString());
    _log.finer(request.headers.toString());

    if (request.method != "GET") _log.finest(request.body);
    var client = http.Client();
    late http.Response res;

    try {
      final streamRes = await client.send(request).timeout(timeout);
      res = await http.Response.fromStream(streamRes);
      _log.finer("Response: (${res.contentLength} bytes)");
      _log.finer(res.headers);
      _log.finer(utf8.decode(res.bodyBytes));
    } finally {
      client.close();
    }

    // unauthorized
    // if (res.statusCode == HttpStatus.unauthorized) {
    //   _accessToken_old == null;
    //   if (refreshToken == null) {
    //     throw UnauthorizedError(res.statusCode, res.reasonPhrase);
    //   }

    //   await _refreshAccessToken();
    //   return this.request(request, authenticated: authenticated);
    // }

    // // forbidden
    // if (res.statusCode == HttpStatus.forbidden) {
    //   throw ForbiddenError();
    // }

    // other error
    if (res.statusCode >= 400) {
      throw FloraCloudError(res.statusCode, res.body);
    }

    return res;
  }

  Future<http.Response> get(String path,
      {authenticated = true,
      Map<String, dynamic>? queryParameters,
      QueryFilter? filter,
      Map<String, String>? headers}) {
    if (filter != null) {
      queryParameters ??= {};
      queryParameters["filter"] = filter.toJson();
    }
    // request
    final url = _buildUrl(path, queryParameters: queryParameters);
    final request = http.Request("GET", url);
    if (headers != null) request.headers.addAll(headers);
    return this.request(request, authenticated: authenticated);
  }

  Future<http.Response> post(String path,
      {authenticated = true,
      Map<String, dynamic>? json,
      Map<String, dynamic>? queryParameters,
      Map<String, String>? headers}) {
    // build request

    final url = _buildUrl(path, queryParameters: queryParameters);
    final request = http.Request("POST", url);
    if (headers != null) request.headers.addAll(headers);

    // json body
    if (json != null) {
      request.encoding = Utf8Codec();
      request.headers["content-type"] = "application/json";
      request.body = jsonEncode(json);
    }

    // request
    return this.request(request, authenticated: authenticated);
  }

  Future<http.Response> patch(String path,
      {authenticated = true,
      Map<String, dynamic>? json,
      Map<String, dynamic>? queryParameters,
      Map<String, String>? headers}) {
    // build request

    final url = _buildUrl(path, queryParameters: queryParameters);
    final request = http.Request("PATCH", url);
    if (headers != null) request.headers.addAll(headers);

    // json body
    if (json != null) {
      request.encoding = Utf8Codec();
      request.headers["content-type"] = "application/json";
      request.body = jsonEncode(json);
    }

    // request
    return this.request(request, authenticated: authenticated);
  }

  Future<http.Response> put(String path) {
    throw UnimplementedError();
  }

  Future<http.Response> delete(String path, {authenticated = true}) {
    // request
    final url = _buildUrl(path);
    final request = http.Request("DELETE", url);
    return this.request(request, authenticated: authenticated);
  }

  // unauthenticated requests
  Future<bool> signUp(
      {required String name,
      required String email,
      required String password,
      remember = false}) async {
    final json = {
      "name": name,
      "email": email,
      "password": password,
      "remember": remember
    };
    final res = await post("/users/sign-up", json: json, authenticated: false);
    final decodedResponse = jsonDecode(res.body);

    accessToken = AccessToken(decodedResponse["accessToken"] as String);
    refreshToken = decodedResponse["refreshToken"] as String?;
    return true;
  }

  Future<void> signIn(String email, String password, {remember = false}) async {
    final credential = {
      "email": email,
      "password": password,
      "remember": remember
    };

    accessToken = null;
    refreshToken = null;

    final res =
        await post("auth/sign-in", json: credential, authenticated: false);
    // store tokens
    final data = jsonDecode(res.body);
    accessToken = AccessToken(data["accessToken"] as String);
    refreshToken = data["refreshToken"] as String?;
  }

  void signOut() {
    accessToken = null;
    refreshToken = null;
  }

  Future<List<FarmTicket>> checkIn() async {
    final res = await get("users/check-in");
    final body = utf8.decode(res.bodyBytes);
    final data = jsonDecode(body);

    List<FarmTicket> tickets = [];
    for (final ticketData in data) {
      tickets.add(FarmTicket.fromJson(ticketData));
    }

    return tickets;
  }

  // high-level farm request
  Future<String> fluxQuery({farmId = 0, required String raw}) async {
    final json = {"raw": raw.replaceAll("\n", " ")};
    final headers = {
      "Accept-Encoding": "gzip",
      "Accept": "application/csv",
    };
    final res =
        await post("farms/$farmId/flux_query", json: json, headers: headers);
    return res.body;
  }

  Future<List<RoomRecord>> getFarmRooms({required int farmId}) async {
    final res = await get("farms/$farmId/rooms");
    final body = utf8.decode(res.bodyBytes);
    final jsonList = jsonDecode(body);
    assert(jsonList is List);

    List<RoomRecord> rooms = [];

    for (final item in jsonList) {
      rooms.add(RoomRecord.fromJson(item));
    }

    return rooms;
  }

  Future<RoomRecord> createFarmRoom(
      {required int farmId, required String name}) async {
    final res = await post("farms/$farmId/rooms", json: {"name": name});
    final json = jsonDecode(res.body);
    return RoomRecord.fromJson(json);
  }

  Future<void> renameFarm({required int farmId, required String name}) async {
    await patch("farms/$farmId", json: {"name": name});
  }

  Future<void> renameFarmRoom(
      {required int farmId, required int roomId, required String name}) async {
    await patch("farms/$farmId/rooms/$roomId", json: {"name": name});
  }

  Future<void> setDeviceRoom(Device device, int roomId) async {
    await patch("/farms/${device.farm.id}/devices/${device.hardwareId}",
        json: {"roomId": roomId});
  }

  Future<FarmJoinTokenRecord> createFarmJoinToken(
      {required int farmId, int? userId, readOnly = false}) async {
    Map<String, dynamic> params = {"readOnly": readOnly};
    if (userId != null) params["userId"] = userId.toInt();

    final res = await post("farms/$farmId/join-token", json: params);

    final json = jsonDecode(res.body);
    return FarmJoinTokenRecord.fromJson(json);
  }

  Future<FarmJoinTokenRecord> resolveFarmJoinToken(
      {required String jwtToken}) async {
    final res =
        await post("farms/resolve-join-token", json: {"token": jwtToken});
    final json = jsonDecode(res.body);
    return FarmJoinTokenRecord.fromJson(json);
  }

  Future<FarmTicket> acceptFarmJoinToken({required String jwtToken}) async {
    final res =
        await post("farms/accept-join-token", json: {"token": jwtToken});
    final json = jsonDecode(res.body);
    return FarmTicket.fromJson(json);
  }

  /// User endpoints
  Future<void> saveFcmToken(
      {required String token, required String userAgent}) async {
    final json = {"token": token, "userAgent": userAgent};
    await post("/users/fcm-token", json: json);
  }

  Future<List<UserRecord>> findUsers(
      {required String query, limit = 20, page = 1}) async {
    final res = await get("users", queryParameters: {
      "query": query,
      "limit": limit.toString(),
      "page": page.toString(),
    });

    final jsonList = jsonDecode(res.body);

    List<UserRecord> users = [];

    for (final item in jsonList) {
      users.add(UserRecord.fromJson(item));
    }

    return users;
  }
}
