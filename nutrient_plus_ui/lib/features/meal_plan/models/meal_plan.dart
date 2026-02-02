/// Model for meal item
class MealItem {
  final String name;
  final int calories;
  final String emoji;

  MealItem({
    required this.name,
    required this.calories,
    required this.emoji,
  });

  MealItem copyWith({
    String? name,
    int? calories,
    String? emoji,
  }) {
    return MealItem(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      emoji: emoji ?? this.emoji,
    );
  }
}

/// Model for a day's meal plan
class DayMealPlan {
  final MealItem breakfast;
  final MealItem lunch;
  final MealItem snack;
  final MealItem dinner;

  DayMealPlan({
    required this.breakfast,
    required this.lunch,
    required this.snack,
    required this.dinner,
  });

  int get totalCalories => 
      breakfast.calories + lunch.calories + snack.calories + dinner.calories;
}
