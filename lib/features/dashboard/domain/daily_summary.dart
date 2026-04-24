class DailySummary {
  const DailySummary({
    required this.dayId,
    required this.totalCalories,
    required this.mealCount,
    required this.lastMealAtIso,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFats = 0,
  });

  final String dayId;
  final int totalCalories;
  final int mealCount;
  final String lastMealAtIso;
  final int totalProtein;
  final int totalCarbs;
  final int totalFats;

  String progressLabel(int targetCalories) => '$totalCalories / $targetCalories kcal';

  static DailySummary fromMap(String dayId, Map<String, dynamic> map) {
    return DailySummary(
      dayId: dayId,
      totalCalories: (map['totalCalories'] as num?)?.toInt() ?? 0,
      mealCount: (map['mealCount'] as num?)?.toInt() ?? 0,
      lastMealAtIso: (map['lastMealAtIso'] ?? map['lastMealAt'] ?? '') as String,
      totalProtein: (map['totalProtein'] as num?)?.toInt() ?? 0,
      totalCarbs: (map['totalCarbs'] as num?)?.toInt() ?? 0,
      totalFats: (map['totalFats'] as num?)?.toInt() ?? 0,
    );
  }
}
