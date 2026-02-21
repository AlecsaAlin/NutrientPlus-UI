import '../../features/auth/models/user.dart';
import '../services/api_service.dart';

/// Repository for user-related data operations
/// Acts as single source of truth for user data
class UserRepository {
  User? _cachedUser;

  User? get cachedUser => _cachedUser;

  /// Get current user from API or cache
  Future<User?> getCurrentUser({bool forceRefresh = false}) async {
    if (_cachedUser != null && !forceRefresh) {
      return _cachedUser;
    }

    final user = await ApiService.getCurrentUser();
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
    int? preferredMealsPerDay,
    int? maxCookTime,
    bool clearMaxCookTime = false,
  }) async {
    final result = await ApiService.updateProfile(
      currentWeight: currentWeight,
      goalWeight: goalWeight,
      gender: gender,
      profileImagePath: profileImagePath,
      height: height,
      age: age,
      activityLevel: activityLevel,
      goalType: goalType,
      preferredMealsPerDay: preferredMealsPerDay,
      maxCookTime: maxCookTime,
      clearMaxCookTime: clearMaxCookTime,
    );

    if (result.success && result.user != null) {
      _cachedUser = result.user;
    }

    return result;
  }

  /// Clear cached user data
  void clearCache() {
    _cachedUser = null;
    ApiService.clearUserCache();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await ApiService.isLoggedIn();
  }
}
