import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class RatingsService {
  static String get _baseUrl => AppConfig.baseUrl;

  static Future<RatingsResult> getUserRatings() async {
    final token = await AuthService.getToken();
    if (token == null) {
      return RatingsResult(success: false, error: 'Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/meals/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final ratings = data.map((item) => UserRating.fromJson(item)).toList();
        return RatingsResult(success: true, ratings: ratings);
      } else {
        return RatingsResult(success: false, error: 'Failed to load ratings');
      }
    } catch (e) {
      return RatingsResult(success: false, error: 'Connection error: $e');
    }
  }

  static Future<bool> rateRecipe({required int recipeId, required double rating}) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/meals/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recipe_id': recipeId,
          'rating': rating,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<double?> getRecipeRating({required int recipeId}) async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/meals/ratings/$recipeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rating']?.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteRecipeRating({required int recipeId}) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/meals/ratings/$recipeId'),
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
}

class UserRating {
  final int id;
  final int recipeId;
  final String recipeName;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final int? totalTimeMinutes;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserRating({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    this.totalTimeMinutes,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserRating.fromJson(Map<String, dynamic> json) {
    return UserRating(
      id: json['id'],
      recipeId: json['recipe_id'],
      recipeName: json['recipe_name'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      proteinG: (json['protein_g'] ?? 0).toDouble(),
      fatG: (json['fat_g'] ?? 0).toDouble(),
      carbsG: (json['carbs_g'] ?? 0).toDouble(),
      totalTimeMinutes: json['total_time_minutes'],
      rating: (json['rating'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class RatingsResult {
  final bool success;
  final List<UserRating>? ratings;
  final String? error;

  RatingsResult({required this.success, this.ratings, this.error});
}
