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

class EvolutionData {
  final List<WeightPoint> weightHistory;
  final List<CaloriePoint> calorieHistory;
  final int loggedMealCount;

  EvolutionData({
    this.weightHistory = const [],
    this.calorieHistory = const [],
    this.loggedMealCount = 0,
  });

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
