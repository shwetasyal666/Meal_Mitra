import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/dashboard/domain/daily_summary.dart';
import 'package:mealmitra/features/meal_history/domain/meal_record.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dailySummaryProvider = FutureProvider<DailySummary?>((ref) async {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return null;
  final selectedDate = ref.watch(selectedDateProvider);
  final api = ref.watch(apiClientProvider);
  final dayId = selectedDate.toIso8601String().substring(0, 10);
  try {
    final response = await api.get('/dashboard/summary/$dayId');
    if (response != null && response is Map<String, dynamic>) {
      return DailySummary.fromMap(dayId, response);
    }
    return null;
  } catch (e) {
    return null;
  }
});

final recentMealsProvider = FutureProvider<List<MealRecord>>((ref) async {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return [];
  final selectedDate = ref.watch(selectedDateProvider);
  final api = ref.watch(apiClientProvider);
  final dateStr = selectedDate.toIso8601String().substring(0, 10);
  
  try {
    final response = await api.get('/meals/history?date=$dateStr');
    if (response != null && response is List) {
      return response
          .map((data) => MealRecord.fromMap(
              (data['id'] ?? '').toString(), Map<String, dynamic>.from(data)))
          .toList();
    }
    return [];
  } catch (e) {
    return [];
  }
});
