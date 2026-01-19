import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config.dart';

class ApiService {
  static String get baseUrl {
    return 'http://${AppConfig.serverIP}:${AppConfig.serverPort}/api';
  }

  static String? _token;
  static User? _currentUser;

  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<void> _clearToken() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['access_token']);
        _currentUser = User.fromJson(data['user']);
        return AuthResult(success: true, user: _currentUser);
      } else {
        return AuthResult(
          success: false,
          error: data['detail'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Connection error: $e');
    }
  }

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['access_token']);
        _currentUser = User.fromJson(data['user']);
        return AuthResult(success: true, user: _currentUser);
      } else {
        return AuthResult(
          success: false,
          error: data['detail'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Connection error: $e');
    }
  }

  static Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(jsonDecode(response.body));
        return _currentUser;
      } else if (response.statusCode == 401) {
        await _clearToken();
        return null;
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    return null;
  }

  static Future<void> logout() async {
    await _clearToken();
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult({required this.success, this.user, this.error});
}
