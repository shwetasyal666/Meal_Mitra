import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/features/evolution/domain/evolution_data.dart';

final evolutionRepositoryProvider = Provider((ref) {
  return EvolutionRepository(ref.watch(apiClientProvider));
});

final evolutionDataProvider = FutureProvider<EvolutionData>((ref) {
  return ref.watch(evolutionRepositoryProvider).fetchEvolutionData();
});

class EvolutionRepository {
  final ApiClient _apiClient;
  EvolutionRepository(this._apiClient);

  Future<EvolutionData> fetchEvolutionData() async {
    try {
      final response = await _apiClient.get('/profile/evolution');
      if (response == null) return EvolutionData();
      return EvolutionData.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      return EvolutionData();
    }
  }
}
