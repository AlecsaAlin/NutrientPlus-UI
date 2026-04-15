import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/recipe_repository.dart';
import '../../../core/services/favorites_service.dart' show FavoriteRecipe;
import '../../../core/services/meal_service.dart';
import '../../../core/services/ratings_service.dart' show UserRating;
import '../../meal_plan/models/meal_models.dart';

class SavedViewModel extends BaseViewModel {
  final RecipeRepository _recipeRepository;

  SavedViewModel({RecipeRepository? recipeRepository})
      : _recipeRepository = recipeRepository ?? RecipeRepository();

  List<FavoriteRecipe> _favorites = [];
  List<UserRating> _ratings = [];
  bool _isLoadingFavorites = true;
  bool _isLoadingRatings = true;
  String _reviewSort = 'time';

  List<FavoriteRecipe> get favorites => _favorites;
  List<UserRating> get ratings => _ratings;
  bool get isLoadingFavorites => _isLoadingFavorites;
  bool get isLoadingRatings => _isLoadingRatings;
  String get reviewSort => _reviewSort;

  List<UserRating> get sortedRatings {
    final sorted = List<UserRating>.from(_ratings);
    if (_reviewSort == 'score') {
      sorted.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return sorted;
  }

  Future<void> loadData() {
    return Future.wait([
      loadFavorites(),
      loadRatings(),
    ]);
  }

  Future<void> loadFavorites() async {
    final result = await _recipeRepository.getFavorites();
    _isLoadingFavorites = false;
    if (result.success && result.favorites != null) {
      _favorites = result.favorites!;
    }
    notifyListeners();
  }

  Future<void> loadRatings() async {
    final result = await _recipeRepository.getUserRatings();
    _isLoadingRatings = false;
    if (result.success && result.ratings != null) {
      _ratings = result.ratings!;
    }
    notifyListeners();
  }

  void setReviewSort(String sort) {
    _reviewSort = sort;
    notifyListeners();
  }

  Future<bool> removeFavorite(FavoriteRecipe fav) async {
    _favorites.remove(fav);
    notifyListeners();

    final success =
        await _recipeRepository.removeFavorite(recipeId: fav.recipeId);
    if (!success) {
      _favorites.add(fav);
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteRating(UserRating rating) async {
    _ratings.remove(rating);
    notifyListeners();

    final success = await _recipeRepository.deleteRecipeRating(
        recipeId: rating.recipeId);
    if (!success) {
      _ratings.add(rating);
      notifyListeners();
    }
    return success;
  }

  Future<RecipeDetail?> getRecipeById(int recipeId) async {
    return await _recipeRepository.getRecipeById(recipeId: recipeId);
  }

  Future<bool> scheduleForDate({
    required FavoriteRecipe fav,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final recipe = RecipeDetail(
      recipeId: fav.recipeId,
      name: fav.recipeName,
      calories: fav.calories,
      proteinG: fav.proteinG,
      fatG: fav.fatG,
      carbsG: fav.carbsG,
      sugarG: 0,
      fiberG: 0,
      totalTimeMinutes: fav.totalTimeMinutes,
      predictedRating: 0,
      matchScore: 0,
    );

    MealPlanResponse plan;

    final existingPlans = await MealService.getSavedMealPlans(
      startDate: dateStr,
      endDate: dateStr,
    );

    if (existingPlans.success &&
        existingPlans.plans != null &&
        existingPlans.plans!.containsKey(dateStr)) {
      plan = existingPlans.plans![dateStr]!;
    } else {
      final generated = await MealService.generateMealPlan();
      if (!generated.success || generated.mealPlan == null) return false;
      plan = generated.mealPlan!;
    }

    final bestIdx = _findBestSlotIndex(plan, fav.calories);
    plan.meals[bestIdx].recipe = recipe;
    plan.recalculateTotals();

    return await MealService.saveMealPlan(planDate: dateStr, plan: plan);
  }

  int _findBestSlotIndex(MealPlanResponse plan, double recipeCalories) {
    final emptyIdx = plan.meals.indexWhere((m) => m.recipe == null);
    if (emptyIdx >= 0) return emptyIdx;

    int bestIdx = 0;
    double bestDiff = double.infinity;
    for (int i = 0; i < plan.meals.length; i++) {
      final diff = (plan.meals[i].targetCalories - recipeCalories).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIdx = i;
      }
    }
    return bestIdx;
  }
}
