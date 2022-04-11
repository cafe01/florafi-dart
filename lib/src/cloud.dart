import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

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

  FarmTicket(this.farmId, this.farmName, this.host, this.port, this.tlsPort,
      this.wssPort, this.username, this.password);

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

class FloraCloud {
  FloraCloud({String apiUrl = "https://api.florafi.net"}) {
    baseUrl = Uri.parse(apiUrl);
  }

  late final Uri baseUrl;
  final apiHost = "api.florafi.net";

  AccessToken? accessToken;

  String? _accessToken_old;
  String? refreshToken;

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
        return this.request(request, authenticated: authenticated);
      }

      request.headers["Authorization"] = "Bearer ${accessToken!.token}";
    }

    // send request
    _log.fine(request.toString());
    _log.finer(request.headers.toString());
    _log.finest(request.body);
    var client = http.Client();
    late http.Response res;
    try {
      res = await http.Response.fromStream(await client.send(request));
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
      {Map<String, dynamic>? queryParameters,
      authenticated = true,
      Map<String, String>? headers}) {
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
      request.body = jsonEncode(json);
      request.headers["content-type"] = "application/json";
    }

    // request
    return this.request(request, authenticated: authenticated);
  }

  Future<http.Response> put(String path) {
    throw UnimplementedError();
  }

  Future<http.Response> delete(String path) {
    throw UnimplementedError();
  }

  // unauthenticated requests
  Future<bool> signUp(
      {required String name,
      required String email,
      required String password}) async {
    final json = {"name": name, "email": email, "password": password};
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

  Future<List<FarmTicket>> checkIn() async {
    final res = await get("users/check-in");
    final data = jsonDecode(res.body);

    List<FarmTicket> tickets = [];
    for (final ticketData in data) {
      tickets.add(FarmTicket.fromJson(ticketData));
    }

    return tickets;
  }

  // high-level user request
  Future<void> saveFcmToken(
      {required String token, required String userAgent}) async {
    final json = {"token": token, "userAgent": userAgent};
    await post("/users/fcm-token", json: json);
  }

  // high-level farm request
  Future<String> fluxQuery({farmId = 0, required String raw}) async {
    final json = {"raw": raw};
    final headers = {
      "Accept-Encoding": "gzip",
      "Accept": "application/csv",
    };
    final res =
        await post("farms/$farmId/flux_query", json: json, headers: headers);
    return res.body;
  }
}
