import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/user.dart';
import '../../features/profile/models/calorie_info.dart';
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

  static Future<UpdateResult> updateProfile({
    double? currentWeight,
    double? goalWeight,
    String? gender,
    String? profileImagePath,
    double? height,
    int? age,
    String? activityLevel,
    String? goalType,
    int? preferredMealsPerDay,
    int? maxCookTime,
    bool clearMaxCookTime = false,
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
      if (preferredMealsPerDay != null) body['preferred_meals_per_day'] = preferredMealsPerDay;
      if (clearMaxCookTime) {
        body['max_cook_time'] = null;
      } else if (maxCookTime != null) {
        body['max_cook_time'] = maxCookTime;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
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

  static void clearUserCache() {
    _currentUser = null;
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get calorie information based on user profile
  static Future<CalorieResult> getCalorieInfo() async {
    final token = await getToken();
    if (token == null) {
      return CalorieResult(success: false, error: 'Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nutrition/calories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final calorieInfo = CalorieInfo.fromJson(jsonDecode(response.body));
        return CalorieResult(success: true, calorieInfo: calorieInfo);
      } else {
        final data = jsonDecode(response.body);
        return CalorieResult(
          success: false,
          error: data['detail'] ?? 'Failed to get calorie info',
        );
      }
    } catch (e) {
      return CalorieResult(success: false, error: 'Connection error: $e');
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

class CalorieResult {
  final bool success;
  final CalorieInfo? calorieInfo;
  final String? error;

  CalorieResult({required this.success, this.calorieInfo, this.error});
}
