import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/features/profile/domain/user_profile.dart';

class WaterTarget {
  final double dailyGlasses;
  final double dailyLiters;
  final double glassSizeMl;

  const WaterTarget({
    required this.dailyGlasses,
    required this.dailyLiters,
    this.glassSizeMl = 250,
  });

  static WaterTarget calculate(UserProfile profile) {
    double baseLiters = profile.weightKg * 0.033;

    if (profile.age >= 65) {
      baseLiters *= 1.1;
    } else if (profile.age <= 18) {
      baseLiters *= 0.85;
    }

    switch (profile.activityLevel) {
      case ActivityLevel.low:
        break;
      case ActivityLevel.moderate:
        baseLiters += 0.5;
        break;
      case ActivityLevel.high:
        baseLiters += 1.0;
        break;
    }

    if (profile.goal == ProfileGoal.lose) {
      baseLiters += 0.3;
    } else if (profile.goal == ProfileGoal.gain) {
      baseLiters += 0.2;
    }

    const glassSize = 250.0;
    final totalMl = baseLiters * 1000;
    final glasses = (totalMl / glassSize).roundToDouble();
    final liters = (glasses * glassSize / 1000);

    return WaterTarget(
      dailyGlasses: glasses,
      dailyLiters: liters,
      glassSizeMl: glassSize,
    );
  }
}

class WaterDayRecord {
  final String date;
  final int glassesTaken;

  const WaterDayRecord({required this.date, required this.glassesTaken});

  WaterDayRecord copyWith({int? glassesTaken}) {
    return WaterDayRecord(
      date: date,
      glassesTaken: glassesTaken ?? this.glassesTaken,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'glassesTaken': glassesTaken,
      };

  factory WaterDayRecord.fromMap(Map<String, dynamic> map) {
    return WaterDayRecord(
      date: map['date'] as String,
      glassesTaken: (map['glassesTaken'] as num).toInt(),
    );
  }
}

class WaterAnalysis {
  final int glassesTaken;
  final double dailyGlassesTarget;
  final double percentage;
  final String verdict;
  final String subcopy;
  final String status;

  const WaterAnalysis({
    required this.glassesTaken,
    required this.dailyGlassesTarget,
    required this.percentage,
    required this.verdict,
    required this.subcopy,
    required this.status,
  });

  static WaterAnalysis analyze(int glassesTaken, double targetGlasses) {
    if (targetGlasses <= 0) {
      return WaterAnalysis(
        glassesTaken: 0,
        dailyGlassesTarget: 0,
        percentage: 0,
        verdict: 'Set your profile to get a personalized hydration target.',
        subcopy: 'Your daily water goal is calculated from age, weight, and activity level.',
        status: 'pending',
      );
    }

    final percentage = (glassesTaken / targetGlasses * 100).clamp(0.0, 150.0);

    String status;
    String verdict;
    String subcopy;

    if (glassesTaken == 0) {
      status = 'empty';
      verdict = 'No glasses logged today.';
      subcopy = 'Tap a glass to start tracking your hydration.';
    } else if (percentage >= 100) {
      status = 'complete';
      verdict = 'Hydration goal achieved!';
      subcopy = 'You drank $glassesTaken/${targetGlasses.toInt()} glasses. Your body thanks you.';
    } else if (percentage >= 75) {
      status = 'almost';
      verdict = 'Almost there!';
      subcopy = '${(targetGlasses - glassesTaken).ceil()} more glasses to hit your target.';
    } else if (percentage >= 50) {
      status = 'halfway';
      verdict = 'Halfway to your goal.';
      subcopy = 'Keep sipping to stay on track today.';
    } else if (percentage >= 25) {
      status = 'low';
      verdict = 'Hydration is behind schedule.';
      subcopy = 'Try setting hourly reminders to drink water.';
    } else {
      status = 'very_low';
      verdict = 'Very low water intake today.';
      subcopy = 'Start with a glass now and build momentum.';
    }

    return WaterAnalysis(
      glassesTaken: glassesTaken,
      dailyGlassesTarget: targetGlasses,
      percentage: percentage,
      verdict: verdict,
      subcopy: subcopy,
      status: status,
    );
  }
}

final waterTargetProvider = Provider<WaterTarget>((ref) {
  throw UnimplementedError('Profile must be provided via family');
});

final waterTargetProviderFamily = Provider.family<WaterTarget, UserProfile>((ref, profile) {
  return WaterTarget.calculate(profile);
});
