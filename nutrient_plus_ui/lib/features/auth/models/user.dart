class User {
  final int id;
  final String email;
  final String username;
  final DateTime createdAt;
  final double? currentWeight;
  final double? goalWeight;
  final String? gender;
  final String? profileImagePath;
  final double? height;
  final int? age;
  final String? activityLevel;
  final String? goalType;
  final int? preferredMealsPerDay;
  final int? maxCookTime;
  final String? explorationPreference;
  final List<String> excludedIngredients;
  final List<String> likedIngredients;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.createdAt,
    this.currentWeight,
    this.goalWeight,
    this.gender,
    this.profileImagePath,
    this.height,
    this.age,
    this.activityLevel,
    this.goalType,
    this.preferredMealsPerDay,
    this.maxCookTime,
    this.explorationPreference,
    this.excludedIngredients = const [],
    this.likedIngredients = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      createdAt: DateTime.parse(json['created_at']),
      currentWeight: json['current_weight']?.toDouble(),
      goalWeight: json['goal_weight']?.toDouble(),
      gender: json['gender'],
      profileImagePath: json['profile_image_path'],
      height: json['height']?.toDouble(),
      age: json['age'],
      activityLevel: json['activity_level'],
      goalType: json['goal_type'],
      preferredMealsPerDay: json['preferred_meals_per_day'],
      maxCookTime: json['max_cook_time'],
      explorationPreference: json['exploration_preference'],
      excludedIngredients: (json['excluded_ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      likedIngredients: (json['liked_ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'created_at': createdAt.toIso8601String(),
      'current_weight': currentWeight,
      'goal_weight': goalWeight,
      'gender': gender,
      'profile_image_path': profileImagePath,
      'height': height,
      'age': age,
      'activity_level': activityLevel,
      'goal_type': goalType,
      'preferred_meals_per_day': preferredMealsPerDay,
      'max_cook_time': maxCookTime,
      'exploration_preference': explorationPreference,
      'excluded_ingredients': excludedIngredients,
      'liked_ingredients': likedIngredients,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? username,
    DateTime? createdAt,
    double? currentWeight,
    double? goalWeight,
    String? gender,
    String? profileImagePath,
    double? height,
    int? age,
    String? activityLevel,
    String? goalType,
    int? preferredMealsPerDay,
    int? maxCookTime,
    bool clearMaxCookTime = false,
    String? explorationPreference,
    List<String>? excludedIngredients,
    List<String>? likedIngredients,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      currentWeight: currentWeight ?? this.currentWeight,
      goalWeight: goalWeight ?? this.goalWeight,
      gender: gender ?? this.gender,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      height: height ?? this.height,
      age: age ?? this.age,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      preferredMealsPerDay: preferredMealsPerDay ?? this.preferredMealsPerDay,
      maxCookTime: clearMaxCookTime ? null : (maxCookTime ?? this.maxCookTime),
      explorationPreference: explorationPreference ?? this.explorationPreference,
      excludedIngredients: excludedIngredients ?? this.excludedIngredients,
      likedIngredients: likedIngredients ?? this.likedIngredients,
    );
  }
}
