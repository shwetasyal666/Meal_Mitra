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

  EvolutionData({
    this.weightHistory = const [],
    this.calorieHistory = const [],
  });

  factory EvolutionData.fromMap(Map<String, dynamic> map) {
    return EvolutionData(
      weightHistory: (map['weightHistory'] as List?)
          ?.map((e) => WeightPoint.fromMap(e))
          .toList() ?? [],
      calorieHistory: (map['calorieHistory'] as List?)
          ?.map((e) => CaloriePoint.fromMap(e))
          .toList() ?? [],
    );
  }
}
