import 'package:flutter/material.dart';
import '../models/meal_models.dart';
import '../../../core/constants/app_colors.dart';

class MealPlanTab extends StatefulWidget {
  const MealPlanTab({super.key});

  @override
  State<MealPlanTab> createState() => _MealPlanTabState();
}

class _MealPlanTabState extends State<MealPlanTab> {
  int _selectedDayIndex = DateTime.now().weekday - 1;

  final Map<int, DayMealPlan> _weeklyMeals = {
    0: DayMealPlan(
      breakfast: MealItem(name: 'Oatmeal with Berries', calories: 350, emoji: '🥣'),
      lunch: MealItem(name: 'Grilled Chicken Salad', calories: 450, emoji: '🥗'),
      snack: MealItem(name: 'Greek Yogurt', calories: 150, emoji: '🥛'),
      dinner: MealItem(name: 'Salmon with Vegetables', calories: 550, emoji: '🐟'),
    ),
    1: DayMealPlan(
      breakfast: MealItem(name: 'Scrambled Eggs & Toast', calories: 400, emoji: '🍳'),
      lunch: MealItem(name: 'Turkey Sandwich', calories: 480, emoji: '🥪'),
      snack: MealItem(name: 'Apple & Almond Butter', calories: 200, emoji: '🍎'),
      dinner: MealItem(name: 'Pasta Primavera', calories: 520, emoji: '🍝'),
    ),
    2: DayMealPlan(
      breakfast: MealItem(name: 'Smoothie Bowl', calories: 380, emoji: '🫐'),
      lunch: MealItem(name: 'Buddha Bowl', calories: 500, emoji: '🥙'),
      snack: MealItem(name: 'Protein Bar', calories: 180, emoji: '🍫'),
      dinner: MealItem(name: 'Grilled Steak & Potatoes', calories: 650, emoji: '🥩'),
    ),
    3: DayMealPlan(
      breakfast: MealItem(name: 'Avocado Toast', calories: 320, emoji: '🥑'),
      lunch: MealItem(name: 'Chicken Wrap', calories: 450, emoji: '🌯'),
      snack: MealItem(name: 'Mixed Nuts', calories: 170, emoji: '🥜'),
      dinner: MealItem(name: 'Fish Tacos', calories: 480, emoji: '🌮'),
    ),
    4: DayMealPlan(
      breakfast: MealItem(name: 'Pancakes & Fruit', calories: 450, emoji: '🥞'),
      lunch: MealItem(name: 'Sushi Bowl', calories: 520, emoji: '🍱'),
      snack: MealItem(name: 'Hummus & Veggies', calories: 160, emoji: '🥕'),
      dinner: MealItem(name: 'Pizza Night', calories: 700, emoji: '🍕'),
    ),
    5: DayMealPlan(
      breakfast: MealItem(name: 'French Toast', calories: 420, emoji: '🍞'),
      lunch: MealItem(name: 'Burger & Fries', calories: 750, emoji: '🍔'),
      snack: MealItem(name: 'Fruit Smoothie', calories: 200, emoji: '🍓'),
      dinner: MealItem(name: 'BBQ Chicken', calories: 580, emoji: '🍗'),
    ),
    6: DayMealPlan(
      breakfast: MealItem(name: 'Eggs Benedict', calories: 480, emoji: '🍳'),
      lunch: MealItem(name: 'Roast Chicken', calories: 550, emoji: '🍖'),
      snack: MealItem(name: 'Cheese & Crackers', calories: 220, emoji: '🧀'),
      dinner: MealItem(name: 'Soup & Salad', calories: 380, emoji: '🥗'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final today = DateTime.now().weekday - 1;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final dayMeals = _weeklyMeals[_selectedDayIndex];
    final totalCalories = dayMeals != null
        ? dayMeals.breakfast.calories + dayMeals.lunch.calories +
            dayMeals.snack.calories + dayMeals.dinner.calories
        : 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isSelected = index == _selectedDayIndex;
              final isToday = index == today;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                },
                child: Container(
                  width: 46,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        days[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullDays[_selectedDayIndex],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDayIndex == today ? 'Today' : '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalCalories kcal',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (dayMeals != null) ...[
                  _buildMealCard(
                    mealType: 'Breakfast',
                    time: '7:00 - 9:00',
                    meal: dayMeals.breakfast,
                    color: const Color(0xFFFFB347),
                  ),
                  _buildMealCard(
                    mealType: 'Lunch',
                    time: '12:00 - 14:00',
                    meal: dayMeals.lunch,
                    color: const Color(0xFF4CAF50),
                  ),
                  _buildMealCard(
                    mealType: 'Snack',
                    time: '16:00 - 17:00',
                    meal: dayMeals.snack,
                    color: const Color(0xFF9C27B0),
                  ),
                  _buildMealCard(
                    mealType: 'Dinner',
                    time: '19:00 - 21:00',
                    meal: dayMeals.dinner,
                    color: const Color(0xFF2196F3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard({
    required String mealType,
    required String time,
    required MealItem meal,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                meal.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mealType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${meal.calories} kcal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
