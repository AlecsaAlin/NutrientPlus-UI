import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/user.dart';
import '../config.dart';

class AuthService {
  static String get _baseUrl => AppConfig.baseUrl;

  static String? _token;
  static User? _currentUser;

  static String _extractError(dynamic detail, String fallback) {
    if (detail == null) return fallback;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map) {
        final loc = first['loc'];
        if (loc is List && loc.isNotEmpty) {
          switch (loc.last?.toString()) {
            case 'email':
              return 'Please enter a valid email address';
            case 'password':
              return 'Password is too short or invalid';
            case 'username':
              return 'Username is invalid';
          }
        }
      }
    }
    return fallback;
  }

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

  static void clearUserCache() {
    _currentUser = null;
  }

  static Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['access_token']);
        _currentUser = User.fromJson(data['user']);
        return AuthResult(success: true, user: _currentUser);
      } else if (response.statusCode >= 500) {
        return AuthResult(success: false, error: 'Server error. Please try again later.');
      } else {
        try {
          final data = jsonDecode(response.body);
          return AuthResult(
            success: false,
            error: _extractError(data['detail'], 'Registration failed'),
          );
        } catch (_) {
          return AuthResult(success: false, error: 'Registration failed (${response.statusCode})');
        }
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Unable to connect to server. Please check your internet connection.');
    }
  }

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['access_token']);
        _currentUser = User.fromJson(data['user']);
        return AuthResult(success: true, user: _currentUser);
      } else if (response.statusCode >= 500) {
        return AuthResult(success: false, error: 'Server error. Please try again later.');
      } else {
        try {
          final data = jsonDecode(response.body);
          return AuthResult(
            success: false,
            error: _extractError(data['detail'], 'Login failed'),
          );
        } catch (_) {
          return AuthResult(success: false, error: 'Login failed (${response.statusCode})');
        }
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Unable to connect to server. Please check your internet connection.');
    }
  }

  static Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
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

  static Future<UpdateResult> updateProfile({
    double? currentWeight,
    double? goalWeight,
    String? gender,
    String? profileImagePath,
    double? height,
    int? age,
    String? activityLevel,
    String? goalType,
    int? goalTimeline,
    int? preferredMealsPerDay,
    int? maxCookTime,
    bool clearMaxCookTime = false,
    String? explorationPreference,
  }) async {
    final token = await getToken();
    if (token == null) {
      return UpdateResult(success: false, error: 'Not authenticated');
    }

    try {
      final body = <String, dynamic>{};
      if (currentWeight != null) body['current_weight'] = currentWeight;
      if (goalWeight != null) body['goal_weight'] = goalWeight;
      if (gender != null) body['gender'] = gender;
      if (profileImagePath != null) body['profile_image_path'] = profileImagePath;
      if (height != null) body['height'] = height;
      if (age != null) body['age'] = age;
      if (activityLevel != null) body['activity_level'] = activityLevel;
      if (goalType != null) body['goal_type'] = goalType;
      if (goalTimeline != null) body['goal_timeline'] = goalTimeline;
      if (preferredMealsPerDay != null) body['preferred_meals_per_day'] = preferredMealsPerDay;
      if (clearMaxCookTime) {
        body['max_cook_time'] = null;
      } else if (maxCookTime != null) {
        body['max_cook_time'] = maxCookTime;
      }
      if (explorationPreference != null) body['exploration_preference'] = explorationPreference;

      final response = await http.put(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(jsonDecode(response.body));
        return UpdateResult(success: true, user: _currentUser);
      } else {
        final data = jsonDecode(response.body);
        return UpdateResult(
          success: false,
          error: data['detail'] ?? 'Update failed',
        );
      }
    } catch (e) {
      return UpdateResult(success: false, error: 'Connection error: $e');
    }
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
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

class UpdateResult {
  final bool success;
  final User? user;
  final String? error;

  UpdateResult({required this.success, this.user, this.error});
}
