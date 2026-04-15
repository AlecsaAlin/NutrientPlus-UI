import '../../features/meal_plan/models/meal_models.dart';
import '../services/favorites_service.dart';
import '../services/meal_service.dart';
import '../services/ratings_service.dart';

class RecipeRepository {
  Future<FavoritesResult> getFavorites() async =>
      await FavoritesService.getFavorites();

  Future<bool> addFavorite({required int recipeId}) async =>
      await FavoritesService.addFavorite(recipeId: recipeId);

  Future<bool> removeFavorite({required int recipeId}) async =>
      await FavoritesService.removeFavorite(recipeId: recipeId);

  Future<bool> isFavorite({required int recipeId}) async =>
      await FavoritesService.isFavorite(recipeId: recipeId);

  Future<RatingsResult> getUserRatings() async =>
      await RatingsService.getUserRatings();

  Future<bool> rateRecipe({required int recipeId, required double rating}) async =>
      await RatingsService.rateRecipe(recipeId: recipeId, rating: rating);

  Future<double?> getRecipeRating({required int recipeId}) async =>
      await RatingsService.getRecipeRating(recipeId: recipeId);

  Future<bool> deleteRecipeRating({required int recipeId}) async =>
      await RatingsService.deleteRecipeRating(recipeId: recipeId);

  Future<RecipeDetail?> getRecipeById({required int recipeId}) async =>
      await MealService.getRecipeById(recipeId: recipeId);
}
