import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  // Use 10.0.2.2 for Android emulator, localhost for iOS/macOS/desktop.
  final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:3000'
      : 'http://localhost:3000';
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

  Future<dynamic> postMultipart(String path, {required String fileField, required String filePath, Map<String, String>? fields}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    if (fields != null) {
      request.fields.addAll(fields);
    }
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

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
