import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/user.dart';

class AuthService {
  final String baseUrl = AppConstants.baseUrl;

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<({String token})> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/login');
    final body = {'email': email, 'password': password};
    debugPrint('[AUTH] → POST $uri');
    final response = await http.post(uri, headers: _headers(), body: jsonEncode(body));
    debugPrint('[AUTH] ← ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (token: data['access_token'] as String);
    }
    final error = _parseError(response);
    throw AuthException(error);
  }

  Future<User> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/register');
    final body = {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'password': password,
    };
    debugPrint('[AUTH] → POST $uri');
    final response = await http.post(uri, headers: _headers(), body: jsonEncode(body));
    debugPrint('[AUTH] ← ${response.statusCode}');

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    }
    final error = _parseError(response);
    throw AuthException(error);
  }

  Future<User> getMe(String token) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/me');
    debugPrint('[AUTH] → GET $uri');
    final response = await http.get(uri, headers: _headers(token: token));
    debugPrint('[AUTH] ← ${response.statusCode}');

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw AuthException('Session expired');
  }

  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        if (data['detail'] is String) return data['detail'];
        if (data['detail'] is List) {
          final details = data['detail'] as List;
          if (details.isNotEmpty) {
            return details.map((d) => d['msg'] ?? d.toString()).join(', ');
          }
        }
      }
    } catch (_) {}
    return 'Request failed (${response.statusCode})';
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
