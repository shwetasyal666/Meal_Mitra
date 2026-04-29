import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mealmitra/features/meal_scan/data/local_food_catalog.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

final onDeviceFoodAnalysisServiceProvider = Provider((ref) {
  final labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.55),
  );
  ref.onDispose(labeler.close);
  return OnDeviceFoodAnalysisService(labeler);
});

class OnDeviceFoodAnalysisService {
  OnDeviceFoodAnalysisService(this._labeler);

  final ImageLabeler _labeler;

  Future<MealAnalysisDraft> analyze({
    required XFile imageFile,
    required String mealType,
  }) async {
    final labels = await _labeler
        .processImage(InputImage.fromFilePath(imageFile.path))
        .timeout(const Duration(seconds: 10));

    final matches = _matchCatalog(labels);
    final fallback = _fallbackEntriesForMealType(mealType);
    final resolvedEntries = matches.isEmpty ? fallback : matches;
    final detectedItems = resolvedEntries
        .take(3)
        .map(
          (entry) => DetectedFoodItem(
            name: entry.name,
            calories: entry.calories,
            protein: entry.protein,
            carbs: entry.carbs,
            fat: entry.fat,
            quantity: 1,
            unit: entry.unit,
          ),
        )
        .toList();

    final totalCalories = detectedItems.fold<int>(
      0,
      (sum, item) => sum + item.calories,
    );
    final healthLabel = _resolveHealthLabel(resolvedEntries);

    return MealAnalysisDraft(
      totalCalories: totalCalories,
      healthLabel: healthLabel,
      detectedItems: detectedItems,
      suggestions: _buildSuggestions(
        mealType: mealType,
        totalCalories: totalCalories,
        healthLabel: healthLabel,
        detectedItems: detectedItems,
        labels: labels,
        usedFallback: matches.isEmpty,
      ),
    );
  }

  List<LocalFoodKnowledgeEntry> _matchCatalog(List<ImageLabel> labels) {
    final scoredEntries = <String, _ScoredEntry>{};

    for (final label in labels) {
      final normalizedLabel = label.label.toLowerCase().trim();
      for (final entry in localFoodCatalog) {
        final keyword = entry.keywords.cast<String?>().firstWhere(
              (candidate) =>
                  candidate != null &&
                  candidate.isNotEmpty &&
                  (normalizedLabel.contains(candidate) ||
                      candidate.contains(normalizedLabel)),
              orElse: () => null,
            );

        if (keyword == null) continue;

        final score = label.confidence + (keyword.length / 100);
        final previous = scoredEntries[entry.name];
        if (previous == null || score > previous.score) {
          scoredEntries[entry.name] = _ScoredEntry(entry: entry, score: score);
        }
      }
    }

    final ranked = scoredEntries.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return ranked.map((item) => item.entry).toList();
  }

  List<LocalFoodKnowledgeEntry> _fallbackEntriesForMealType(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return const [
          LocalFoodKnowledgeEntry(
            name: 'Balanced Breakfast Plate',
            keywords: ['breakfast'],
            calories: 320,
            protein: 14,
            carbs: 38,
            fat: 11,
            healthLabel: 'healthy',
            unit: 'plate',
          ),
        ];
      case 'snack':
        return const [
          LocalFoodKnowledgeEntry(
            name: 'Snack Portion',
            keywords: ['snack'],
            calories: 210,
            protein: 6,
            carbs: 24,
            fat: 9,
            healthLabel: 'moderate',
            unit: 'portion',
          ),
        ];
      case 'dinner':
        return const [
          LocalFoodKnowledgeEntry(
            name: 'Dinner Plate',
            keywords: ['dinner'],
            calories: 430,
            protein: 20,
            carbs: 42,
            fat: 18,
            healthLabel: 'moderate',
            unit: 'plate',
          ),
        ];
      default:
        return const [
          LocalFoodKnowledgeEntry(
            name: 'Lunch Plate',
            keywords: ['lunch'],
            calories: 410,
            protein: 18,
            carbs: 44,
            fat: 16,
            healthLabel: 'moderate',
            unit: 'plate',
          ),
        ];
    }
  }

  String _resolveHealthLabel(List<LocalFoodKnowledgeEntry> entries) {
    var healthyCount = 0;
    var avoidCount = 0;

    for (final entry in entries) {
      if (entry.healthLabel == 'healthy') {
        healthyCount++;
      } else if (entry.healthLabel == 'avoid') {
        avoidCount++;
      }
    }

    if (avoidCount > 0) return 'avoid';
    if (healthyCount == entries.length) return 'healthy';
    return 'moderate';
  }

  List<String> _buildSuggestions({
    required String mealType,
    required int totalCalories,
    required String healthLabel,
    required List<DetectedFoodItem> detectedItems,
    required List<ImageLabel> labels,
    required bool usedFallback,
  }) {
    final suggestions = <String>[];
    final protein = detectedItems.fold<int>(0, (sum, item) => sum + item.protein);
    final carbs = detectedItems.fold<int>(0, (sum, item) => sum + item.carbs);

    if (usedFallback) {
      suggestions.add(
        'We used on-device portion estimates for this $mealType. Review the detected items if the portion looks off.',
      );
    } else {
      suggestions.add(
        'Analysis ran fully on-device using ML Kit labels, so it stays free, quick, and available even under heavy usage.',
      );
    }

    if (healthLabel == 'avoid') {
      suggestions.add(
        'This looks energy-dense. Try pairing it with vegetables or trimming fried and sugary sides next time.',
      );
    } else if (healthLabel == 'healthy') {
      suggestions.add(
        'This is a strong pick. Keep protein and fiber in the mix to stay fuller for longer.',
      );
    } else {
      suggestions.add(
        'This meal looks workable. A little more protein or vegetables would improve balance.',
      );
    }

    if (protein < 15) {
      suggestions.add('Protein looks light. Consider adding yogurt, dal, eggs, paneer, or lean meat.');
    }
    if (carbs > 55 || totalCalories > 500) {
      suggestions.add('Portion size may be the main driver here. Use the edit flow to fine-tune servings.');
    }
    if (labels.isEmpty) {
      suggestions.add('The image labels were limited, so the estimate leaned on meal-type defaults.');
    }

    return suggestions.take(3).toList();
  }
}

class MealAnalysisDraft {
  const MealAnalysisDraft({
    required this.totalCalories,
    required this.healthLabel,
    required this.suggestions,
    required this.detectedItems,
  });

  final int totalCalories;
  final String healthLabel;
  final List<String> suggestions;
  final List<DetectedFoodItem> detectedItems;

  int get protein => detectedItems.fold<int>(0, (sum, item) => sum + item.protein);
  int get carbs => detectedItems.fold<int>(0, (sum, item) => sum + item.carbs);
  int get fat => detectedItems.fold<int>(0, (sum, item) => sum + item.fat);
}

class _ScoredEntry {
  const _ScoredEntry({
    required this.entry,
    required this.score,
  });

  final LocalFoodKnowledgeEntry entry;
  final double score;
}
