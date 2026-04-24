import 'package:mealmitra/features/profile/domain/user_profile.dart';

class DailyCalorieTargetCalculator {
  static int calculate({
    required int age,
    required double heightCm,
    required double weightKg,
    required String gender,
    required ProfileGoal goal,
    required ActivityLevel activityLevel,
  }) {
    // Mifflin-St Jeor Equation
    final genderOffset = gender.toLowerCase() == 'male' ? 5 : -161;
    final bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + genderOffset;
    
    final multiplier = switch (activityLevel) {
      ActivityLevel.low => 1.2,
      ActivityLevel.moderate => 1.375,
      ActivityLevel.high => 1.55,
    };
    final maintenance = bmr * multiplier;
    final adjusted = switch (goal) {
      ProfileGoal.lose => maintenance - 300,
      ProfileGoal.maintain => maintenance,
      ProfileGoal.gain => maintenance + 250,
    };
    return adjusted.round();
  }
}
