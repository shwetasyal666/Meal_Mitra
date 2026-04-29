import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mealmitra/core/config/app_config.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/evolution/domain/evolution_data.dart';
import 'package:mealmitra/features/profile/data/profile_repository.dart';
import 'package:mealmitra/features/profile/domain/user_profile.dart';

final evolutionRepositoryProvider = Provider((ref) {
  return EvolutionRepository(
    ref.watch(apiClientProvider),
    uid: ref.watch(authStateProvider).value,
    profile: ref.watch(currentProfileProvider).value,
  );
});

final evolutionDataProvider = FutureProvider<EvolutionData>((ref) {
  return ref.watch(evolutionRepositoryProvider).fetchEvolutionData();
});

class EvolutionRepository {
  final ApiClient _apiClient;
  final String? uid;
  final UserProfile? profile;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EvolutionRepository(
    this._apiClient, {
    required this.uid,
    required this.profile,
  });

  Future<EvolutionData> fetchEvolutionData() async {
    if (AppConfig.useFirebase) {
      return _fetchFirebaseEvolutionData();
    }

    try {
      final response = await _apiClient.get('/profile/evolution');
      if (response == null) return EvolutionData();
      return EvolutionData.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      return EvolutionData();
    }
  }

  Future<EvolutionData> _fetchFirebaseEvolutionData() async {
    if (uid == null) return EvolutionData();

    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weightCutoff = now.subtract(const Duration(days: 35));

    final weightDocs = await _firestore
        .collection('users')
        .doc(uid)
        .collection('weight_history')
        .orderBy('recordedAt')
        .get();

    final weightHistory = weightDocs.docs
        .map((doc) => WeightPoint.fromMap(doc.data()))
        .where((point) => !point.date.isBefore(weightCutoff))
        .toList();

    final mealsDocs = await _firestore
        .collection('users')
        .doc(uid)
        .collection('meals')
        .where(
          'capturedAt',
          isGreaterThanOrEqualTo: weekStart.toIso8601String(),
        )
        .get();

    final caloriesByDay = <String, int>{};
    final healthConcernByDay = <String, _HealthConcernDay>{};
    var loggedMealCount = 0;
    var totalCalories = 0;
    var totalProtein = 0;
    var totalCarbs = 0;
    var totalFat = 0;

    for (final doc in mealsDocs.docs) {
      final data = doc.data();
      final capturedAt = data['capturedAt'] as String?;
      if (capturedAt == null) continue;

      final parsed = DateTime.tryParse(capturedAt);
      if (parsed == null) continue;

      final dayId = DateFormat('yyyy-MM-dd').format(parsed);
      final mealCalories = (data['totalCalories'] as num?)?.toInt() ?? 0;
      caloriesByDay.update(
        dayId,
        (value) => value + mealCalories,
        ifAbsent: () => mealCalories,
      );
      loggedMealCount += 1;
      totalCalories += mealCalories;
      totalProtein += (data['protein'] as num?)?.toInt() ?? 0;
      totalCarbs += (data['carbs'] as num?)?.toInt() ?? 0;
      totalFat += (data['fat'] as num?)?.toInt() ?? 0;

      final healthLabel = (data['healthLabel'] as String?) ?? 'moderate';
      final dayConcern = healthConcernByDay.putIfAbsent(
        dayId,
        () => _HealthConcernDay(date: dayId),
      );
      dayConcern.increment(healthLabel);
    }

    final healthConcernData = _buildHealthConcernData(
      mealsDocs.docs.map((doc) => doc.data()).toList(),
      healthConcernByDay,
      totalCalories,
      totalProtein,
      totalCarbs,
      totalFat,
      loggedMealCount,
    );

    final calorieHistory = List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final dayId = DateFormat('yyyy-MM-dd').format(day);
      return CaloriePoint(calories: caloriesByDay[dayId] ?? 0, dayId: dayId);
    });

    if (weightHistory.isEmpty && profile != null && profile!.weightKg > 0) {
      return EvolutionData(
        weightHistory: [WeightPoint(weight: profile!.weightKg, date: now)],
        calorieHistory: calorieHistory,
        loggedMealCount: loggedMealCount,
        healthConcernData: healthConcernData,
      );
    }

    if (profile != null && profile!.weightKg > 0) {
      final hasCurrentWeight =
          weightHistory.isNotEmpty &&
          (weightHistory.last.weight - profile!.weightKg).abs() < 0.01;
      if (!hasCurrentWeight) {
        weightHistory.add(WeightPoint(weight: profile!.weightKg, date: now));
      }
    }

    return EvolutionData(
      weightHistory: weightHistory,
      calorieHistory: calorieHistory,
      loggedMealCount: loggedMealCount,
      healthConcernData: healthConcernData,
    );
  }

  HealthConcernData _buildHealthConcernData(
    List<Map<String, dynamic>> mealsData,
    Map<String, _HealthConcernDay> healthConcernByDay,
    int totalCalories,
    int totalProtein,
    int totalCarbs,
    int totalFat,
    int loggedMealCount,
  ) {
    int healthyMeals = 0;
    int moderateMeals = 0;
    int avoidMeals = 0;

    for (final data in mealsData) {
      final healthLabel = (data['healthLabel'] as String?) ?? 'moderate';
      if (healthLabel == 'healthy') {
        healthyMeals++;
      } else if (healthLabel == 'avoid') {
        avoidMeals++;
      } else {
        moderateMeals++;
      }
    }

    final breakdown = healthConcernByDay.values
        .map((e) => MealConcernBreakdown(
              date: e.date,
              healthy: e.healthy,
              moderate: e.moderate,
              avoid: e.avoid,
            ))
        .toList();

    String dominantConcern = 'moderate';
    if (healthyMeals > moderateMeals && healthyMeals > avoidMeals) {
      dominantConcern = 'healthy';
    } else if (avoidMeals > moderateMeals && avoidMeals > healthyMeals) {
      dominantConcern = 'avoid';
    }

    return HealthConcernData(
      healthyMeals: healthyMeals,
      moderateMeals: moderateMeals,
      avoidMeals: avoidMeals,
      averageCalories: loggedMealCount > 0 ? totalCalories / loggedMealCount : 0,
      averageProtein: loggedMealCount > 0 ? totalProtein / loggedMealCount : 0,
      averageCarbs: loggedMealCount > 0 ? totalCarbs / loggedMealCount : 0,
      averageFat: loggedMealCount > 0 ? totalFat / loggedMealCount : 0,
      dominantConcern: dominantConcern,
      breakdown: breakdown,
    );
  }
}

class _HealthConcernDay {
  final String date;
  int healthy = 0;
  int moderate = 0;
  int avoid = 0;

  _HealthConcernDay({required this.date});

  void increment(String healthLabel) {
    if (healthLabel == 'healthy') {
      healthy++;
    } else if (healthLabel == 'avoid') {
      avoid++;
    } else {
      moderate++;
    }
  }
}
