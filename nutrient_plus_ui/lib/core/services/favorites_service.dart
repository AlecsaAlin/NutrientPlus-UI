import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class FavoritesService {
  static String get _baseUrl => AppConfig.baseUrl;

  static Future<bool> addFavorite({required int recipeId}) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/meals/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'recipe_id': recipeId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeFavorite({required int recipeId}) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/meals/favorites/$recipeId'),
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

  static Future<bool> isFavorite({required int recipeId}) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/meals/favorites/check/$recipeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_favorite'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<FavoritesResult> getFavorites() async {
    final token = await AuthService.getToken();
    if (token == null) {
      return FavoritesResult(success: false, error: 'Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/meals/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final favorites = data.map((item) => FavoriteRecipe.fromJson(item)).toList();
        return FavoritesResult(success: true, favorites: favorites);
      } else {
        return FavoritesResult(success: false, error: 'Failed to load favorites');
      }
    } catch (e) {
      return FavoritesResult(success: false, error: 'Connection error: $e');
    }
  }
}

class FavoriteRecipe {
  final int id;
  final int recipeId;
  final String recipeName;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final int? totalTimeMinutes;
  final DateTime createdAt;

  FavoriteRecipe({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    this.totalTimeMinutes,
    required this.createdAt,
  });

  factory FavoriteRecipe.fromJson(Map<String, dynamic> json) {
    return FavoriteRecipe(
      id: json['id'],
      recipeId: json['recipe_id'],
      recipeName: json['recipe_name'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      proteinG: (json['protein_g'] ?? 0).toDouble(),
      fatG: (json['fat_g'] ?? 0).toDouble(),
      carbsG: (json['carbs_g'] ?? 0).toDouble(),
      totalTimeMinutes: json['total_time_minutes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class FavoritesResult {
  final bool success;
  final List<FavoriteRecipe>? favorites;
  final String? error;

  FavoritesResult({required this.success, this.favorites, this.error});
}
