import '../services/api_service.dart';
import '../../features/meal_plan/models/meal_models.dart';

class RecipeRepository {
  Future<FavoritesResult> getFavorites() async =>
      await ApiService.getFavorites();

  Future<bool> addFavorite({required int recipeId}) async =>
      await ApiService.addFavorite(recipeId: recipeId);

  Future<bool> removeFavorite({required int recipeId}) async =>
      await ApiService.removeFavorite(recipeId: recipeId);

  Future<bool> isFavorite({required int recipeId}) async =>
      await ApiService.isFavorite(recipeId: recipeId);

  Future<RatingsResult> getUserRatings() async =>
      await ApiService.getUserRatings();

  Future<bool> rateRecipe({required int recipeId, required double rating}) async =>
      await ApiService.rateRecipe(recipeId: recipeId, rating: rating);

  Future<double?> getRecipeRating({required int recipeId}) async =>
      await ApiService.getRecipeRating(recipeId: recipeId);

  Future<bool> deleteRecipeRating({required int recipeId}) async =>
      await ApiService.deleteRecipeRating(recipeId: recipeId);

  Future<RecipeDetail?> getRecipeById({required int recipeId}) async =>
      await ApiService.getRecipeById(recipeId: recipeId);
}
