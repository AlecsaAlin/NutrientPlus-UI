import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/recipe_repository.dart';
import '../../../core/services/api_service.dart' show FavoriteRecipe, UserRating;
import '../../meal_plan/models/meal_models.dart' show RecipeDetail;

/// ViewModel for Saved (Favorites & Reviews) screen
class SavedViewModel extends BaseViewModel {
  final RecipeRepository _recipeRepository;

  SavedViewModel({RecipeRepository? recipeRepository})
      : _recipeRepository = recipeRepository ?? RecipeRepository();

  List<FavoriteRecipe> _favorites = [];
  List<UserRating> _ratings = [];
  bool _isLoadingFavorites = true;
  bool _isLoadingRatings = true;
  String _reviewSort = 'time';

  // Getters
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

  /// Load both favorites and ratings
  Future<void> loadData() {
    return Future.wait([
      loadFavorites(),
      loadRatings(),
    ]);
  }

  /// Load favorites
  Future<void> loadFavorites() async {
    final result = await _recipeRepository.getFavorites();
    _isLoadingFavorites = false;
    if (result.success && result.favorites != null) {
      _favorites = result.favorites!;
    }
    notifyListeners();
  }

  /// Load ratings
  Future<void> loadRatings() async {
    final result = await _recipeRepository.getUserRatings();
    _isLoadingRatings = false;
    if (result.success && result.ratings != null) {
      _ratings = result.ratings!;
    }
    notifyListeners();
  }

  /// Set review sort order
  void setReviewSort(String sort) {
    _reviewSort = sort;
    notifyListeners();
  }

  /// Remove a favorite (optimistic)
  Future<bool> removeFavorite(FavoriteRecipe fav) async {
    _favorites.remove(fav);
    notifyListeners();

    final success = await _recipeRepository.removeFavorite(recipeId: fav.recipeId);
    if (!success) {
      _favorites.add(fav);
      notifyListeners();
    }
    return success;
  }

  /// Delete a rating (optimistic)
  Future<bool> deleteRating(UserRating rating) async {
    _ratings.remove(rating);
    notifyListeners();

    final success = await _recipeRepository.deleteRecipeRating(recipeId: rating.recipeId);
    if (!success) {
      _ratings.add(rating);
      notifyListeners();
    }
    return success;
  }

  /// Get recipe details by ID
  Future<RecipeDetail?> getRecipeById(int recipeId) async {
    return await _recipeRepository.getRecipeById(recipeId: recipeId);
  }
}
