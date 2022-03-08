import 'dart:convert';
import 'package:http/http.dart' as http;

class AccessDeniedError implements Exception {
  final int code;
  final String? reason;
  AccessDeniedError(this.code, this.reason);
}

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

class FloraCloud {
  final apiHost = "api.florafi.net";
  String? accessToken;
  String? refreshToken;

  // low-level api request methods
  Future<http.Response> request(http.Request request,
      {authenticated = true}) async {
    // authenticated request
    if (authenticated) {
      request.headers["Authorization"] = "Bearer $accessToken";
    }

    // send request
    var client = http.Client();
    late http.Response res;
    try {
      res = await http.Response.fromStream(await client.send(request));
    } finally {
      client.close();
    }

    // access denied
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw AccessDeniedError(res.statusCode, res.reasonPhrase);
    }

    return res;
  }

  Future<http.Response> get(String path,
      {Map<String, dynamic>? query,
      authenticated = true,
      Map<String, String>? headers}) async {
    // request
    final request = http.Request("GET", Uri.https(apiHost, path, query));
    if (headers != null) request.headers.addAll(headers);
    return this.request(request, authenticated: authenticated);
  }

  Future<http.Response> post(String path,
      {authenticated = true,
      Map<String, dynamic>? json,
      Map<String, String>? headers}) async {
    // build request
    final request = http.Request("POST", Uri.https(apiHost, path));
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
    throw UnimplementedError();
  }

  Future<bool> signIn(String email, String password, {remember = false}) async {
    final credential = {
      "email": email,
      "password": password,
      "remember": remember
    };

    late http.Response res;
    try {
      res = await post("auth/sign-in", json: credential, authenticated: false);
    } on AccessDeniedError {
      return false;
    }

    // store tokens
    final data = jsonDecode(res.body);
    accessToken = data["accessToken"] as String;
    refreshToken = data["refreshToken"] as String?;

    return true;
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

  // high-level farm request

}
