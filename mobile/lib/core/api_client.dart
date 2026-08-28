import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../data/mock_backend.dart';
import 'auth_store.dart';

/// Every failed call surfaces as one of these, so screens can render a single
/// error state instead of guessing at exception types.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => message;
}

/// Thin REST wrapper: attaches the JWT, decodes JSON, normalises errors.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const Duration _timeout = Duration(seconds: 20);

  final http.Client _client = http.Client();

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    // Demo mode: serve everything from memory, no server required.
    if (ApiConfig.useMockData) {
      try {
        return await MockBackend.instance.handle(method, path, body, query);
      } on ApiException catch (error) {
        if (error.isUnauthorized && AuthStore.instance.isLoggedIn) {
          AuthStore.instance.logout();
        }
        rethrow;
      }
    }

    var uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query != null) {
      final params = <String, String>{};
      query.forEach((key, value) {
        if (value != null) params[key] = '$value';
      });
      if (params.isNotEmpty) uri = uri.replace(queryParameters: params);
    }

    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';

    final token = AuthStore.instance.token;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(0, 'The request timed out. Is the backend awake?');
    } catch (_) {
      throw ApiException(
        0,
        'Cannot reach the FleetX backend at ${ApiConfig.baseUrl}.\n'
        'Start it with "mvn spring-boot:run" and try again.',
      );
    }

    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    final status = response.statusCode;
    final raw = response.body;

    if (status >= 200 && status < 300) {
      if (raw.isEmpty) return null;
      return jsonDecode(raw);
    }

    // A 401 on an authenticated call means the token expired - drop it so the
    // app returns to the login screen instead of looping on failures.
    if (status == 401 && AuthStore.instance.isLoggedIn) {
      AuthStore.instance.logout();
    }

    throw ApiException(status, _messageFrom(raw, status));
  }

  String _messageFrom(String raw, int status) {
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['message'] is String) {
          return decoded['message'] as String;
        }
      } catch (_) {
        // Not JSON - fall through to the generic message.
      }
    }
    switch (status) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to do that.';
      case 404:
        return 'Not found.';
      default:
        return 'Something went wrong (HTTP $status).';
    }
  }
}
