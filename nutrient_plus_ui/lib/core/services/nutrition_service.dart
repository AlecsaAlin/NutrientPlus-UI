import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/profile/models/calorie_info.dart';
import '../config.dart';
import 'auth_service.dart';

class NutritionService {
  static String get _baseUrl => AppConfig.baseUrl;

  static Future<CalorieResult> getCalorieInfo() async {
    final token = await AuthService.getToken();
    if (token == null) {
      return CalorieResult(success: false, error: 'Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/nutrition/calories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final calorieInfo = CalorieInfo.fromJson(jsonDecode(response.body));
        return CalorieResult(success: true, calorieInfo: calorieInfo);
      } else if (response.statusCode >= 500) {
        return CalorieResult(success: false, error: 'Server error. Please try again later.');
      } else {
        try {
          final data = jsonDecode(response.body);
          return CalorieResult(
            success: false,
            error: data['detail'] ?? 'Failed to get calorie info',
          );
        } catch (_) {
          return CalorieResult(success: false, error: 'Failed to get calorie info (${response.statusCode})');
        }
      }
    } catch (e) {
      return CalorieResult(success: false, error: 'Unable to connect to server.');
    }
  }
}

class CalorieResult {
  final bool success;
  final CalorieInfo? calorieInfo;
  final String? error;

  CalorieResult({required this.success, this.calorieInfo, this.error});
}
