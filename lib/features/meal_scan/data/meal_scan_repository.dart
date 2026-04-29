import 'package:image_picker/image_picker.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
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
  LocalMealScanRepository(ApiClient apiClient);

  @override
  Future<MealAnalysis> analyzeMeal({
    required String uid,
    required XFile imageFile,
    required String mealType,
  }) async {
    final mealId = DateTime.now().millisecondsSinceEpoch.toString();
    return MealAnalysis(
      mealId: mealId,
      mealType: mealType,
      capturedAtIso: DateTime.now().toIso8601String(),
      totalCalories: 0,
      healthLabel: 'moderate',
      imageUrl: imageFile.path,
      suggestions: const [
        'Add the visible foods from the catalog to calculate this meal.',
      ],
    );
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
