import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/user.dart';
import '../../features/profile/models/calorie_info.dart';
import '../../features/meal_plan/models/meal_models.dart';
import '../config.dart';

class ApiService {
  static String get baseUrl {
    return 'http://${AppConfig.serverIP}:${AppConfig.serverPort}/api';
  }

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
          error: _extractError(data['detail'], 'Registration failed'),
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
          error: _extractError(data['detail'], 'Login failed'),
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

  static Future<MealPlanResult> generateMealPlan({
    int? numMeals,
    int? maxCookTime,
  }) async {
    final token = await getToken();
    if (token == null) {
      return MealPlanResult(success: false, error: 'Not authenticated');
    }

    try {
      final body = <String, dynamic>{};
      if (numMeals != null) body['num_meals'] = numMeals;
      if (maxCookTime != null) body['max_cook_time'] = maxCookTime;

      final response = await http.post(
        Uri.parse('$baseUrl/meals/plan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final mealPlan = MealPlanResponse.fromJson(jsonDecode(response.body));
        return MealPlanResult(success: true, mealPlan: mealPlan);
      } else {
        final data = jsonDecode(response.body);
        return MealPlanResult(
          success: false,
          error: data['detail'] ?? 'Failed to generate meal plan',
        );
      }
    } catch (e) {
      return MealPlanResult(success: false, error: 'Connection error: $e');
    }
  }

  /// Save a meal plan for a specific date
  static Future<bool> saveMealPlan({
    required String planDate,
    required MealPlanResponse plan,
  }) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meals/save'),
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

  /// Load saved meal plans for a date range
  static Future<SavedPlansResult> getSavedMealPlans({
    required String startDate,
    required String endDate,
  }) async {
    final token = await getToken();
    if (token == null) {
      return SavedPlansResult(success: false, error: 'Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/meals/saved?start_date=$startDate&end_date=$endDate'),
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

  /// Sync user's meal history from past saved plans
  /// This should be called on app start to update the ML model's training data
  static Future<bool> syncMealHistory() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meals/sync-history'),
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

  /// Save/rate a recipe to meal history
  static Future<bool> rateMeal({required int recipeId}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meals/rate'),
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

  /// Add a recipe to favorites
  static Future<bool> addFavorite({required int recipeId}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meals/favorites'),
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

  /// Remove a recipe from favorites
  static Future<bool> removeFavorite({required int recipeId}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/meals/favorites/$recipeId'),
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

  /// Check if a recipe is in favorites
  static Future<bool> isFavorite({required int recipeId}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/meals/favorites/check/$recipeId'),
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

  /// Get all favorite recipes
  static Future<FavoritesResult> getFavorites() async {
    final token = await getToken();
    if (token == null) {
      return FavoritesResult(success: false, error: 'Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/meals/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final favorites = data
            .map((item) => FavoriteRecipe.fromJson(item))
            .toList();
        return FavoritesResult(success: true, favorites: favorites);
      } else {
        return FavoritesResult(success: false, error: 'Failed to load favorites');
      }
    } catch (e) {
      return FavoritesResult(success: false, error: 'Connection error: $e');
    }
  }

  /// Get all user's ratings with recipe details
  static Future<RatingsResult> getUserRatings() async {
    final token = await getToken();
    if (token == null) {
      return RatingsResult(success: false, error: 'Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/meals/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final ratings = data
            .map((item) => UserRating.fromJson(item))
            .toList();
        return RatingsResult(success: true, ratings: ratings);
      } else {
        return RatingsResult(success: false, error: 'Failed to load ratings');
      }
    } catch (e) {
      return RatingsResult(success: false, error: 'Connection error: $e');
    }
  }

  /// Rate a recipe (1-5 stars)
  static Future<bool> rateRecipe({required int recipeId, required double rating}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meals/ratings'),
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

  /// Get user's rating for a recipe
  static Future<double?> getRecipeRating({required int recipeId}) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/meals/ratings/$recipeId'),
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

  /// Get full recipe details by ID
  static Future<RecipeDetail?> getRecipeById({required int recipeId}) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/meals/recipe/$recipeId'),
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

  static Future<List<String>> searchIngredients({required String query}) async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ingredients/search?q=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<String>> getExcludedIngredients() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ingredients/excluded'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addExcludedIngredient({required String ingredient}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ingredients/excluded'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'ingredient': ingredient}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeExcludedIngredient({required String ingredient}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/ingredients/excluded/${Uri.encodeComponent(ingredient)}'),
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

  static Future<List<String>> getLikedIngredients() async {
    final token = await getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ingredients/liked'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addLikedIngredient({required String ingredient}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ingredients/liked'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'ingredient': ingredient}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeLikedIngredient({required String ingredient}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/ingredients/liked/${Uri.encodeComponent(ingredient)}'),
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

  static Future<bool> deleteRecipeRating({required int recipeId}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/meals/ratings/$recipeId'),
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
      rating: json['rating'].toDouble(),
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
