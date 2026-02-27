import '../services/api_service.dart';
import '../../features/meal_plan/models/meal_models.dart';

class MealPlanRepository {
  Future<MealPlanResult> generateMealPlan({
    int? numMeals,
    int? maxCookTime,
  }) async =>
      await ApiService.generateMealPlan(
        numMeals: numMeals,
        maxCookTime: maxCookTime,
      );

  Future<bool> saveMealPlan({
    required String planDate,
    required MealPlanResponse plan,
  }) async =>
      await ApiService.saveMealPlan(planDate: planDate, plan: plan);

  Future<SavedPlansResult> getSavedMealPlans({
    required String startDate,
    required String endDate,
  }) async =>
      await ApiService.getSavedMealPlans(startDate: startDate, endDate: endDate);

  Future<bool> syncMealHistory() async =>
      await ApiService.syncMealHistory();

  Future<bool> addToHistory({required int recipeId}) async =>
      await ApiService.rateMeal(recipeId: recipeId);
}
