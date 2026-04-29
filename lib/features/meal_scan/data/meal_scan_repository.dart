import 'package:image_picker/image_picker.dart';
import 'package:mealmitra/features/meal_scan/data/ai_food_analysis_service.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

abstract class MealScanRepository {
  Future<MealAnalysis> analyzeMeal({
    required String uid,
    required XFile imageFile,
    required String mealType,
  });

  Future<void> saveMeal({required String uid, required MealAnalysis analysis});

  Future<void> deleteMeal(String id);
}

class LocalMealScanRepository implements MealScanRepository {
  LocalMealScanRepository(this._foodAnalysisService);

  final AiFoodAnalysisService _foodAnalysisService;

  @override
  Future<MealAnalysis> analyzeMeal({
    required String uid,
    required XFile imageFile,
    required String mealType,
  }) async {
    final mealId = DateTime.now().millisecondsSinceEpoch.toString();
    final capturedAtIso = DateTime.now().toIso8601String();

    try {
      return await _foodAnalysisService.analyzeMealImage(
        mealId: mealId,
        mealType: mealType,
        capturedAtIso: capturedAtIso,
        imageFile: imageFile,
      );
    } catch (error) {
      return MealAnalysis(
        mealId: mealId,
        mealType: mealType,
        capturedAtIso: capturedAtIso,
        totalCalories: 0,
        healthLabel: 'moderate',
        imageUrl: imageFile.path,
        suggestions: [
          'AI analysis failed: $error',
          'Try a clearer top-down photo or add foods manually.',
        ],
      );
    }
  }

  @override
  Future<void> saveMeal({
    required String uid,
    required MealAnalysis analysis,
  }) async {
    if (analysis.detectedItems.isEmpty) {
      throw Exception('Add at least one food item before logging this meal.');
    }
  }

  @override
  Future<void> deleteMeal(String id) async {}
}
