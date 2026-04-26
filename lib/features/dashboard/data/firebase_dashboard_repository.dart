import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mealmitra/features/dashboard/domain/daily_summary.dart';
import 'package:mealmitra/features/meal_history/domain/meal_record.dart';

class FirebaseDashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _uid;

  FirebaseDashboardRepository(this._uid);

  Future<List<MealRecord>> getMealsForDate(DateTime date) async {
    // Get start and end of day in UTC to match how we save ISO strings
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).toIso8601String();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('meals')
          .where('capturedAt', isGreaterThanOrEqualTo: startOfDay)
          .where('capturedAt', isLessThanOrEqualTo: endOfDay)
          .get();

      return snapshot.docs.map((doc) {
        return MealRecord.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<DailySummary?> getDailySummary(DateTime date, String dayId) async {
    final meals = await getMealsForDate(date);
    
    int totalCals = 0;
    int carbs = 0;
    int protein = 0;
    int fats = 0;

    for (final meal in meals) {
      totalCals += meal.totalCalories;
      carbs += meal.carbs;
      protein += meal.protein;
      fats += meal.fat;
    }

    return DailySummary(
      dayId: dayId,
      totalCalories: totalCals,
      mealCount: meals.length,
      lastMealAtIso: meals.isNotEmpty ? meals.last.capturedAtIso : '',
      totalProtein: protein,
      totalCarbs: carbs,
      totalFats: fats,
    );
  }
}
