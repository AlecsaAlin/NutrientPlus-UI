import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/views/home_screen.dart';
import '../viewmodels/onboarding_survey_viewmodel.dart';

class OnboardingSurveyScreen extends StatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  late OnboardingSurveyViewModel _viewModel;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingSurveyViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onNext() async {
    final vm = _viewModel;
    if (!vm.canProceed) return;

    if (vm.isLastStep) {
      final success = await vm.submit();
      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      _textController.clear();
      vm.nextStep();
    }
  }

  void _onBack() {
    _textController.clear();
    _viewModel.previousStep();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<OnboardingSurveyViewModel>(
        builder: (context, vm, _) {
          return PopScope(
            canPop: false,
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(vm),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(vm.currentStepIndex),
                          child: _buildStepContent(vm),
                        ),
                      ),
                    ),
                    _buildFooter(vm),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(OnboardingSurveyViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 28,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.eco,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                'Step ${vm.currentStepIndex + 1} of ${vm.totalSteps}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (vm.currentStepIndex + 1) / vm.totalSteps,
              backgroundColor: AppColors.primaryWithOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(OnboardingSurveyViewModel vm) {
    final step = vm.currentStep;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.question,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          if (step.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              step.subtitle!,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 32),
          _buildStepInput(vm, step),
          if (vm.hasError) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.errorMessage!,
                      style: TextStyle(color: AppColors.error, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepInput(OnboardingSurveyViewModel vm, SurveyStep step) {
    switch (step.field) {
      case 'goalType':
        return _buildGoalTypeSelector(vm);
      case 'gender':
        return _buildGenderSelector(vm);
      case 'age':
        return _buildNumberInput(
          label: 'Age',
          unit: 'years',
          isDecimal: false,
          initialValue: vm.age?.toString(),
          onChanged: (v) => vm.setAge(int.tryParse(v)),
        );
      case 'height':
        return _buildNumberInput(
          label: 'Height',
          unit: 'cm',
          isDecimal: true,
          initialValue: vm.height?.toString(),
          onChanged: (v) => vm.setHeight(double.tryParse(v)),
        );
      case 'currentWeight':
        return _buildNumberInput(
          label: 'Current weight',
          unit: 'kg',
          isDecimal: true,
          initialValue: vm.currentWeight?.toString(),
          onChanged: (v) => vm.setCurrentWeight(double.tryParse(v)),
        );
      case 'goalWeight':
        return _buildNumberInput(
          label: 'Goal weight',
          unit: 'kg',
          isDecimal: true,
          initialValue: vm.goalWeight?.toString(),
          onChanged: (v) => vm.setGoalWeight(double.tryParse(v)),
        );
      case 'activityLevel':
        return _buildActivityLevelSelector(vm);
      case 'preferredMealsPerDay':
        return _buildMealsPerDaySelector(vm);
      case 'maxCookTime':
        return _buildCookTimeSelector(vm);
      case 'explorationPreference':
        return _buildExplorationPreferenceSelector(vm);
      case 'mealPreferences':
        return _buildMealPreferencesSelector(vm);
      default:
        return const SizedBox();
    }
  }

  Widget _buildGoalTypeSelector(OnboardingSurveyViewModel vm) {
    final options = [
      ('lose_weight', Icons.trending_down_rounded, 'Lose Weight', 'Reduce body fat'),
      ('gain_muscle', Icons.fitness_center_rounded, 'Gain Muscle', 'Build strength & mass'),
      ('maintain_weight', Icons.balance_rounded, 'Maintain Weight', 'Stay where I am'),
      ('eat_healthier', Icons.eco_rounded, 'Eat Healthier', 'Better food choices'),
    ];

    return Column(
      children: options.map((opt) {
        final selected = vm.goalType == opt.$1;
        return _OptionCard(
          icon: opt.$2,
          label: opt.$3,
          description: opt.$4,
          selected: selected,
          onTap: () => vm.setGoalType(opt.$1),
        );
      }).toList(),
    );
  }

  Widget _buildGenderSelector(OnboardingSurveyViewModel vm) {
    final options = [
      ('male', Icons.male_rounded, 'Male'),
      ('female', Icons.female_rounded, 'Female'),
    ];

    return Row(
      children: options.map((opt) {
        final selected = vm.gender == opt.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _CompactOptionCard(
              icon: opt.$2,
              label: opt.$3,
              selected: selected,
              onTap: () => vm.setGender(opt.$1),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityLevelSelector(OnboardingSurveyViewModel vm) {
    final options = [
      ('sedentary', Icons.chair_rounded, 'Sedentary', 'Little or no exercise'),
      ('lightly_active', Icons.directions_walk_rounded, 'Lightly Active', '1–3 days/week'),
      ('moderately_active', Icons.directions_bike_rounded, 'Moderately Active', '3–5 days/week'),
      ('very_active', Icons.directions_run_rounded, 'Very Active', '6–7 days/week')
    ];

    return Column(
      children: options.map((opt) {
        final selected = vm.activityLevel == opt.$1;
        return _OptionCard(
          icon: opt.$2,
          label: opt.$3,
          description: opt.$4,
          selected: selected,
          onTap: () => vm.setActivityLevel(opt.$1),
        );
      }).toList(),
    );
  }

  Widget _buildMealsPerDaySelector(OnboardingSurveyViewModel vm) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(2, (i) {
        final value = i + 3;
        final selected = vm.preferredMealsPerDay == value;
        return GestureDetector(
          onTap: () => vm.setPreferredMealsPerDay(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.grey.shade200,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: AppColors.primaryWithOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  value == 1 ? 'meal' : 'meals',
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCookTimeSelector(OnboardingSurveyViewModel vm) {
    final options = [
      (null, Icons.all_inclusive_rounded, 'No Limit', 'Any recipe is fine'),
      (30, Icons.timer_rounded, '30 min', 'Simple meals'),
      (45, Icons.timer_rounded, '45 min', 'Moderate effort'),
      (60, Icons.timer_rounded, '60 min', 'I enjoy cooking'),
    ];

    return Column(
      children: options.map((opt) {
        final selected = vm.maxCookTime == opt.$1;
        return _OptionCard(
          icon: opt.$2,
          label: opt.$3,
          description: opt.$4,
          selected: selected,
          onTap: () => vm.setMaxCookTime(opt.$1),
        );
      }).toList(),
    );
  }

  Widget _buildExplorationPreferenceSelector(OnboardingSurveyViewModel vm) {
    final options = [
      ('conservative', Icons.favorite_rounded, 'Stick with Favorites', 'Meals similar to what you already enjoy'),
      ('balanced', Icons.swap_horiz_rounded, 'A Bit of Both', 'Mostly familiar, with some surprises'),
      ('adventurous', Icons.explore_rounded, 'Surprise Me', 'Prioritise variety and new discoveries'),
    ];

    return Column(
      children: options.map((opt) {
        final selected = vm.explorationPreference == opt.$1;
        return _OptionCard(
          icon: opt.$2,
          label: opt.$3,
          description: opt.$4,
          selected: selected,
          onTap: () => vm.setExplorationPreference(opt.$1),
        );
      }).toList(),
    );
  }

  Widget _buildMealPreferencesSelector(OnboardingSurveyViewModel vm) {
    if (vm.isMealPreferencesLoading && vm.mealPreferenceIds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Column(
      children: vm.mealPreferenceIds.asMap().entries.map((entry) {
        final idx = entry.key;
        final recipeId = entry.value;
        final detail = vm.mealPreferenceDetails.length > idx
            ? vm.mealPreferenceDetails[idx]
            : null;
        final selection = vm.mealPreferenceSelections[recipeId];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selection == null
                  ? Colors.grey.shade200
                  : selection
                      ? AppColors.primary
                      : Colors.grey.shade400,
              width: selection != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: detail == null
                    ? const SizedBox(
                        height: 36,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${detail.calories.round()} kcal · ${detail.proteinG.round()}g P · ${detail.carbsG.round()}g C · ${detail.fatG.round()}g F',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => vm.setMealPreference(recipeId, true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: selection == true
                        ? AppColors.primary
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.thumb_up_rounded,
                    size: 18,
                    color: selection == true ? Colors.white : Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => vm.setMealPreference(recipeId, false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: selection == false
                        ? Colors.grey.shade500
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.thumb_down_rounded,
                    size: 18,
                    color: selection == false ? Colors.white : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required String unit,
    required bool isDecimal,
    required ValueChanged<String> onChanged,
    String? initialValue,
  }) {
    if (initialValue != null && _textController.text.isEmpty) {
      _textController.text = initialValue;
    }

    return Center(
      child: SizedBox(
        width: 220,
        child: TextField(
          controller: _textController,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(isDecimal ? RegExp(r'[\d.]') : RegExp(r'\d')),
          ],
          onChanged: onChanged,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(fontSize: 32, color: Colors.grey.shade300, fontWeight: FontWeight.bold),
            suffix: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                unit,
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2.5),
            ),
            filled: false,
          ),
          autofocus: true,
        ),
      ),
    );
  }

  Widget _buildFooter(OnboardingSurveyViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          if (!vm.isFirstStep)
            OutlinedButton(
              onPressed: vm.isLoading ? null : _onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          if (!vm.isFirstStep) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: (vm.canProceed && !vm.isLoading) ? _onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: vm.canProceed ? 2 : 0,
              ),
              child: vm.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      vm.isLastStep ? 'Complete' : 'Next',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryWithOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: selected ? Colors.white : AppColors.textSecondary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CompactOptionCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.textSecondary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
