import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:mealmitra/core/config/app_config.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/features/meal_scan/data/meal_scan_repository.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

class FirebaseMealRepository implements MealScanRepository {
  static const String _geminiModel = 'gemini-2.5-flash';

  FirebaseMealRepository(this._apiClient);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiClient _apiClient;

  @override
  Future<MealAnalysis> analyzeMeal({
    required String uid,
    required XFile imageFile,
    required String mealType,
  }) async {
    final data = await _loadAnalysisData(
      imageFile: imageFile,
      mealType: mealType,
    );
    final aiResult = MealAnalysis.fromMap(data);

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

  Future<Map<String, dynamic>> _loadAnalysisData({
    required XFile imageFile,
    required String mealType,
  }) async {
    try {
      final response = await _apiClient.postMultipart(
        '/meals/analyze-public',
        fileField: 'image',
        fileBytes: await imageFile.readAsBytes(),
        fileName: _safeFileName(imageFile),
        fields: {'mealType': mealType},
      );

      return _normalizeAnalysisResponse(response, mealType);
    } catch (error) {
      debugPrint('Backend analysis failed: $error');

      if (!_canUseDirectFallback) {
        throw Exception(
          'Meal analysis failed via backend and direct fallback is unavailable. '
          'Backend error: $error',
        );
      }

      return _analyzeDirectly(
        imageFile: imageFile,
        mealType: mealType,
        backendError: error,
      );
    }
  }

  bool get _canUseDirectFallback =>
      AppConfig.geminiApiKey.isNotEmpty &&
      AppConfig.cloudinaryCloudName.isNotEmpty &&
      AppConfig.cloudinaryUploadPreset.isNotEmpty;

  Future<Map<String, dynamic>> _analyzeDirectly({
    required XFile imageFile,
    required String mealType,
    required Object backendError,
  }) async {
    try {
      final imageUrl = await _uploadToCloudinary(imageFile);
      final geminiJson = await _generateGeminiAnalysis(
        imageFile: imageFile,
        mealType: mealType,
      );

      final detectedItems = List<dynamic>.from(
        geminiJson['detectedItems'] ?? const <dynamic>[],
      );
      final mealId = DateTime.now().millisecondsSinceEpoch.toString();

      return {
        'id': mealId,
        'mealId': mealId,
        'mealType': mealType,
        'imageUrl': imageUrl,
        'capturedAt': DateTime.now().toIso8601String(),
        'totalCalories': (geminiJson['totalCalories'] as num?)?.toInt() ?? 0,
        'protein': _sumMacro(detectedItems, 'protein'),
        'carbs': _sumMacro(detectedItems, 'carbs'),
        'fat': _sumMacro(detectedItems, 'fat'),
        'healthLabel': _normalizeHealthLabel(geminiJson['healthLabel']),
        'suggestions': List<String>.from(geminiJson['suggestions'] ?? const []),
        'detectedItems': detectedItems,
      };
    } catch (directError) {
      throw Exception(
        'Meal analysis failed. Backend error: $backendError. '
        'Direct fallback error: $directError',
      );
    }
  }

  Future<String> _uploadToCloudinary(XFile imageFile) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
            ),
          )
          ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              await imageFile.readAsBytes(),
              filename: _safeFileName(imageFile),
            ),
          );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = decoded['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary upload did not return a secure URL.');
    }
    return secureUrl;
  }

  Future<Map<String, dynamic>> _generateGeminiAnalysis({
    required XFile imageFile,
    required String mealType,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$_geminiModel:generateContent',
      ),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'x-goog-api-key': AppConfig.geminiApiKey,
      },
      body: jsonEncode({
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.1,
        },
        'contents': [
          {
            'parts': [
              {
                'text':
                    '''
Analyze this meal for $mealType.
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
''',
              },
              {
                'inline_data': {
                  'mime_type': _mimeTypeForImage(imageFile),
                  'data': base64Encode(bytes),
                },
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gemini API error ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>? ?? const [];
    if (candidates.isEmpty) {
      throw Exception('Gemini returned no candidates: ${response.body}');
    }

    final content =
        (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? const [];

    String? text;
    for (final part in parts) {
      if (part is Map<String, dynamic> && part['text'] != null) {
        text = part['text'].toString();
        break;
      }
    }

    if (text == null || text.isEmpty) {
      throw Exception('Gemini response did not include text content.');
    }

    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    return Map<String, dynamic>.from(jsonDecode(cleaned) as Map);
  }

  Map<String, dynamic> _normalizeAnalysisResponse(
    dynamic response,
    String mealType,
  ) {
    if (response is! Map<String, dynamic>) {
      throw Exception('Invalid analysis response from backend.');
    }

    final mealId =
        (response['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    final capturedAt =
        (response['capturedAt'] ?? DateTime.now().toIso8601String()).toString();

    return {
      'id': mealId,
      'mealId': mealId,
      'mealType': (response['mealType'] ?? mealType).toString(),
      'imageUrl': (response['imageUrl'] ?? '').toString(),
      'capturedAt': capturedAt,
      'totalCalories': (response['totalCalories'] as num?)?.toInt() ?? 0,
      'protein': (response['protein'] as num?)?.toInt() ?? 0,
      'carbs': (response['carbs'] as num?)?.toInt() ?? 0,
      'fat': (response['fat'] as num?)?.toInt() ?? 0,
      'healthLabel': _normalizeHealthLabel(response['healthLabel']),
      'suggestions': List<String>.from(response['suggestions'] ?? const []),
      'detectedItems': List<dynamic>.from(
        response['detectedItems'] ?? const [],
      ),
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

  String _mimeTypeForImage(XFile imageFile) {
    final path = imageFile.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.heic') || path.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }
}
