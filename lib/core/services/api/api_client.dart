import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set to `true` to use the local development server.
/// Set to `false` to use the production Render backend.
const bool kUseLocalBackend = false;

/// Production backend URL (Render).
/// Update this after deploying to Render.
const String kProductionBaseUrl = 'https://mealmitra-backend-pnov.onrender.com';

/// Local dev server URL.
String get _localBaseUrl {
  if (kIsWeb) return 'http://localhost:3000';
  return Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  final String baseUrl = kUseLocalBackend ? _localBaseUrl : kProductionBaseUrl;
  String? authToken;

  void setToken(String token) {
    authToken = token;
  }

  void clearToken() {
    authToken = null;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handleResponse(response);
  }

  Future<dynamic> postMultipart(String path, {required String fileField, required List<int> fileBytes, required String fileName, Map<String, String>? fields}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    if (fields != null) {
      request.fields.addAll(fields);
    }
    request.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }
}
