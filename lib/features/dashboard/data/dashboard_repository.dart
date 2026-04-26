import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/dashboard/domain/daily_summary.dart';
import 'package:mealmitra/features/meal_history/domain/meal_record.dart';
import 'package:mealmitra/core/config/app_config.dart';
import 'package:mealmitra/features/dashboard/data/firebase_dashboard_repository.dart';

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void updateDate(DateTime date) {
    state = date;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

final firebaseDashboardRepositoryProvider = Provider.family<FirebaseDashboardRepository?, String>((ref, uid) {
  if (AppConfig.useFirebase) {
    return FirebaseDashboardRepository(uid);
  }
  return null;
});

final dailySummaryProvider = FutureProvider<DailySummary?>((ref) async {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return null;
  final selectedDate = ref.watch(selectedDateProvider);
  final dayId = selectedDate.toIso8601String().substring(0, 10);

  if (AppConfig.useFirebase) {
    final repo = ref.watch(firebaseDashboardRepositoryProvider(uid));
    return repo?.getDailySummary(selectedDate, dayId);
  }

  final api = ref.watch(apiClientProvider);
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
  
  if (AppConfig.useFirebase) {
    final repo = ref.watch(firebaseDashboardRepositoryProvider(uid));
    return repo?.getMealsForDate(selectedDate) ?? [];
  }

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
