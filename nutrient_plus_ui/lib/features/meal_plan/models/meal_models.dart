// Models
class MealItem {
  final String name;
  final int calories;
  final String emoji;

  MealItem({
    required this.name,
    required this.calories,
    required this.emoji,
  });
}

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
}

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
