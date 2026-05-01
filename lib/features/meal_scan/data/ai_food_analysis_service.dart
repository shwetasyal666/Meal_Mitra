import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mealmitra/core/config/app_config.dart';
import 'package:mealmitra/features/meal_scan/data/local_food_catalog.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

final aiFoodAnalysisServiceProvider = Provider(
  (ref) => AiFoodAnalysisService(),
);

class FoodAnalysisException implements Exception {
  const FoodAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiFoodAnalysisService {
  AiFoodAnalysisService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<MealAnalysis> analyzeMealImage({
    required String mealId,
    required String mealType,
    required String capturedAtIso,
    required XFile imageFile,
    String? imageUrl,
  }) async {
    final providers = ['openrouter', 'gemini', 'openai'];
    Map<String, dynamic>? payload;
    FoodAnalysisException? lastError;

    for (final provider in providers) {
      try {
        payload = switch (provider) {
          'openai' => await _analyzeWithOpenAI(
              mealType: mealType,
              imageFile: imageFile,
              imageUrl: imageUrl,
            ),
          'gemini' => await _analyzeWithGemini(
              mealType: mealType,
              imageFile: imageFile,
              imageUrl: imageUrl,
            ),
          _ => await _analyzeWithOpenRouter(
              mealType: mealType,
              imageFile: imageFile,
              imageUrl: imageUrl,
            ),
        };
        lastError = null;
        break;
      } on FoodAnalysisException catch (e) {
        lastError = e;
        continue;
      }
    }

    if (payload == null) {
      throw lastError ??
          const FoodAnalysisException('All AI providers failed. Please try again later.');
    }

    return _analysisFromPayload(
      payload,
      mealId: mealId,
      mealType: mealType,
      capturedAtIso: capturedAtIso,
      imageUrl: imageUrl,
    );
  }

  Future<Map<String, dynamic>> _analyzeWithOpenAI({
    required String mealType,
    required XFile imageFile,
    String? imageUrl,
  }) async {
    final apiKey = AppConfig.openaiApiKey.trim();
    if (apiKey.isEmpty) {
      throw const FoodAnalysisException(
        'Food AI is not configured. Add OPENAI_API_KEY.',
      );
    }

    final imageSource = imageUrl != null && imageUrl.isNotEmpty
        ? imageUrl
        : await _imageDataUrl(imageFile);

    final body = <String, dynamic>{
      'model': AppConfig.openaiModel,
      'temperature': 0.1,
      'max_tokens': 1200,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are MealMitra, a careful food image analyst. Return only valid JSON. Never invent foods that are not visible.',
        },
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _foodAnalysisPrompt(mealType)},
            {
              'type': 'image_url',
              'image_url': {'url': imageSource, 'detail': 'low'},
            },
          ],
        },
      ],
      'response_format': {'type': 'json_object'},
    };

    final response = await _client
        .post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeAiResponse(response.body);
    }

    throw FoodAnalysisException(
      'Food AI failed (${response.statusCode}). Please try again.',
    );
  }

  Future<Map<String, dynamic>> _analyzeWithGemini({
    required String mealType,
    required XFile imageFile,
    String? imageUrl,
  }) async {
    final apiKey = AppConfig.geminiApiKey.trim();
    if (apiKey.isEmpty) {
      throw const FoodAnalysisException(
        'Food AI is not configured. Add GEMINI_API_KEY.',
      );
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final body = <String, dynamic>{
      'contents': [
        {
          'parts': [
            {'text': _foodAnalysisPrompt(mealType)},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 1200,
        'responseMimeType': 'application/json',
      },
    };

    final response = await _client
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/${AppConfig.geminiModel}:generateContent?key=$apiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeGeminiResponse(response.body);
    }

    throw FoodAnalysisException(
      'Food AI failed (${response.statusCode}). Please try again.',
    );
  }

  Map<String, dynamic> _decodeGeminiResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FoodAnalysisException(
        'Food AI returned an invalid response.',
      );
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const FoodAnalysisException('Food AI returned no analysis.');
    }

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map) {
      throw const FoodAnalysisException('Food AI returned an invalid candidate.');
    }

    final content = firstCandidate['content'];
    if (content is! Map) {
      throw const FoodAnalysisException('Food AI returned invalid content.');
    }

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      throw const FoodAnalysisException('Food AI returned empty content.');
    }

    final firstPart = parts.first;
    if (firstPart is! Map) {
      throw const FoodAnalysisException('Food AI returned an invalid part.');
    }

    final text = firstPart['text'];
    if (text is! String || text.isEmpty) {
      throw const FoodAnalysisException('Food AI returned empty text.');
    }

    final jsonText = _extractJsonObject(text);
    final payload = jsonDecode(jsonText);
    if (payload is! Map<String, dynamic>) {
      throw const FoodAnalysisException('Food AI returned invalid meal JSON.');
    }
    return payload;
  }

  Future<Map<String, dynamic>> _analyzeWithProxy({
    required String mealType,
    required XFile imageFile,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'mealType': mealType,
      'prompt': _foodAnalysisPrompt(mealType),
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (imageUrl == null || imageUrl.isEmpty)
        'imageBase64': await _imageDataUrl(imageFile),
    };

    final response = await _client
        .post(
          Uri.parse(AppConfig.foodAiProxyUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FoodAnalysisException(
        'Food AI proxy failed (${response.statusCode}). Please try again.',
      );
    }

    return _decodeAiResponse(response.body);
  }

  Future<Map<String, dynamic>> _analyzeWithOpenRouter({
    required String mealType,
    required XFile imageFile,
    String? imageUrl,
  }) async {
    final apiKey = AppConfig.openRouterApiKey.trim();
    if (apiKey.isEmpty) {
      throw const FoodAnalysisException(
        'Food AI is not configured. Add OPENROUTER_API_KEY or FOOD_AI_PROXY_URL.',
      );
    }

    final imageSource = imageUrl != null && imageUrl.isNotEmpty
        ? imageUrl
        : await _imageDataUrl(imageFile);

    final response = await _postOpenRouter(
      apiKey: apiKey,
      mealType: mealType,
      imageSource: imageSource,
      forceJson: true,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeAiResponse(response.body);
    }

    // Some free routed models do not accept response_format. Retry once with
    // prompt-only JSON enforcement before giving up.
    final fallbackResponse = await _postOpenRouter(
      apiKey: apiKey,
      mealType: mealType,
      imageSource: imageSource,
      forceJson: false,
    );

    if (fallbackResponse.statusCode < 200 ||
        fallbackResponse.statusCode >= 300) {
      throw FoodAnalysisException(
        'Food AI failed (${fallbackResponse.statusCode}). Please try again.',
      );
    }

    return _decodeAiResponse(fallbackResponse.body);
  }

  Future<http.Response> _postOpenRouter({
    required String apiKey,
    required String mealType,
    required String imageSource,
    required bool forceJson,
  }) {
    final body = <String, dynamic>{
      'model': AppConfig.foodAiModel,
      'temperature': 0.1,
      'max_tokens': 1200,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are MealMitra, a careful food image analyst. Return only valid JSON. Never invent foods that are not visible.',
        },
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _foodAnalysisPrompt(mealType)},
            {
              'type': 'image_url',
              'image_url': {'url': imageSource},
            },
          ],
        },
      ],
      if (forceJson) 'response_format': {'type': 'json_object'},
    };

    return _client
        .post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://github.com/${AppConfig.githubRepo}',
            'X-Title': 'MealMitra',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));
  }

  Future<String> _imageDataUrl(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final extension = imageFile.name.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  Map<String, dynamic> _decodeAiResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FoodAnalysisException(
        'Food AI returned an invalid response.',
      );
    }

    if (decoded.containsKey('detectedItems') || decoded.containsKey('items')) {
      return decoded;
    }

    final content = _extractOpenRouterContent(decoded);
    final jsonText = _extractJsonObject(content);
    final payload = jsonDecode(jsonText);
    if (payload is! Map<String, dynamic>) {
      throw const FoodAnalysisException('Food AI returned invalid meal JSON.');
    }
    return payload;
  }

  String _extractOpenRouterContent(Map<String, dynamic> decoded) {
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FoodAnalysisException('Food AI returned no analysis.');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map) {
      throw const FoodAnalysisException('Food AI returned an invalid choice.');
    }

    final message = firstChoice['message'];
    if (message is! Map) {
      throw const FoodAnalysisException('Food AI returned an invalid message.');
    }

    final content = message['content'];
    if (content is String) return content;
    if (content is List) {
      return content
          .whereType<Map>()
          .map((part) => part['text'])
          .whereType<String>()
          .join('\n');
    }

    throw const FoodAnalysisException('Food AI returned empty content.');
  }

  String _extractJsonObject(String content) {
    final trimmed = content.trim();
    final withoutFence = trimmed
        .replaceFirst(RegExp(r'^```(?:json)?', multiLine: true), '')
        .replaceFirst(RegExp(r'```$', multiLine: true), '')
        .trim();

    final start = withoutFence.indexOf('{');
    final end = withoutFence.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FoodAnalysisException('Food AI did not return valid JSON.');
    }
    return withoutFence.substring(start, end + 1);
  }

  MealAnalysis _analysisFromPayload(
    Map<String, dynamic> payload, {
    required String mealId,
    required String mealType,
    required String capturedAtIso,
    String? imageUrl,
  }) {
    final rawItems = payload['detectedItems'] ?? payload['items'] ?? const [];
    final items = <DetectedFoodItem>[];

    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is! Map) continue;
        final item = _parseFoodItem(Map<String, dynamic>.from(rawItem));
        if (item != null) items.add(item);
      }
    }

    final totals = _macroTotals(items);
    final totalCalories = totals['totalCalories'] ?? 0;

    return MealAnalysis(
      mealId: mealId,
      mealType: mealType,
      capturedAtIso: capturedAtIso,
      imageUrl: imageUrl,
      detectedItems: items,
      totalCalories: totalCalories,
      healthLabel: _healthLabel(totalCalories),
      suggestions: _safeSuggestions(payload, items, totalCalories),
    );
  }

  DetectedFoodItem? _parseFoodItem(Map<String, dynamic> rawItem) {
    final name = rawItem['name']?.toString().trim() ?? '';
    if (name.length < 2) return null;

    final quantity = _safeDouble(
      rawItem['quantity'],
      fallback: 1,
    ).clamp(0.1, 8);
    final unit = _safeUnit(rawItem['unit']?.toString());
    var calories = _safeInt(rawItem['calories']);
    var protein = _safeInt(rawItem['protein']);
    var carbs = _safeInt(rawItem['carbs']);
    var fat = _safeInt(rawItem['fat']);

    final catalogItem = _catalogMatch(name);
    if (catalogItem != null && _unitsAreCompatible(unit, catalogItem.unit)) {
      calories = catalogItem.calories;
      protein = catalogItem.protein;
      carbs = catalogItem.carbs;
      fat = catalogItem.fat;
    }

    final macroCalories = (protein * 4) + (carbs * 4) + (fat * 9);
    if (calories <= 0 && macroCalories > 0) calories = macroCalories;
    if (calories <= 0) return null;

    return DetectedFoodItem(
      name: catalogItem?.name ?? name,
      calories: calories.clamp(1, 2500).toInt(),
      protein: protein.clamp(0, 250).toInt(),
      carbs: carbs.clamp(0, 350).toInt(),
      fat: fat.clamp(0, 250).toInt(),
      quantity: quantity.toDouble(),
      unit: catalogItem?.unit ?? unit,
    );
  }

  DetectedFoodItem? _catalogMatch(String name) {
    final normalized = name.toLowerCase();
    for (final item in LocalFoodCatalog.items) {
      final catalogName = item.name.toLowerCase();
      if (normalized == catalogName ||
          normalized.contains(catalogName) ||
          catalogName.contains(normalized)) {
        return item;
      }
    }
    return null;
  }

  bool _unitsAreCompatible(String aiUnit, String catalogUnit) {
    if (aiUnit == catalogUnit) return true;
    if (aiUnit == 'serving' || aiUnit == 'visible portion') return true;
    if (catalogUnit == 'piece' &&
        ['piece', 'roti', 'chapati'].contains(aiUnit)) {
      return true;
    }
    return false;
  }

  int _safeInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _safeDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _safeUnit(String? unit) {
    final normalized = unit?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return 'serving';
    if (normalized.length > 24) return 'serving';
    return normalized;
  }

  Map<String, int> _macroTotals(List<DetectedFoodItem> items) {
    var calories = 0;
    var protein = 0;
    var carbs = 0;
    var fat = 0;

    for (final item in items) {
      calories += (item.calories * item.quantity).round();
      protein += (item.protein * item.quantity).round();
      carbs += (item.carbs * item.quantity).round();
      fat += (item.fat * item.quantity).round();
    }

    return {
      'totalCalories': calories,
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

  List<String> _safeSuggestions(
    Map<String, dynamic> payload,
    List<DetectedFoodItem> items,
    int totalCalories,
  ) {
    final rawSuggestions = payload['suggestions'];
    final suggestions = <String>[];

    if (rawSuggestions is List) {
      for (final suggestion in rawSuggestions) {
        final text = suggestion.toString().trim();
        if (text.length >= 8 && text.length <= 180) {
          suggestions.add(text);
        }
      }
    }

    if (items.isEmpty) {
      return const [
        'AI could not confidently identify food in this image. Try a clearer top-down photo or add items manually.',
      ];
    }

    if (suggestions.isEmpty) {
      suggestions.add('Review the detected foods and portions before logging.');
      if (totalCalories >= 800) {
        suggestions.add(
          'This looks calorie-dense. Consider a smaller portion.',
        );
      }
    }

    return suggestions.take(3).toList();
  }

  String _foodAnalysisPrompt(String mealType) {
    return '''
Analyze this food image for a $mealType meal.

Return ONLY valid JSON with this exact shape:
{
  "detectedItems": [
    {
      "name": "food name",
      "quantity": 1.0,
      "unit": "serving",
      "calories": 250,
      "protein": 8,
      "carbs": 35,
      "fat": 9
    }
  ],
  "suggestions": ["short useful nutrition note"],
  "confidence": 0.0
}

Rules:
- Identify only foods that are clearly visible. Do not guess hidden ingredients.
- Prefer common Indian food names when appropriate: roti, chapati, dal, rice, paneer curry, chole, rajma, idli, dosa, poha, biryani, curd, salad.
- Nutrition must be realistic for the visible portion. Use grams for protein/carbs/fat and kcal for calories.
- For counted foods like roti, idli, egg, samosa: set quantity to the visible count and nutrition per one piece.
- For mixed foods like rice, curry, dal, biryani: set quantity to the estimated visible serving count, usually 1.0.
- If the image is unclear or not food, return an empty detectedItems array and explain in suggestions.
- No markdown, no prose, no code fences.
''';
  }
}
