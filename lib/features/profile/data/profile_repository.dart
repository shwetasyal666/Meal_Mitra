import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/profile/domain/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> fetchCurrentProfile();
  Future<String?> fetchDisplayName();
  Future<void> saveProfile(UserProfile profile);
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return LocalProfileRepository(
    ref.watch(apiClientProvider),
    ref.watch(authStateProvider).value,
  );
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).fetchCurrentProfile();
});

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._apiClient, this._uid);

  final ApiClient _apiClient;
  final String? _uid;

  @override
  Future<UserProfile?> fetchCurrentProfile() async {
    if (_uid == null) return null;
    try {
      final data = await _apiClient.get('/profile');
      if (data == null) return null;
      if (data is! Map<String, dynamic>) return null;
      // Profile is incomplete if age is not set (onboarding not completed)
      if (data['age'] == null || data['age'] == 0) {
        return null;
      }
      return UserProfile.fromMap(data['uid'] as String? ?? _uid, data);
    } catch (e) {
      return null;
    }
  }

  /// Fetches just the display name from the server without completeness checks.
  /// Used by onboarding to preserve the name set during registration.
  @override
  Future<String?> fetchDisplayName() async {
    if (_uid == null) return null;
    try {
      final data = await _apiClient.get('/profile');
      if (data == null || data is! Map<String, dynamic>) return null;
      return data['displayName'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _apiClient.post('/profile', body: profile.toMap());
  }
}
