import 'dart:io';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/services/nutrition_service.dart';
import '../../../core/services/health_service.dart';
import '../../auth/models/user.dart';
import '../models/calorie_info.dart';

class ProfileViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  ProfileViewModel({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  User? _user;
  File? _profileImage;
  CalorieInfo? _calorieInfo;
  bool _isHealthConnected = false;
  int _weeklyAvgSteps = 0;
  bool _dynamicActivityEnabled = false;

  User? get user => _user;
  File? get profileImage => _profileImage;
  CalorieInfo? get calorieInfo => _calorieInfo;
  bool get isHealthConnected => _isHealthConnected;
  int get weeklyAvgSteps => _weeklyAvgSteps;
  bool get dynamicActivityEnabled => _dynamicActivityEnabled;

  static const String _dynamicActivityPrefKey = 'dynamic_activity_enabled';

  static ActivityLevel activityLevelFromSteps(int avgStepsPerDay) {
    if (avgStepsPerDay < 6000) return ActivityLevel.sedentary;
    if (avgStepsPerDay < 9000) return ActivityLevel.lightlyActive;
    if (avgStepsPerDay < 12000) return ActivityLevel.moderatelyActive;
    if (avgStepsPerDay < 15000) return ActivityLevel.veryActive;
    return ActivityLevel.extraActive;
  }

  Future<void> loadUser({bool forceRefresh = false}) async {
    setLoading(true);
    clearError();

    try {
      _user = await _userRepository.getCurrentUser(forceRefresh: forceRefresh);
      final calorieResult = await NutritionService.getCalorieInfo();
      if (calorieResult.success) {
        _calorieInfo = calorieResult.calorieInfo;
      }
      await _checkHealthConnection();
      setLoading(false);
    } catch (e) {
      setLoading(false);
      setError('Error loading profile: $e');
    }
  }

  Future<void> _checkHealthConnection() async {
    try {
      final health = Health();
      final hasPerms = await health.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      _isHealthConnected = hasPerms == true;

      if (_isHealthConnected) {
        final prefs = await SharedPreferences.getInstance();
        _dynamicActivityEnabled = prefs.getBool(_dynamicActivityPrefKey) ?? false;
        await _fetchWeeklyAvgSteps();
        if (_dynamicActivityEnabled) {
          await _applyDynamicActivityLevel();
        }
      }
      notifyListeners();
    } catch (_) {
      _isHealthConnected = false;
    }
  }

  Future<void> _fetchWeeklyAvgSteps() async {
    _weeklyAvgSteps = await HealthService.fetchAvgDailySteps(days: 7);
  }

  Future<void> setDynamicActivityEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dynamicActivityPrefKey, enabled);
    _dynamicActivityEnabled = enabled;
    if (enabled) {
      await _applyDynamicActivityLevel();
    }
    notifyListeners();
  }

  Future<void> _applyDynamicActivityLevel() async {
    final level = activityLevelFromSteps(_weeklyAvgSteps);
    if (_user?.activityLevel != level.value) {
      await updateActivityLevel(level.value);
    }
  }

  void setProfileImage(File image) {
    _profileImage = image;
    notifyListeners();
  }

  Future<void> updateGender(String gender) async {
    _user = _user?.copyWith(gender: gender);
    notifyListeners();

    final result = await _userRepository.updateProfile(gender: gender);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  Future<void> updateCurrentWeight(double weight) async {
    _user = _user?.copyWith(currentWeight: weight);
    notifyListeners();

    final result = await _userRepository.updateProfile(currentWeight: weight);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  Future<void> updateGoalWeight(double weight) async {
    _user = _user?.copyWith(goalWeight: weight);
    notifyListeners();

    final result = await _userRepository.updateProfile(goalWeight: weight);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  Future<void> updateHeight(double height) async {
    _user = _user?.copyWith(height: height);
    notifyListeners();

    final result = await _userRepository.updateProfile(height: height);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  Future<void> updateAge(int age) async {
    _user = _user?.copyWith(age: age);
    notifyListeners();

    final result = await _userRepository.updateProfile(age: age);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  /// Update profile image path
  Future<void> updateProfileImagePath(String path) async {
    final result = await _userRepository.updateProfile(profileImagePath: path);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  /// Update activity level
  Future<void> updateActivityLevel(String activityLevel) async {
    _user = _user?.copyWith(activityLevel: activityLevel);
    notifyListeners();

    final result = await _userRepository.updateProfile(activityLevel: activityLevel);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  /// Update goal type
  Future<void> updateGoalType(String goalType) async {
    _user = _user?.copyWith(goalType: goalType);
    notifyListeners();

    final result = await _userRepository.updateProfile(goalType: goalType);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  /// Update preferred meals per day
  Future<void> updatePreferredMealsPerDay(int meals) async {
    _user = _user?.copyWith(preferredMealsPerDay: meals);
    notifyListeners();

    final result = await _userRepository.updateProfile(preferredMealsPerDay: meals);
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  /// Update max cook time
  Future<void> updateMaxCookTime(int? maxCookTime, {bool clear = false}) async {
    _user = _user?.copyWith(maxCookTime: maxCookTime);
    notifyListeners();

    final result = await _userRepository.updateProfile(
      maxCookTime: maxCookTime,
      clearMaxCookTime: clear,
    );
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }
}
