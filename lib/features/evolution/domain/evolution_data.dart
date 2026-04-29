class WeightPoint {
  final double weight;
  final DateTime date;

  WeightPoint({required this.weight, required this.date});

  factory WeightPoint.fromMap(Map<String, dynamic> map) {
    return WeightPoint(
      weight: (map['weightKg'] as num).toDouble(),
      date: DateTime.parse(map['recordedAt']),
    );
  }
}

class CaloriePoint {
  final int calories;
  final String dayId;

  CaloriePoint({required this.calories, required this.dayId});

  factory CaloriePoint.fromMap(Map<String, dynamic> map) {
    return CaloriePoint(
      calories: (map['totalCalories'] as num).toInt(),
      dayId: map['dayId'] as String,
    );
  }
}

class HealthConcernData {
  final int healthyMeals;
  final int moderateMeals;
  final int avoidMeals;
  final double averageCalories;
  final double averageProtein;
  final double averageCarbs;
  final double averageFat;
  final String dominantConcern;
  final List<MealConcernBreakdown> breakdown;

  HealthConcernData({
    this.healthyMeals = 0,
    this.moderateMeals = 0,
    this.avoidMeals = 0,
    this.averageCalories = 0,
    this.averageProtein = 0,
    this.averageCarbs = 0,
    this.averageFat = 0,
    this.dominantConcern = 'moderate',
    this.breakdown = const [],
  });

  factory HealthConcernData.fromMap(Map<String, dynamic> map) {
    final breakdownList = (map['breakdown'] as List?)
        ?.map((e) => MealConcernBreakdown.fromMap(e))
        .toList() ?? [];
    return HealthConcernData(
      healthyMeals: (map['healthyMeals'] as num?)?.toInt() ?? 0,
      moderateMeals: (map['moderateMeals'] as num?)?.toInt() ?? 0,
      avoidMeals: (map['avoidMeals'] as num?)?.toInt() ?? 0,
      averageCalories: (map['averageCalories'] as num?)?.toDouble() ?? 0,
      averageProtein: (map['averageProtein'] as num?)?.toDouble() ?? 0,
      averageCarbs: (map['averageCarbs'] as num?)?.toDouble() ?? 0,
      averageFat: (map['averageFat'] as num?)?.toDouble() ?? 0,
      dominantConcern: (map['dominantConcern'] as String?) ?? 'moderate',
      breakdown: breakdownList,
    );
  }

  int get totalMeals => healthyMeals + moderateMeals + avoidMeals;

  double get healthScore {
    if (totalMeals == 0) return 0;
    final score = ((healthyMeals * 100) + (moderateMeals * 50) + (avoidMeals * 0)) / totalMeals;
    return (score / 100).clamp(0, 1);
  }
}

class MealConcernBreakdown {
  final String date;
  final int healthy;
  final int moderate;
  final int avoid;

  MealConcernBreakdown({
    required this.date,
    this.healthy = 0,
    this.moderate = 0,
    this.avoid = 0,
  });

  factory MealConcernBreakdown.fromMap(Map<String, dynamic> map) {
    return MealConcernBreakdown(
      date: map['date'] as String,
      healthy: (map['healthy'] as num?)?.toInt() ?? 0,
      moderate: (map['moderate'] as num?)?.toInt() ?? 0,
      avoid: (map['avoid'] as num?)?.toInt() ?? 0,
    );
  }
}

class EvolutionData {
  final List<WeightPoint> weightHistory;
  final List<CaloriePoint> calorieHistory;
  final int loggedMealCount;
  final HealthConcernData healthConcernData;

  EvolutionData({
    this.weightHistory = const [],
    this.calorieHistory = const [],
    this.loggedMealCount = 0,
    HealthConcernData? healthConcernData,
  }) : healthConcernData = healthConcernData ?? HealthConcernData();

  factory EvolutionData.fromMap(Map<String, dynamic> map) {
    return EvolutionData(
      weightHistory:
          (map['weightHistory'] as List?)
              ?.map((e) => WeightPoint.fromMap(e))
              .toList() ??
          [],
      calorieHistory:
          (map['calorieHistory'] as List?)
              ?.map((e) => CaloriePoint.fromMap(e))
              .toList() ??
          [],
      loggedMealCount: (map['loggedMealCount'] as num?)?.toInt() ?? 0,
      healthConcernData: map['healthConcernData'] != null
          ? HealthConcernData.fromMap(
              Map<String, dynamic>.from(map['healthConcernData']))
          : null,
    );
  }

  int get loggedDaysCount =>
      calorieHistory.where((point) => point.calories > 0).length;

  int get totalCaloriesLogged =>
      calorieHistory.fold(0, (sum, point) => sum + point.calories);

  int get averageCaloriesPerLoggedDay {
    final loggedDays = loggedDaysCount;
    if (loggedDays == 0) return 0;
    return (totalCaloriesLogged / loggedDays).round();
  }
}
