import 'dart:math';
import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/services/api_service.dart' show ApiService;
import '../../meal_plan/models/meal_models.dart' show RecipeDetail;

enum SurveyStepType { cardSelection, numberInput, chipRow }

class SurveyStep {
  final String question;
  final String? subtitle;
  final SurveyStepType type;
  final String field;

  const SurveyStep({
    required this.question,
    this.subtitle,
    required this.type,
    required this.field,
  });
}

class OnboardingSurveyViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  OnboardingSurveyViewModel({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  String? _goalType;
  String? _gender;
  int? _age;
  double? _height;
  double? _currentWeight;
  double? _goalWeight;
  String? _activityLevel;
  int? _preferredMealsPerDay;
  int? _maxCookTime;

  int _currentStepIndex = 0;

  static const List<int> _coldStartMealIds = [
    45809, 27208, 39087, 35813, 67256, 54257, 22782, 32204,
    25690, 69173, 73440, 68955, 33919, 82102, 25885, 85629,
  ];

  List<int> _mealPreferenceIds = [];
  List<RecipeDetail?> _mealPreferenceDetails = [];
  Map<int, bool> _mealPreferenceSelections = {};
  bool _isMealPreferencesLoading = false;

  String? get goalType => _goalType;
  String? get gender => _gender;
  int? get age => _age;
  double? get height => _height;
  double? get currentWeight => _currentWeight;
  double? get goalWeight => _goalWeight;
  String? get activityLevel => _activityLevel;
  int? get preferredMealsPerDay => _preferredMealsPerDay;
  int? get maxCookTime => _maxCookTime;
  int get currentStepIndex => _currentStepIndex;

  List<int> get mealPreferenceIds => _mealPreferenceIds;
  List<RecipeDetail?> get mealPreferenceDetails => _mealPreferenceDetails;
  Map<int, bool> get mealPreferenceSelections => _mealPreferenceSelections;
  bool get isMealPreferencesLoading => _isMealPreferencesLoading;

  static const List<SurveyStep> _allSteps = [
    SurveyStep(
      question: "What's your main goal?",
      subtitle: "We'll personalize your meal plan around it",
      type: SurveyStepType.cardSelection,
      field: 'goalType',
    ),
    SurveyStep(
      question: "What's your gender?",
      subtitle: "Used to calculate your nutritional needs",
      type: SurveyStepType.cardSelection,
      field: 'gender',
    ),
    SurveyStep(
      question: "How old are you?",
      subtitle: "Age helps us fine-tune your calorie targets",
      type: SurveyStepType.numberInput,
      field: 'age',
    ),
    SurveyStep(
      question: "What's your height?",
      subtitle: "Enter your height in centimetres",
      type: SurveyStepType.numberInput,
      field: 'height',
    ),
    SurveyStep(
      question: "What's your current weight?",
      subtitle: "Enter your weight in kilograms",
      type: SurveyStepType.numberInput,
      field: 'currentWeight',
    ),
    SurveyStep(
      question: "What's your goal weight?",
      subtitle: "Enter your target weight in kilograms",
      type: SurveyStepType.numberInput,
      field: 'goalWeight',
    ),
    SurveyStep(
      question: "How active are you?",
      subtitle: "Your typical week of physical activity",
      type: SurveyStepType.cardSelection,
      field: 'activityLevel',
    ),
    SurveyStep(
      question: "How many meals per day?",
      subtitle: "We'll split your calories accordingly",
      type: SurveyStepType.chipRow,
      field: 'preferredMealsPerDay',
    ),
    SurveyStep(
      question: "How long can you spend cooking?",
      subtitle: "We'll suggest recipes that fit your schedule",
      type: SurveyStepType.cardSelection,
      field: 'maxCookTime',
    ),
    SurveyStep(
      question: "Which of these would you eat?",
      subtitle: "Helps us personalize your recommendations from day one",
      type: SurveyStepType.cardSelection,
      field: 'mealPreferences',
    ),
  ];

  List<SurveyStep> get activeSteps {
    final skipGoalWeight = _goalType == 'maintain_weight' || _goalType == 'eat_healthier';
    return _allSteps.where((s) => !(s.field == 'goalWeight' && skipGoalWeight)).toList();
  }

  SurveyStep get currentStep => activeSteps[_currentStepIndex];
  int get totalSteps => activeSteps.length;
  bool get isLastStep => _currentStepIndex == totalSteps - 1;
  bool get isFirstStep => _currentStepIndex == 0;

  bool get canProceed {
    switch (currentStep.field) {
      case 'goalType':
        return _goalType != null;
      case 'gender':
        return _gender != null;
      case 'age':
        return _age != null && _age! > 0;
      case 'height':
        return _height != null && _height! > 0;
      case 'currentWeight':
        return _currentWeight != null && _currentWeight! > 0;
      case 'goalWeight':
        return _goalWeight != null && _goalWeight! > 0;
      case 'activityLevel':
        return _activityLevel != null;
      case 'preferredMealsPerDay':
        return _preferredMealsPerDay != null;
      case 'maxCookTime':
        return true;
      case 'mealPreferences':
        return !_isMealPreferencesLoading &&
            _mealPreferenceIds.isNotEmpty &&
            _mealPreferenceSelections.length == _mealPreferenceIds.length;
      default:
        return false;
    }
  }

  void setGoalType(String value) {
    _goalType = value;
    notifyListeners();
  }

  void setGender(String value) {
    _gender = value;
    notifyListeners();
  }

  void setAge(int? value) {
    _age = value;
    notifyListeners();
  }

  void setHeight(double? value) {
    _height = value;
    notifyListeners();
  }

  void setCurrentWeight(double? value) {
    _currentWeight = value;
    notifyListeners();
  }

  void setGoalWeight(double? value) {
    _goalWeight = value;
    notifyListeners();
  }

  void setActivityLevel(String value) {
    _activityLevel = value;
    notifyListeners();
  }

  void setPreferredMealsPerDay(int value) {
    _preferredMealsPerDay = value;
    notifyListeners();
  }

  void setMaxCookTime(int? value) {
    _maxCookTime = value;
    notifyListeners();
  }

  void setMealPreference(int recipeId, bool liked) {
    _mealPreferenceSelections[recipeId] = liked;
    notifyListeners();
  }

  Future<void> loadMealPreferences() async {
    if (_mealPreferenceIds.isNotEmpty) return;
    _isMealPreferencesLoading = true;
    notifyListeners();

    final shuffled = List<int>.from(_coldStartMealIds)..shuffle(Random());
    _mealPreferenceIds = shuffled.take(5).toList();
    _mealPreferenceDetails = List<RecipeDetail?>.filled(5, null);

    await Future.wait(
      _mealPreferenceIds.asMap().entries.map((entry) async {
        final detail = await ApiService.getRecipeById(recipeId: entry.value);
        _mealPreferenceDetails[entry.key] = detail;
        notifyListeners();
      }),
    );

    _isMealPreferencesLoading = false;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStepIndex < totalSteps - 1) {
      _currentStepIndex++;
      clearError();
      notifyListeners();
      if (currentStep.field == 'mealPreferences') {
        loadMealPreferences();
      }
    }
  }

  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      clearError();
      notifyListeners();
      if (currentStep.field == 'mealPreferences') {
        loadMealPreferences();
      }
    }
  }

  Future<bool> submit() async {
    setLoading(true);
    clearError();

    try {
      final result = await _userRepository.updateProfile(
        goalType: _goalType,
        gender: _gender,
        age: _age,
        height: _height,
        currentWeight: _currentWeight,
        goalWeight: _goalWeight,
        activityLevel: _activityLevel,
        preferredMealsPerDay: _preferredMealsPerDay,
        maxCookTime: _maxCookTime,
        clearMaxCookTime: _maxCookTime == null,
      );

      if (!result.success) {
        setLoading(false);
        setError(result.error ?? 'Failed to save profile');
        return false;
      }

      await Future.wait(
        _mealPreferenceSelections.entries
            .where((e) => e.value == true)
            .map((e) => ApiService.rateMeal(recipeId: e.key)),
      );

      setLoading(false);
      return true;
    } catch (e) {
      setLoading(false);
      setError('Connection error: $e');
      return false;
    }
  }
}
