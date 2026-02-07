import 'package:flutter/material.dart';
import '../models/meal_models.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class MealPlanTab extends StatefulWidget {
  const MealPlanTab({super.key});

  @override
  State<MealPlanTab> createState() => _MealPlanTabState();
}

class _MealPlanTabState extends State<MealPlanTab> {
  int _selectedDayIndex = DateTime.now().weekday - 1;
  bool _isLoading = false;
  bool _isLoadingSaved = true;
  String? _error;

  // Cache generated plans per day index
  final Map<int, MealPlanResponse> _weeklyPlans = {};

  MealPlanResponse? get _currentPlan => _weeklyPlans[_selectedDayIndex];

  @override
  void initState() {
    super.initState();
    _loadSavedPlans();
  }

  /// Get the date for a given day index in the current week
  DateTime _dateForDayIndex(int dayIndex) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return startOfWeek.add(Duration(days: dayIndex));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSavedPlans() async {
    final startDate = _formatDate(_dateForDayIndex(0));
    final endDate = _formatDate(_dateForDayIndex(6));

    final result = await ApiService.getSavedMealPlans(
      startDate: startDate,
      endDate: endDate,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingSaved = false;
      if (result.success && result.plans != null) {
        for (final entry in result.plans!.entries) {
          // Convert date string to day index
          final date = DateTime.parse(entry.key);
          final dayIndex = date.weekday - 1;
          _weeklyPlans[dayIndex] = entry.value;
        }
      }
    });
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiService.generateMealPlan();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success && result.mealPlan != null) {
        _weeklyPlans[_selectedDayIndex] = result.mealPlan!;
        // Save to backend in the background
        final date = _formatDate(_dateForDayIndex(_selectedDayIndex));
        ApiService.saveMealPlan(planDate: date, plan: result.mealPlan!);
      } else {
        _error = result.error ?? 'Failed to generate meal plan';
      }
    });
  }

  void _swapAlternative(int mealIndex, int altIndex) {
    final plan = _currentPlan;
    if (plan == null) return;

    setState(() {
      final slot = plan.meals[mealIndex];
      final currentRecipe = slot.recipe;
      final alternative = slot.alternatives[altIndex];

      // Swap primary with alternative
      slot.recipe = alternative;
      if (currentRecipe != null) {
        slot.alternatives[altIndex] = currentRecipe;
      }

      // Recalculate daily totals with new recipes
      plan.recalculateTotals();
    });

    // Save updated plan to backend
    final date = _formatDate(_dateForDayIndex(_selectedDayIndex));
    ApiService.saveMealPlan(planDate: date, plan: plan);
  }

  void _showMealDetails(MealSlot slot, int mealIndex) {
    final recipe = slot.recipe;
    if (recipe == null) return;

    final color = _getSlotColor(slot.slot);
    final icon = _getSlotIcon(slot.slot);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: meal type + icon
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _capitalize(slot.slot),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recipe name
              Text(
                recipe.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Nutrition info row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutritionItem(
                        'Calories', '${recipe.calories.toInt()}', 'kcal', Colors.orange),
                    _buildNutritionItem(
                        'Protein', '${recipe.proteinG.toInt()}', 'g', Colors.red[400]!),
                    _buildNutritionItem(
                        'Carbs', '${recipe.carbsG.toInt()}', 'g', Colors.blue[400]!),
                    _buildNutritionItem(
                        'Fat', '${recipe.fatG.toInt()}', 'g', Colors.amber[600]!),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Cook time if available
              if (recipe.totalTimeMinutes != null) ...[
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${recipe.totalTimeMinutes} minutes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Category if available
              if (recipe.category != null && recipe.category!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.category_outlined, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      recipe.category!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Ingredients section
              if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty) ...[
                const Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    recipe.ingredients!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Instructions section
              if (recipe.instructions != null && recipe.instructions!.isNotEmpty) ...[
                const Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    recipe.instructions!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Alternatives section
              if (slot.alternatives.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.swap_horiz, color: color, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Change to Alternative',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(slot.alternatives.length, (altIndex) {
                  final alt = slot.alternatives[altIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context);
                        _swapAlternative(mealIndex, altIndex);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alt.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildMiniChip('${alt.calories.toInt()} kcal', Colors.orange),
                                      const SizedBox(width: 6),
                                      _buildMiniChip('P ${alt.proteinG.toInt()}g', Colors.red[400]!),
                                      const SizedBox(width: 6),
                                      _buildMiniChip('C ${alt.carbsG.toInt()}g', Colors.blue[400]!),
                                      const SizedBox(width: 6),
                                      _buildMiniChip('F ${alt.fatG.toInt()}g', Colors.amber[600]!),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: color),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2, left: 2),
              child: Text(
                unit,
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAlternatives(int mealIndex) {
    final slot = _currentPlan?.meals[mealIndex];
    if (slot == null || slot.alternatives.isEmpty) return;

    final slotColors = _getSlotColor(slot.slot);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: slotColors, size: 22),
                const SizedBox(width: 8),
                Text(
                  '${_capitalize(slot.slot)} Alternatives',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(slot.alternatives.length, (altIndex) {
              final alt = slot.alternatives[altIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _swapAlternative(mealIndex, altIndex);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alt.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildMiniChip('${alt.calories.toInt()} kcal',
                                      Colors.orange),
                                  const SizedBox(width: 6),
                                  _buildMiniChip(
                                      'P ${alt.proteinG.toInt()}g',
                                      Colors.red[400]!),
                                  const SizedBox(width: 6),
                                  _buildMiniChip(
                                      'C ${alt.carbsG.toInt()}g',
                                      Colors.blue[400]!),
                                  const SizedBox(width: 6),
                                  _buildMiniChip(
                                      'F ${alt.fatG.toInt()}g',
                                      Colors.amber[600]!),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final fullDays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
      'Sunday'
    ];
    final today = DateTime.now().weekday - 1;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return Column(
      children: [
        // Week day selector
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
                    color: isSelected ? AppColors.primary : Colors.transparent,
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
                          color: isSelected ? Colors.white : Colors.grey[600],
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

        // Content
        Expanded(
          child: _isLoading || _isLoadingSaved
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        _isLoadingSaved
                            ? 'Loading your meal plans...'
                            : 'Generating your meal plan...',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : _error != null
                  ? _buildErrorState()
                  : _currentPlan != null
                      ? _buildMealPlanContent(fullDays, today)
                      : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generatePlan,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No meal plan for this day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a personalized plan based on your goals',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generatePlan,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Meal Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanContent(List<String> fullDays, int today) {
    final plan = _currentPlan!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: day name + calorie target
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${plan.dailyCalorieTarget.toInt()} kcal',
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
          const SizedBox(height: 20),

          // Daily totals summary
          _buildDailyTotals(plan),
          const SizedBox(height: 20),

          // Meal cards
          ...List.generate(plan.meals.length, (index) {
            return _buildMealCard(plan.meals[index], index);
          }),

          const SizedBox(height: 12),

          // Regenerate button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _generatePlan,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Regenerate Plan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDailyTotals(MealPlanResponse plan) {
    final totals = plan.dailyTotals;
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalItem(
              'Calories', '${totals.calories.toInt()}', 'kcal', Colors.orange),
          _buildTotalDivider(),
          _buildTotalItem(
              'Protein', '${totals.proteinG.toInt()}', 'g', Colors.red[400]!),
          _buildTotalDivider(),
          _buildTotalItem(
              'Carbs', '${totals.carbsG.toInt()}', 'g', Colors.blue[400]!),
          _buildTotalDivider(),
          _buildTotalItem(
              'Fat', '${totals.fatG.toInt()}', 'g', Colors.amber[600]!),
        ],
      ),
    );
  }

  Widget _buildTotalItem(
      String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2, left: 2),
              child: Text(
                unit,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey[200],
    );
  }

  Widget _buildMealCard(MealSlot slot, int mealIndex) {
    final recipe = slot.recipe;
    if (recipe == null) return const SizedBox.shrink();

    final color = _getSlotColor(slot.slot);
    final icon = _getSlotIcon(slot.slot);
    final time = _getSlotTime(slot.slot);

    return GestureDetector(
      onTap: () => _showMealDetails(slot, mealIndex),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + meal type + time + calories
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _capitalize(slot.slot),
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
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${recipe.calories.toInt()} kcal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Macro nutrients row
            Row(
              children: [
                _buildMacroChip(
                    'P', '${recipe.proteinG.toInt()}g', Colors.red[400]!),
                const SizedBox(width: 8),
                _buildMacroChip(
                    'C', '${recipe.carbsG.toInt()}g', Colors.blue[400]!),
                const SizedBox(width: 8),
                _buildMacroChip(
                    'F', '${recipe.fatG.toInt()}g', Colors.amber[600]!),
                if (recipe.totalTimeMinutes != null) ...[
                  const SizedBox(width: 8),
                  _buildMacroChip(
                      '', '${recipe.totalTimeMinutes} min', Colors.grey[500]!,
                      icon: Icons.timer_outlined),
                ],
                const Spacer(),
                if (slot.alternatives.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${slot.alternatives.length} alt',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color,
      {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          if (label.isNotEmpty)
            Text(
              '$label ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // Helpers

  Color _getSlotColor(String slot) {
    switch (slot.toLowerCase()) {
      case 'breakfast':
        return const Color(0xFFFFB347);
      case 'lunch':
        return const Color(0xFF4CAF50);
      case 'snack':
        return const Color(0xFF9C27B0);
      case 'dinner':
        return const Color(0xFF2196F3);
      default:
        return AppColors.primary;
    }
  }

  IconData _getSlotIcon(String slot) {
    switch (slot.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny_outlined;
      case 'lunch':
        return Icons.light_mode_outlined;
      case 'snack':
        return Icons.coffee_outlined;
      case 'dinner':
        return Icons.nights_stay_outlined;
      default:
        return Icons.restaurant;
    }
  }

  String _getSlotTime(String slot) {
    switch (slot.toLowerCase()) {
      case 'breakfast':
        return '7:00 - 9:00';
      case 'lunch':
        return '12:00 - 14:00';
      case 'snack':
        return '16:00 - 17:00';
      case 'dinner':
        return '19:00 - 21:00';
      default:
        return '';
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
