class DetectedFoodItem {
  const DetectedFoodItem({
    required this.name,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.quantity = 1.0,
    this.unit = 'serving',
  });

  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final double quantity;
  final String unit;

  factory DetectedFoodItem.fromMap(Map<String, dynamic> map) {
    return DetectedFoodItem(
      name: (map['name'] as String?) ?? 'Unknown',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toInt() ?? 0,
      carbs: (map['carbs'] as num?)?.toInt() ?? 0,
      fat: (map['fat'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: (map['unit'] as String?) ?? 'serving',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'quantity': quantity,
      'unit': unit,
    };
  }

  DetectedFoodItem copyWith({
    String? name,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    double? quantity,
    String? unit,
  }) {
    return DetectedFoodItem(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
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

  Map<String, dynamic> toMap() {
    return {
      'id': mealId,
      'totalCalories': totalCalories,
      'healthLabel': healthLabel,
      'suggestions': suggestions,
      'detectedItems': detectedItems.map((e) => e.toMap()).toList(),
      'imageUrl': imageUrl,
    };
  }

  MealAnalysis copyWith({
    String? mealId,
    int? totalCalories,
    String? healthLabel,
    List<String>? suggestions,
    List<DetectedFoodItem>? detectedItems,
    String? imageUrl,
  }) {
    return MealAnalysis(
      mealId: mealId ?? this.mealId,
      totalCalories: totalCalories ?? this.totalCalories,
      healthLabel: healthLabel ?? this.healthLabel,
      suggestions: suggestions ?? this.suggestions,
      detectedItems: detectedItems ?? this.detectedItems,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
