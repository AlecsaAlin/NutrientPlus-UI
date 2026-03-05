import '../../../core/base/base_viewmodel.dart';
import '../../../core/repositories/user_repository.dart';

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
  int? _goalTimeline; 

  int _currentStepIndex = 0;

  String? get goalType => _goalType;
  String? get gender => _gender;
  int? get age => _age;
  double? get height => _height;
  double? get currentWeight => _currentWeight;
  double? get goalWeight => _goalWeight;
  String? get activityLevel => _activityLevel;
  int? get preferredMealsPerDay => _preferredMealsPerDay;
  int? get maxCookTime => _maxCookTime;
  int? get goalTimeline => _goalTimeline;
  int get currentStepIndex => _currentStepIndex;

  static const List<SurveyStep> _allSteps = [
    SurveyStep(
      question: "What's your main goal?",
      subtitle: "We'll personalize your meal plan around it",
      type: SurveyStepType.cardSelection,
      field: 'goalType',
    ),
    SurveyStep(
      question: "When do you want to reach it?",
      subtitle: "Set a realistic timeline",
      type: SurveyStepType.cardSelection,
      field: 'goalTimeline',
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
      case 'goalTimeline':
        return _goalTimeline != null;
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
      default:
        return false;
    }
  }

  void setGoalType(String value) {
    _goalType = value;
    notifyListeners();
  }

  void setGoalTimeline(int value) {
    _goalTimeline = value;
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

  void nextStep() {
    if (_currentStepIndex < totalSteps - 1) {
      _currentStepIndex++;
      clearError();
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      clearError();
      notifyListeners();
    }
  }

  Future<bool> submit() async {
    setLoading(true);
    clearError();

    try {
      final result = await _userRepository.updateProfile(
        goalType: _goalType,
        goalTimeline: _goalTimeline,
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

      setLoading(false);

      if (result.success) {
        return true;
      } else {
        setError(result.error ?? 'Failed to save profile');
        return false;
      }
    } catch (e) {
      setLoading(false);
      setError('Connection error: $e');
      return false;
    }
  }
}
