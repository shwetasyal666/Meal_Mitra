import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthRepository {
  Stream<String?> authStateChanges();
  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail(String email, String password, {String? displayName});
  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository(
    ref.watch(apiClientProvider),
  );
});

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._apiClient) {
    _init();
  }

  final ApiClient _apiClient;
  final _authStateController = StreamController<String?>.broadcast();

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final uid = prefs.getString('auth_uid');
    if (token != null && uid != null) {
      _apiClient.setToken(token);
      _authStateController.add(uid);
    } else {
      _authStateController.add(null);
    }
  }

  @override
  Stream<String?> authStateChanges() => _authStateController.stream;

  @override
  Future<void> registerWithEmail(String email, String password, {String? displayName}) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (displayName != null && displayName.isNotEmpty) {
      body['displayName'] = displayName;
    }
    final response = await _apiClient.post('/auth/register', body: body);
    await _handleAuthResponse(response);
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    final response = await _apiClient.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    await _handleAuthResponse(response);
  }

  Future<void> _handleAuthResponse(dynamic response) async {
    final token = response['token'] as String;
    final uid = response['uid'] as String;

    _apiClient.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_uid', uid);

    _authStateController.add(uid);
  }

  @override
  Future<void> signOut() async {
    _apiClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_uid');
    _authStateController.add(null);
  }
}
