import '../services/api_service.dart';
import '../../features/meal_plan/models/meal_models.dart';

class MealPlanRepository {
  Future<MealPlanResult> generateMealPlan({
    int? numMeals,
    int? maxCookTime,
    List<int>? excludeRecipeIds,
  }) async =>
      await ApiService.generateMealPlan(
        numMeals: numMeals,
        maxCookTime: maxCookTime,
        excludeRecipeIds: excludeRecipeIds,
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
}
