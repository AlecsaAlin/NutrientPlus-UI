import '../services/meal_service.dart';
import '../../features/meal_plan/models/meal_models.dart';

class MealPlanRepository {
  Future<MealPlanResult> generateMealPlan({
    int? numMeals,
    int? maxCookTime,
  }) async =>
      await MealService.generateMealPlan(
        numMeals: numMeals,
        maxCookTime: maxCookTime,
      );

  Future<bool> saveMealPlan({
    required String planDate,
    required MealPlanResponse plan,
  }) async =>
      await MealService.saveMealPlan(planDate: planDate, plan: plan);

  Future<SavedPlansResult> getSavedMealPlans({
    required String startDate,
    required String endDate,
  }) async =>
      await MealService.getSavedMealPlans(startDate: startDate, endDate: endDate);

  Future<bool> syncMealHistory() async =>
      await MealService.syncMealHistory();

  Future<bool> addToHistory({required int recipeId}) async =>
      await MealService.rateMeal(recipeId: recipeId);
}
