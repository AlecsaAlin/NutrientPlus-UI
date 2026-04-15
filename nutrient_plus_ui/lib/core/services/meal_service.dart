import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/meal_plan/models/meal_models.dart';
import '../config.dart';
import 'auth_service.dart';

class MealService {
  static String get _baseUrl => AppConfig.baseUrl;

  static Future<MealPlanResult> generateMealPlan({
    int? numMeals,
    int? maxCookTime,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return MealPlanResult(success: false, error: 'Not authenticated');
    }

    try {
      final body = <String, dynamic>{};
      if (numMeals != null) body['num_meals'] = numMeals;
      if (maxCookTime != null) body['max_cook_time'] = maxCookTime;

      final response = await http.post(
        Uri.parse('$_baseUrl/meals/plan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final mealPlan = MealPlanResponse.fromJson(jsonDecode(response.body));
        return MealPlanResult(success: true, mealPlan: mealPlan);
      } else if (response.statusCode >= 500) {
        return MealPlanResult(success: false, error: 'Server error. Please try again later.');
      } else {
        try {
          final data = jsonDecode(response.body);
          return MealPlanResult(
            success: false,
            error: data['detail'] ?? 'Failed to generate meal plan',
          );
        } catch (_) {
          return MealPlanResult(success: false, error: 'Failed to generate meal plan (${response.statusCode})');
        }
      }
    } catch (e) {
      return MealPlanResult(success: false, error: 'Unable to connect to server. Please check your internet connection.');
    }
  }

  static Future<bool> saveMealPlan({
    required String planDate,
    required MealPlanResponse plan,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/meals/save'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'plan_date': planDate,
          'plan': plan.toJson(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<SavedPlansResult> getSavedMealPlans({
    required String startDate,
    required String endDate,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return SavedPlansResult(success: false, error: 'Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/meals/saved?start_date=$startDate&end_date=$endDate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final plans = <String, MealPlanResponse>{};
        for (final item in data) {
          final date = item['plan_date'] as String;
          plans[date] = MealPlanResponse.fromJson(item['plan']);
        }
        return SavedPlansResult(success: true, plans: plans);
      } else {
        final data = jsonDecode(response.body);
        return SavedPlansResult(
          success: false,
          error: data['detail'] ?? 'Failed to load saved plans',
        );
      }
    } catch (e) {
      return SavedPlansResult(success: false, error: 'Connection error: $e');
    }
  }

  static Future<bool> syncMealHistory() async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/meals/sync-history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> rateMeal({required int recipeId}) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/meals/rate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recipe_id': recipeId,
          'saved': true,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<RecipeDetail?> getRecipeById({required int recipeId}) async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/meals/recipe/$recipeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return RecipeDetail.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class MealPlanResult {
  final bool success;
  final MealPlanResponse? mealPlan;
  final String? error;

  MealPlanResult({required this.success, this.mealPlan, this.error});
}

class SavedPlansResult {
  final bool success;
  final Map<String, MealPlanResponse>? plans;
  final String? error;

  SavedPlansResult({required this.success, this.plans, this.error});
}
