import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mealmitra/core/services/cloudinary_upload_service.dart';
import 'package:mealmitra/features/meal_scan/data/ai_food_analysis_service.dart';
import 'package:mealmitra/features/meal_scan/data/meal_scan_repository.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

class FirebaseMealRepository implements MealScanRepository {
  FirebaseMealRepository(
    this._cloudinaryUploadService,
    this._foodAnalysisService,
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryUploadService _cloudinaryUploadService;
  final AiFoodAnalysisService _foodAnalysisService;

  @override
  Future<MealAnalysis> analyzeMeal({
    required String uid,
    required XFile imageFile,
    required String mealType,
  }) async {
    final mealId = DateTime.now().millisecondsSinceEpoch.toString();
    final capturedAtIso = DateTime.now().toIso8601String();
    final imageUrl = await _cloudinaryUploadService.uploadMealImage(
      uid: uid,
      mealId: mealId,
      imageFile: imageFile,
    );

    try {
      return await _foodAnalysisService.analyzeMealImage(
        mealId: mealId,
        mealType: mealType,
        capturedAtIso: capturedAtIso,
        imageFile: imageFile,
        imageUrl: imageUrl,
      );
    } catch (error) {
      return MealAnalysis(
        mealId: mealId,
        mealType: mealType,
        capturedAtIso: capturedAtIso,
        totalCalories: 0,
        healthLabel: 'moderate',
        imageUrl: imageUrl,
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

    final data = _toFirestoreMap(analysis);
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(analysis.mealId)
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteMeal(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No authenticated Firebase user found.');
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(id)
        .delete();
  }

  Map<String, dynamic> _toFirestoreMap(MealAnalysis analysis) {
    final totals = _macroTotals(analysis.detectedItems);
    final totalCalories = totals['totalCalories']!;
    final healthLabel = _healthLabel(totalCalories);

    return {
      'id': analysis.mealId,
      'mealId': analysis.mealId,
      'mealType': analysis.mealType,
      'imageUrl': analysis.imageUrl ?? '',
      'capturedAt': analysis.capturedAtIso ?? DateTime.now().toIso8601String(),
      'totalCalories': totalCalories,
      'protein': totals['protein'],
      'carbs': totals['carbs'],
      'fat': totals['fat'],
      'healthLabel': healthLabel,
      'suggestions': _suggestions(analysis.mealType, totalCalories, totals),
      'detectedItems': analysis.detectedItems
          .map((item) => item.toMap())
          .toList(),
      'analysisSource': analysis.detectedItems.isEmpty
          ? 'manual_catalog'
          : 'ai_vision_reviewed',
    };
  }

  Map<String, int> _macroTotals(List<DetectedFoodItem> items) {
    var totalCalories = 0;
    var protein = 0;
    var carbs = 0;
    var fat = 0;

    for (final item in items) {
      totalCalories += (item.calories * item.quantity).round();
      protein += (item.protein * item.quantity).round();
      carbs += (item.carbs * item.quantity).round();
      fat += (item.fat * item.quantity).round();
    }

    return {
      'totalCalories': totalCalories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  String _healthLabel(int calories) {
    if (calories >= 800) return 'avoid';
    if (calories <= 450) return 'healthy';
    return 'moderate';
  }

  List<String> _suggestions(
    String mealType,
    int totalCalories,
    Map<String, int> totals,
  ) {
    final suggestions = <String>[
      'Review the selected foods and portions before logging this $mealType.',
    ];

    if ((totals['protein'] ?? 0) < 15) {
      suggestions.add(
        'Protein looks light. Add dal, paneer, eggs, curd, tofu, or lean meat if it matches the meal.',
      );
    }

    if (totalCalories >= 800) {
      suggestions.add(
        'This is a calorie-dense meal. Reduce portions or balance it with lighter meals later.',
      );
    } else {
      suggestions.add(
        'This estimate is based on the foods and portions you selected from the catalog.',
      );
    }

    return suggestions.take(3).toList();
  }
}
