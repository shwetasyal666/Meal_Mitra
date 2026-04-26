import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mealmitra/core/config/app_config.dart';
import 'package:mealmitra/features/meal_scan/data/meal_scan_repository.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FirebaseMealRepository implements MealScanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<MealAnalysis> analyzeMeal({
    required String uid,
    required File imageFile,
    required String mealType,
  }) async {
    // 1. Upload to Cloudinary
    final imageUrl = await _uploadToCloudinary(imageFile);

    // 2. Client-side AI Analysis
    final aiResult = await _analyzeImageWithGemini(
      imageFile,
      mealType,
      imageUrl,
    );

    // 3. Save to Firestore
    final data = aiResult.toMap();
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(aiResult.mealId)
        .set(data);

    return aiResult;
  }

  @override
  Future<void> deleteMeal(String id) async {
    // For deleting, we would ideally need the current user's UID to properly locate the doc
    // However, since history deletion might happen contextually, we assume it's the current user
    // A better approach in Firebase is passing the UID, but we'll try to find it or query it if global
    throw UnimplementedError('Pass UID via provider instead');
  }

  Future<String> _uploadToCloudinary(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody);
      return json['secure_url'];
    } else {
      print('Failed to upload image: $responseBody');
      throw Exception('Failed to upload image: $responseBody');
    }
  }

  Future<MealAnalysis> _analyzeImageWithGemini(
    File file,
    String mealType,
    String imageUrl,
  ) async {
    final apiKey = AppConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

    final bytes = await file.readAsBytes();
    final prompt =
        '''
Analyze this meal for $mealType. Provide estimated details. 
Return ONLY valid JSON matching this schema:
{
  "totalCalories": number,
  "healthLabel": "healthy" | "moderate" | "avoid",
  "suggestions": ["string"],
  "detectedItems": [
    {
      "name": "string",
      "calories": number,
      "protein": number,
      "carbs": number,
      "fat": number
    }
  ]
}
''';

    final response = await model.generateContent([
      Content.text(prompt),
      Content.data('image/jpeg', bytes),
    ]);

    String text = response.text ?? '{}';
    // Remove markdown code blocks if present
    if (text.contains('```json')) {
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
    } else if (text.contains('```')) {
      text = text.replaceAll('```', '').trim();
    }

    try {
      final json = jsonDecode(text) as Map<String, dynamic>;

      // Calculate derived macros from individual items if present
      int totalProtein = 0;
      int totalCarbs = 0;
      int totalFat = 0;

      final detectedItems = json['detectedItems'] as List<dynamic>? ?? [];
      for (var item in detectedItems) {
        totalProtein += (item['protein'] as num?)?.toInt() ?? 0;
        totalCarbs += (item['carbs'] as num?)?.toInt() ?? 0;
        totalFat += (item['fat'] as num?)?.toInt() ?? 0;
      }

      final mealId = DateTime.now().millisecondsSinceEpoch.toString();

      return MealAnalysis.fromMap({
        'id': mealId,
        'mealType': mealType,
        'imageUrl': imageUrl,
        'capturedAt': DateTime.now().toIso8601String(),
        'totalCalories': json['totalCalories'] ?? 0,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
        'healthLabel': json['healthLabel'] ?? 'moderate',
        'suggestions': json['suggestions'] ?? [],
        'detectedItems': json['detectedItems'] ?? [],
      });
    } catch (e) {
      debugPrint('Gemini parse error: $e\\nText: $text');
      throw Exception('Failed to parse AI response');
    }
  }
}
