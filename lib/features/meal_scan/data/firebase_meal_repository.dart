import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/core/services/local_file_storage_service.dart';
import 'package:mealmitra/features/meal_scan/data/meal_scan_repository.dart';
import 'package:mealmitra/features/meal_scan/data/on_device_food_analysis_service.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

class FirebaseMealRepository implements MealScanRepository {
  FirebaseMealRepository(
    this._apiClient,
    this._analysisService,
    this._localFileStorageService,
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiClient _apiClient;
  final OnDeviceFoodAnalysisService _analysisService;
  final LocalFileStorageService _localFileStorageService;

  @override
  Future<MealAnalysis> analyzeMeal({
    required String uid,
    required XFile imageFile,
    required String mealType,
  }) async {
    final mealId = DateTime.now().millisecondsSinceEpoch.toString();
    final imagePath = await _localFileStorageService.saveMealImage(
      imageFile: imageFile,
      mealId: mealId,
    );

    final data = await _loadAnalysisData(
      imageFile: imageFile,
      mealId: mealId,
      mealType: mealType,
      imagePath: imagePath,
    );
    final aiResult = MealAnalysis.fromMap(data);

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(mealId)
        .set(data);

    return aiResult;
  }

  @override
  Future<void> deleteMeal(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No authenticated Firebase user found.');
    }

    final docRef = _firestore.collection('users').doc(uid).collection('meals').doc(id);
    final existingDoc = await docRef.get();
    final imagePath = existingDoc.data()?['imageUrl'] as String?;

    await docRef.delete();
    await _localFileStorageService.deleteIfManaged(imagePath);
  }

  Future<Map<String, dynamic>> _loadAnalysisData({
    required XFile imageFile,
    required String mealId,
    required String mealType,
    required String imagePath,
  }) async {
    try {
      final draft = await _analysisService.analyze(
        imageFile: imageFile,
        mealType: mealType,
      );
      return _buildLocalAnalysisDocument(
        mealId: mealId,
        mealType: mealType,
        imagePath: imagePath,
        draft: draft,
      );
    } catch (error) {
      debugPrint('On-device analysis failed: $error');

      try {
        final response = await _apiClient.postMultipart(
          '/meals/analyze-public',
          fileField: 'image',
          fileBytes: await imageFile.readAsBytes(),
          fileName: _safeFileName(imageFile),
          fields: {'mealType': mealType},
        );
        return _normalizeBackendResponse(
          response,
          mealId: mealId,
          mealType: mealType,
          imagePath: imagePath,
        );
      } catch (backendError) {
        throw Exception(
          'Meal analysis failed on-device and via backend fallback. '
          'On-device error: $error. Backend error: $backendError',
        );
      }
    }
  }

  Map<String, dynamic> _buildLocalAnalysisDocument({
    required String mealId,
    required String mealType,
    required String imagePath,
    required MealAnalysisDraft draft,
  }) {
    return {
      'id': mealId,
      'mealId': mealId,
      'mealType': mealType,
      'imageUrl': imagePath,
      'capturedAt': DateTime.now().toIso8601String(),
      'totalCalories': draft.totalCalories,
      'protein': draft.protein,
      'carbs': draft.carbs,
      'fat': draft.fat,
      'healthLabel': draft.healthLabel,
      'suggestions': draft.suggestions,
      'detectedItems': draft.detectedItems.map((item) => item.toMap()).toList(),
      'analysisSource': 'on_device_mlkit',
    };
  }

  Map<String, dynamic> _normalizeBackendResponse(
    dynamic response, {
    required String mealId,
    required String mealType,
    required String imagePath,
  }) {
    if (response is! Map<String, dynamic>) {
      throw Exception('Invalid analysis response from backend.');
    }

    return {
      'id': mealId,
      'mealId': mealId,
      'mealType': (response['mealType'] ?? mealType).toString(),
      'imageUrl': imagePath,
      'capturedAt': (response['capturedAt'] ?? DateTime.now().toIso8601String())
          .toString(),
      'totalCalories': (response['totalCalories'] as num?)?.toInt() ?? 0,
      'protein': (response['protein'] as num?)?.toInt() ?? _sumMacro(
            List<dynamic>.from(response['detectedItems'] ?? const []),
            'protein',
          ),
      'carbs': (response['carbs'] as num?)?.toInt() ??
          _sumMacro(
            List<dynamic>.from(response['detectedItems'] ?? const []),
            'carbs',
          ),
      'fat': (response['fat'] as num?)?.toInt() ??
          _sumMacro(
            List<dynamic>.from(response['detectedItems'] ?? const []),
            'fat',
          ),
      'healthLabel': _normalizeHealthLabel(response['healthLabel']),
      'suggestions': List<String>.from(response['suggestions'] ?? const []),
      'detectedItems': List<dynamic>.from(response['detectedItems'] ?? const []),
      'analysisSource': 'backend_fallback',
    };
  }

  String _normalizeHealthLabel(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'healthy':
      case 'good':
      case 'green':
        return 'healthy';
      case 'avoid':
      case 'red':
        return 'avoid';
      default:
        return 'moderate';
    }
  }

  int _sumMacro(List<dynamic> items, String key) {
    var total = 0;
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        total += (item[key] as num?)?.toInt() ?? 0;
      }
    }
    return total;
  }

  String _safeFileName(XFile imageFile) {
    if (imageFile.name.isNotEmpty) return imageFile.name;
    final path = imageFile.path;
    if (path.isEmpty) return 'meal.jpg';
    return path.split('/').last;
  }
}
