import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

class MealRecord {
  const MealRecord({
    required this.id,
    required this.mealType,
    required this.totalCalories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.healthLabel,
    this.imageUrl = '',
    required this.capturedAtIso,
    this.detectedItems = const [],
    this.suggestions = const [],
  });

  final String id;
  final String mealType;
  final int totalCalories;
  final int protein;
  final int carbs;
  final int fat;
  final String healthLabel;
  final String imageUrl;
  final String capturedAtIso;
  final List<DetectedFoodItem> detectedItems;
  final List<String> suggestions;

  static MealRecord fromMap(String id, Map<String, dynamic> map) {
    return MealRecord(
      id: id,
      mealType: (map['mealType'] as String?) ?? 'meal',
      totalCalories: (map['totalCalories'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toInt() ?? 0,
      carbs: (map['carbs'] as num?)?.toInt() ?? 0,
      fat: (map['fat'] as num?)?.toInt() ?? 0,
      healthLabel: (map['healthLabel'] as String?) ?? 'moderate',
      imageUrl: (map['imageUrl'] as String?) ?? '',
      capturedAtIso: (map['capturedAt'] as String?) ?? '',
      detectedItems: (map['detectedItems'] as List?)
              ?.map((item) => DetectedFoodItem.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
      suggestions: List<String>.from(map['suggestions'] ?? const []),
    );
  }
}
