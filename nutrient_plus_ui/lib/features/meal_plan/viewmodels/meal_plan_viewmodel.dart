import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/meal_plan_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../features/auth/models/user.dart';
import '../models/meal_models.dart';

/// ViewModel for Meal Plan screen
class MealPlanViewModel extends BaseViewModel {
  final MealPlanRepository _mealPlanRepository;
  final UserRepository _userRepository;

  MealPlanViewModel({
    MealPlanRepository? mealPlanRepository,
    UserRepository? userRepository,
  })  : _mealPlanRepository = mealPlanRepository ?? MealPlanRepository(),
        _userRepository = userRepository ?? UserRepository();

  late DateTime _selectedDate;
  bool _isGenerating = false;
  bool _isLoadingSaved = true;
  String? _error;

  // Cache generated plans by date string (YYYY-MM-DD)
  final Map<String, MealPlanResponse> _savedPlans = {};

  // Snapshot of profile params at last plan generation (null = no generation this session)
  Map<String, dynamic>? _lastProfileSnapshot;

  // Number of days to show before and after today
  static const int daysRange = 15;

  // Getters
  DateTime get selectedDate => _selectedDate;
  bool get isGenerating => _isGenerating;
  bool get isLoadingSaved => _isLoadingSaved;
  String? get error => _error;
  Map<String, MealPlanResponse> get savedPlans => _savedPlans;

  MealPlanResponse? get currentPlan => _savedPlans[formatDate(_selectedDate)];

  bool get canSwap {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return !selectedOnly.isBefore(todayOnly);
  }

  /// Initialize the ViewModel
  void init() {
    _selectedDate = DateTime.now();
    loadSavedPlans();
    syncMealHistory();
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Format a date to YYYY-MM-DD
  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get date for a given index in the date picker
  DateTime getDateForIndex(int index) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return todayOnly.add(Duration(days: index - daysRange));
  }

  /// Sync meal history in the background
  Future<void> syncMealHistory() async {
    await _mealPlanRepository.syncMealHistory();
  }

  /// Load saved plans from backend
  Future<void> loadSavedPlans() async {
    final today = DateTime.now();
    final startDate = formatDate(today.subtract(const Duration(days: daysRange)));
    final endDate = formatDate(today.add(const Duration(days: daysRange)));

    final result = await _mealPlanRepository.getSavedMealPlans(
      startDate: startDate,
      endDate: endDate,
    );

    _isLoadingSaved = false;
    if (result.success && result.plans != null) {
      _savedPlans.addAll(result.plans!);
    }
    notifyListeners();
  }

  /// Build a comparable snapshot of the profile fields that influence meal plan generation.
  Map<String, dynamic> _buildProfileSnapshot(User user) {
    final excluded = [...user.excludedIngredients]..sort();
    final liked = [...user.likedIngredients]..sort();
    return {
      'activityLevel': user.activityLevel,
      'goalType': user.goalType,
      'preferredMealsPerDay': user.preferredMealsPerDay,
      'maxCookTime': user.maxCookTime,
      'explorationPreference': user.explorationPreference,
      'currentWeight': user.currentWeight,
      'goalWeight': user.goalWeight,
      'height': user.height,
      'age': user.age,
      'gender': user.gender,
      'excludedIngredients': excluded.join(','),
      'likedIngredients': liked.join(','),
    };
  }

  bool _hasProfileChanged(User user) {
    if (_lastProfileSnapshot == null) return true;
    final current = _buildProfileSnapshot(user);
    if (current.length != _lastProfileSnapshot!.length) return true;
    for (final key in current.keys) {
      if (current[key] != _lastProfileSnapshot![key]) return true;
    }
    return false;
  }

  /// Generate a new meal plan. Returns true if a new plan was generated,
  /// false if profile parameters have not changed since the last generation.
  Future<bool> generatePlan() async {
    final user = await _userRepository.getCurrentUser();
    if (user != null && !_hasProfileChanged(user)) {
      return false;
    }

    _isGenerating = true;
    _error = null;
    notifyListeners();

    final result = await _mealPlanRepository.generateMealPlan();

    _isGenerating = false;
    if (result.success && result.mealPlan != null) {
      final dateKey = formatDate(_selectedDate);
      _savedPlans[dateKey] = result.mealPlan!;
      // Save to backend in the background
      _mealPlanRepository.saveMealPlan(planDate: dateKey, plan: result.mealPlan!);
      // Record profile state so repeated refreshes are blocked until something changes
      if (user != null) _lastProfileSnapshot = _buildProfileSnapshot(user);
    } else {
      _error = result.error ?? 'Failed to generate meal plan';
    }
    notifyListeners();
    return true;
  }

  /// Swap a meal with an alternative
  void swapAlternative(int mealIndex, int altIndex) {
    if (!canSwap) return;

    final plan = currentPlan;
    if (plan == null) return;

    final slot = plan.meals[mealIndex];
    final currentRecipe = slot.recipe;
    final alternative = slot.alternatives[altIndex];

    // Swap primary with alternative
    slot.recipe = alternative;
    if (currentRecipe != null) {
      slot.alternatives[altIndex] = currentRecipe;
    }

    // Recalculate daily totals with new recipes
    plan.recalculateTotals();
    notifyListeners();

    // Save updated plan to backend
    final dateKey = formatDate(_selectedDate);
    _mealPlanRepository.saveMealPlan(planDate: dateKey, plan: plan);
  }

  /// Update the aggregated rating of a recipe in the current plan (live after user rates)
  void updateRecipeRating(int mealIndex, double newAggregatedRating, int newReviewCount) {
    final plan = currentPlan;
    if (plan == null) return;

    final slot = plan.meals[mealIndex];
    if (slot.recipe != null) {
      slot.recipe = slot.recipe!.copyWith(
        aggregatedRating: newAggregatedRating,
        reviewCount: newReviewCount,
      );
    }
    notifyListeners();

    // Persist the updated plan
    final dateKey = formatDate(_selectedDate);
    _mealPlanRepository.saveMealPlan(planDate: dateKey, plan: plan);
  }

  /// Check if a date has a plan
  bool hasPlanForDate(DateTime date) {
    return _savedPlans.containsKey(formatDate(date));
  }
}
