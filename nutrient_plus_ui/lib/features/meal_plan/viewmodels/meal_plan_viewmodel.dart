import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/meal_plan_repository.dart';
import '../models/meal_models.dart';

/// ViewModel for Meal Plan screen
class MealPlanViewModel extends BaseViewModel {
  final MealPlanRepository _mealPlanRepository;

  MealPlanViewModel({MealPlanRepository? mealPlanRepository})
      : _mealPlanRepository = mealPlanRepository ?? MealPlanRepository();

  late DateTime _selectedDate;
  bool _isGenerating = false;
  bool _isLoadingSaved = true;
  String? _error;

  // Cache generated plans by date string (YYYY-MM-DD)
  final Map<String, MealPlanResponse> _savedPlans = {};

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

  /// Collect recipe IDs from a sliding 10-day window ending at the selected date
  List<int> getRecentRecipeIds() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final recipeIds = <int>{};

    final daysAhead = selectedOnly.isAfter(todayOnly)
        ? selectedOnly.difference(todayOnly).inDays
        : 0;

    final pastDays = (10 - daysAhead).clamp(0, 10);

    // Collect from past
    for (int i = 1; i <= pastDays; i++) {
      _collectRecipeIds(todayOnly.subtract(Duration(days: i)), recipeIds);
    }

    // Collect from today up to (but not including) the selected date
    for (int i = 0; i < daysAhead; i++) {
      _collectRecipeIds(todayOnly.add(Duration(days: i)), recipeIds);
    }

    // If selected date is today or in the past, still include today
    if (daysAhead == 0) {
      _collectRecipeIds(todayOnly, recipeIds);
    }

    return recipeIds.toList();
  }

  void _collectRecipeIds(DateTime date, Set<int> recipeIds) {
    final plan = _savedPlans[formatDate(date)];
    if (plan == null) return;
    for (final slot in plan.meals) {
      if (slot.recipe != null) {
        recipeIds.add(slot.recipe!.recipeId);
      }
    }
  }

  /// Generate a new meal plan
  Future<void> generatePlan() async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    final excludeIds = getRecentRecipeIds();

    final result = await _mealPlanRepository.generateMealPlan(
      excludeRecipeIds: excludeIds.isNotEmpty ? excludeIds : null,
    );

    _isGenerating = false;
    if (result.success && result.mealPlan != null) {
      final dateKey = formatDate(_selectedDate);
      _savedPlans[dateKey] = result.mealPlan!;
      // Save to backend in the background
      _mealPlanRepository.saveMealPlan(planDate: dateKey, plan: result.mealPlan!);
    } else {
      _error = result.error ?? 'Failed to generate meal plan';
    }
    notifyListeners();
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

  /// Check if a date has a plan
  bool hasPlanForDate(DateTime date) {
    return _savedPlans.containsKey(formatDate(date));
  }
}
