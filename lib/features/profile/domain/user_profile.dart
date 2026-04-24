enum ProfileGoal { lose, maintain, gain }
enum ActivityLevel { low, moderate, high }

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activityLevel,
    required this.dailyCalorieTarget,
    this.healthConditions = const [],
  });

  final String uid;
  final String displayName;
  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final ProfileGoal goal;
  final ActivityLevel activityLevel;
  final int dailyCalorieTarget;
  final List<String> healthConditions;

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'gender': gender,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'goal': goal.name,
        'activityLevel': activityLevel.name,
        'dailyCalorieTarget': dailyCalorieTarget,
        'healthConditions': healthConditions.join(','),
      };

  static UserProfile fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      displayName: (map['displayName'] as String?) ?? '',
      gender: (map['gender'] as String?) ?? 'Male',
      age: (map['age'] as num?)?.toInt() ?? 0,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 0,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
      goal: _parseGoal(map['goal']),
      activityLevel: _parseActivity(map['activityLevel']),
      dailyCalorieTarget: (map['dailyCalorieTarget'] as num?)?.toInt() ?? 0,
      healthConditions: _parseHealthConditions(map['healthConditions']),
    );
  }

  static ProfileGoal _parseGoal(dynamic value) {
    if (value is String) {
      return ProfileGoal.values.where((g) => g.name == value).firstOrNull ?? ProfileGoal.lose;
    }
    return ProfileGoal.lose;
  }

  static ActivityLevel _parseActivity(dynamic value) {
    if (value is String) {
      return ActivityLevel.values.where((a) => a.name == value).firstOrNull ?? ActivityLevel.moderate;
    }
    return ActivityLevel.moderate;
  }

  static List<String> _parseHealthConditions(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    ProfileGoal? goal,
    ActivityLevel? activityLevel,
    int? dailyCalorieTarget,
    List<String>? healthConditions,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      healthConditions: healthConditions ?? this.healthConditions,
    );
  }
}
