import 'package:image_picker/image_picker.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

abstract class MealScanRepository {
  Future<MealAnalysis> analyzeMeal({
    required String uid,
    required XFile imageFile,
    required String mealType,
  });

  Future<void> deleteMeal(String id);
}

class LocalMealScanRepository implements MealScanRepository {
  LocalMealScanRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<MealAnalysis> analyzeMeal({
    required String uid,
    required XFile imageFile,
    required String mealType,
  }) async {
    final response = await _apiClient.postMultipart(
      '/meals/analyze',
      fileField: 'image',
      fileBytes: await imageFile.readAsBytes(),
      fileName: imageFile.name,
      fields: {
        'mealType': mealType,
      },
    );

    return MealAnalysis.fromMap(response);
  }

  @override
  Future<void> deleteMeal(String id) async {
    await _apiClient.delete('/meals/$id');
  }
}
