import 'dart:io';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

class MealScanRepository {
  MealScanRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<MealAnalysis> analyzeMeal({
    required String uid,
    required File imageFile,
    required String mealType,
  }) async {
    final response = await _apiClient.postMultipart(
      '/meals/analyze',
      fileField: 'image',
      filePath: imageFile.path,
      fields: {
        'mealType': mealType,
      },
    );

    return MealAnalysis.fromMap(response);
  }

  Future<void> deleteMeal(String id) async {
    await _apiClient.delete('/meals/$id');
  }
}
