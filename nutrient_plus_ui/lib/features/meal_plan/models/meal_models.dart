class RecipeDetail {
  final int recipeId;
  final String name;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final double sugarG;
  final double fiberG;
  final int? totalTimeMinutes;
  final String? category;
  final String? ingredients;
  final String? instructions;
  final int? numIngredients;
  final double predictedRating;
  final double matchScore;

  RecipeDetail({
    required this.recipeId,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.sugarG,
    required this.fiberG,
    this.totalTimeMinutes,
    this.category,
    this.ingredients,
    this.instructions,
    this.numIngredients,
    required this.predictedRating,
    required this.matchScore,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      recipeId: json['recipe_id'] ?? 0,
      name: json['name'] ?? 'Unknown Recipe',
      calories: (json['calories'] ?? 0).toDouble(),
      proteinG: (json['protein_g'] ?? 0).toDouble(),
      fatG: (json['fat_g'] ?? 0).toDouble(),
      carbsG: (json['carbs_g'] ?? 0).toDouble(),
      sugarG: (json['sugar_g'] ?? 0).toDouble(),
      fiberG: (json['fiber_g'] ?? 0).toDouble(),
      totalTimeMinutes: json['total_time_minutes'],
      category: json['category'],
      ingredients: json['ingredients'],
      instructions: json['instructions'],
      numIngredients: json['num_ingredients'],
      predictedRating: (json['predicted_rating'] ?? 0).toDouble(),
      matchScore: (json['match_score'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'recipe_id': recipeId,
    'name': name,
    'calories': calories,
    'protein_g': proteinG,
    'fat_g': fatG,
    'carbs_g': carbsG,
    'sugar_g': sugarG,
    'fiber_g': fiberG,
    'total_time_minutes': totalTimeMinutes,
    'category': category,
    'ingredients': ingredients,
    'instructions': instructions,
    'num_ingredients': numIngredients,
    'predicted_rating': predictedRating,
    'match_score': matchScore,
  };
}

class MealSlot {
  final String slot;
  RecipeDetail? recipe;
  List<RecipeDetail> alternatives;
  final double targetCalories;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;

  MealSlot({
    required this.slot,
    this.recipe,
    this.alternatives = const [],
    required this.targetCalories,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
  });

  factory MealSlot.fromJson(Map<String, dynamic> json) {
    return MealSlot(
      slot: json['slot'] ?? '',
      recipe: json['recipe'] != null
          ? RecipeDetail.fromJson(json['recipe'])
          : null,
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => RecipeDetail.fromJson(e))
              .toList() ??
          [],
      targetCalories: (json['target_calories'] ?? 0).toDouble(),
      targetProteinG: (json['target_protein_g'] ?? 0).toDouble(),
      targetCarbsG: (json['target_carbs_g'] ?? 0).toDouble(),
      targetFatG: (json['target_fat_g'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'recipe': recipe?.toJson(),
    'alternatives': alternatives.map((e) => e.toJson()).toList(),
    'target_calories': targetCalories,
    'target_protein_g': targetProteinG,
    'target_carbs_g': targetCarbsG,
    'target_fat_g': targetFatG,
  };
}

class DailyTotals {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  DailyTotals({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory DailyTotals.fromJson(Map<String, dynamic> json) {
    return DailyTotals(
      calories: (json['calories'] ?? 0).toDouble(),
      proteinG: (json['protein_g'] ?? 0).toDouble(),
      carbsG: (json['carbs_g'] ?? 0).toDouble(),
      fatG: (json['fat_g'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
  };
}

class MealPlanResponse {
  final double dailyCalorieTarget;
  final String goalType;
  final List<MealSlot> meals;
  DailyTotals dailyTotals;

  MealPlanResponse({
    required this.dailyCalorieTarget,
    required this.goalType,
    required this.meals,
    required this.dailyTotals,
  });

  /// Recalculate daily totals from current meal recipes
  void recalculateTotals() {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final slot in meals) {
      if (slot.recipe != null) {
        calories += slot.recipe!.calories;
        protein += slot.recipe!.proteinG;
        carbs += slot.recipe!.carbsG;
        fat += slot.recipe!.fatG;
      }
    }

    dailyTotals = DailyTotals(
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
    );
  }

  factory MealPlanResponse.fromJson(Map<String, dynamic> json) {
    return MealPlanResponse(
      dailyCalorieTarget: (json['daily_calorie_target'] ?? 0).toDouble(),
      goalType: json['goal_type'] ?? 'maintain',
      meals: (json['meals'] as List<dynamic>?)
              ?.map((e) => MealSlot.fromJson(e))
              .toList() ??
          [],
      dailyTotals: DailyTotals.fromJson(json['daily_totals'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'daily_calorie_target': dailyCalorieTarget,
    'goal_type': goalType,
    'meals': meals.map((e) => e.toJson()).toList(),
    'daily_totals': dailyTotals.toJson(),
  };
}

// Keep InventoryItem here — inventory_tab.dart imports from this file
class InventoryItem {
  final String name;
  final String quantity;
  final String category;
  final String emoji;

  InventoryItem({
    required this.name,
    required this.quantity,
    required this.category,
    required this.emoji,
  });
}
