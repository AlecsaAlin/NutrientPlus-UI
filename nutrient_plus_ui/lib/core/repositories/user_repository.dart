import '../../features/auth/models/user.dart';
import '../services/auth_service.dart';
import '../services/ingredients_service.dart';


class UserRepository {
  User? _cachedUser;

  User? get cachedUser => _cachedUser;


  Future<User?> getCurrentUser({bool forceRefresh = false}) async {
    if (_cachedUser != null && !forceRefresh) {
      return _cachedUser;
    }

    final user = await AuthService.getCurrentUser();
    _cachedUser = user;
    return user;
  }

  /// Update user profile
  Future<UpdateResult> updateProfile({
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
    final result = await AuthService.updateProfile(
      currentWeight: currentWeight,
      goalWeight: goalWeight,
      gender: gender,
      profileImagePath: profileImagePath,
      height: height,
      age: age,
      activityLevel: activityLevel,
      goalType: goalType,
      goalTimeline: goalTimeline,
      preferredMealsPerDay: preferredMealsPerDay,
      maxCookTime: maxCookTime,
      clearMaxCookTime: clearMaxCookTime,
      explorationPreference: explorationPreference,
    );

    if (result.success && result.user != null) {
      _cachedUser = result.user;
    }

    return result;
  }

  /// Clear cached user data
  void clearCache() {
    _cachedUser = null;
    AuthService.clearUserCache();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await AuthService.isLoggedIn();
  }

  /// Search ingredients by name
  Future<List<String>> searchIngredients({required String query}) async {
    return await IngredientsService.searchIngredients(query: query);
  }

  Future<List<String>> getExcludedIngredients() async {
    return await IngredientsService.getExcludedIngredients();
  }

  Future<bool> addExcludedIngredient({required String ingredient}) async {
    final success = await IngredientsService.addExcludedIngredient(ingredient: ingredient);
    if (success && _cachedUser != null) {
      final updated = [..._cachedUser!.excludedIngredients, ingredient];
      _cachedUser = _cachedUser!.copyWith(excludedIngredients: updated);
    }
    return success;
  }

  Future<bool> removeExcludedIngredient({required String ingredient}) async {
    final success = await IngredientsService.removeExcludedIngredient(ingredient: ingredient);
    if (success && _cachedUser != null) {
      final updated = _cachedUser!.excludedIngredients
          .where((i) => i != ingredient)
          .toList();
      _cachedUser = _cachedUser!.copyWith(excludedIngredients: updated);
    }
    return success;
  }

  Future<List<String>> getLikedIngredients() async {
    return await IngredientsService.getLikedIngredients();
  }

  Future<bool> addLikedIngredient({required String ingredient}) async {
    final success = await IngredientsService.addLikedIngredient(ingredient: ingredient);
    if (success && _cachedUser != null) {
      final updated = [..._cachedUser!.likedIngredients, ingredient];
      _cachedUser = _cachedUser!.copyWith(likedIngredients: updated);
    }
    return success;
  }

  Future<bool> removeLikedIngredient({required String ingredient}) async {
    final success = await IngredientsService.removeLikedIngredient(ingredient: ingredient);
    if (success && _cachedUser != null) {
      final updated = _cachedUser!.likedIngredients
          .where((i) => i != ingredient)
          .toList();
      _cachedUser = _cachedUser!.copyWith(likedIngredients: updated);
    }
    return success;
  }
}
