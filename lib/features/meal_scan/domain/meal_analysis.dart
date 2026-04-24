class DetectedFoodItem {
  const DetectedFoodItem({
    required this.name,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  factory DetectedFoodItem.fromMap(Map<String, dynamic> map) {
    return DetectedFoodItem(
      name: (map['name'] as String?) ?? 'Unknown',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toInt() ?? 0,
      carbs: (map['carbs'] as num?)?.toInt() ?? 0,
      fat: (map['fat'] as num?)?.toInt() ?? 0,
    );
  }
}

class MealAnalysis {
  const MealAnalysis({
    required this.mealId,
    required this.totalCalories,
    required this.healthLabel,
    required this.suggestions,
    this.detectedItems = const [],
    this.imageUrl,
  });

  final String mealId;
  final int totalCalories;
  final String healthLabel;
  final List<String> suggestions;
  final List<DetectedFoodItem> detectedItems;
  final String? imageUrl;

  factory MealAnalysis.fromMap(Map<String, dynamic> map) {
    return MealAnalysis(
      mealId: (map['id'] ?? map['mealId'] ?? '') as String,
      totalCalories: (map['totalCalories'] as num?)?.toInt() ?? 0,
      healthLabel: (map['healthLabel'] as String?) ?? 'moderate',
      suggestions: (map['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      detectedItems: (map['detectedItems'] as List<dynamic>?)
              ?.map((e) => DetectedFoodItem.fromMap(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
