class CalorieInfo {
  final double bmr;
  final double tdee;
  final double dailyCalories;
  final String goalType;

  CalorieInfo({
    required this.bmr,
    required this.tdee,
    required this.dailyCalories,
    required this.goalType,
  });

  factory CalorieInfo.fromJson(Map<String, dynamic> json) {
    return CalorieInfo(
      bmr: (json['bmr'] ?? 0).toDouble(),
      tdee: (json['tdee'] ?? 0).toDouble(),
      dailyCalories: (json['daily_calories'] ?? 0).toDouble(),
      goalType: json['goal_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bmr': bmr,
      'tdee': tdee,
      'daily_calories': dailyCalories,
      'goal_type': goalType,
    };
  }
}

enum ActivityLevel {
  sedentary('sedentary', 'Sedentary', 'Little or no exercise'),
  lightlyActive('lightly_active', 'Lightly Active', 'Light exercise 1-3 days/week'),
  moderatelyActive('moderately_active', 'Moderately Active', 'Moderate exercise 3-5 days/week'),
  veryActive('very_active', 'Very Active', 'Hard exercise 6-7 days/week'),
  extraActive('extra_active', 'Extra Active', 'Very hard exercise, physical job');

  final String value;
  final String label;
  final String description;

  const ActivityLevel(this.value, this.label, this.description);

  static ActivityLevel fromString(String? value) {
    return ActivityLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ActivityLevel.sedentary,
    );
  }
}

/// Goal type options for user profile
enum GoalType {
  maintain('maintain', 'Maintain Weight', 'Keep your current weight'),
  mildLoss('mild_loss', 'Mild Weight Loss', '10% calorie deficit'),
  moderateLoss('moderate_loss', 'Moderate Weight Loss', '20% calorie deficit'),
  muscleGain('muscle_gain', 'Muscle Gain', '10% calorie surplus'),
  rapidGain('rapid_gain', 'Rapid Gain', '20% calorie surplus');

  final String value;
  final String label;
  final String description;

  const GoalType(this.value, this.label, this.description);

  static GoalType fromString(String? value) {
    return GoalType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GoalType.maintain,
    );
  }
}


enum ExplorationPreference {
  conservative('conservative', 'Conservative', 'Stick to recipes you already like'),
  balanced('balanced', 'Balanced', 'Mix of familiar and new recipes'),
  adventurous('adventurous', 'Adventurous', 'Discover lots of new recipes');

  final String value;
  final String label;
  final String description;

  const ExplorationPreference(this.value, this.label, this.description);

  static ExplorationPreference fromString(String? value) {
    return ExplorationPreference.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExplorationPreference.balanced,
    );
  }
}
