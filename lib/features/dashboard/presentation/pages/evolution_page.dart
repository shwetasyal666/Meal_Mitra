import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/features/evolution/domain/evolution_data.dart';
import 'package:mealmitra/features/profile/data/profile_repository.dart';
import 'package:mealmitra/features/evolution/data/evolution_repository.dart';
import 'package:intl/intl.dart';
import 'package:mealmitra/features/profile/domain/user_profile.dart';

class EvolutionPage extends ConsumerWidget {
  const EvolutionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentProfileProvider);
    final evolutionAsync = ref.watch(evolutionDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(
                child: Text(
                  'Complete onboarding to unlock your evolution data.',
                ),
              );
            }

            return evolutionAsync.when(
              data: (evolution) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 32),
                    Text(
                      "Weight Evolution",
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 34,
                      ),
                    ),
                    const Text(
                      'Your journey over the last 35 days',
                      style: TextStyle(
                        color: Colors.black38,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildWeightEvolutionCard(context, profile, evolution),
                    const SizedBox(height: 24),

                    _buildWeeklyAverageCard(context, profile, evolution),
                    const SizedBox(height: 24),

                    _buildActiveEnergyCard(context, profile, evolution),
                    const SizedBox(height: 24),

                    _buildHealthConcernCard(context, profile, evolution),
                    const SizedBox(height: 24),

                    _buildAchievementsSection(context, profile, evolution),
                    const SizedBox(height: 24),

                    _buildEditorsNote(context, profile, evolution),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text('Error loading evolution data: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading profile: $e')),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.circleUser, size: 32, color: Color(0xFF027B3D)),
        const SizedBox(width: 12),
        Text(
          'The Vitality Editorial',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF027B3D),
            fontSize: 18,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(LucideIcons.bell, size: 22),
        ),
      ],
    );
  }

  Widget _buildWeightEvolutionCard(
    BuildContext context,
    UserProfile profile,
    EvolutionData evolution,
  ) {
    final chartPoints = _buildChartWeightHistory(profile, evolution);
    final startWeight = chartPoints.first.weight;
    final currentWeight = profile.weightKg;
    final progress = currentWeight - startWeight;
    final progressColor = _progressColor(profile, progress);
    final progressLabel = _progressHeadline(profile, progress);
    final targetWeight = _suggestedTargetWeight(profile);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progressLabel,
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    'TOTAL PROGRESS',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${currentWeight.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'CURRENT WEIGHT',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF027B3D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Target: ${targetWeight.toStringAsFixed(1)}kg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF027B3D),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF027B3D).withValues(alpha: 0.05),
                    ),
                    spots: chartPoints.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.weight);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            chartPoints.length <= 2 && evolution.weightHistory.length <= 1
                ? 'Log another weight update to reveal a fuller trajectory.'
                : _weightTrajectoryMessage(profile, progress),
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'START',
                style: TextStyle(
                  color: Colors.black26,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'PROGRESSION',
                style: TextStyle(
                  color: Colors.black26,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'TODAY',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAverageCard(
    BuildContext context,
    UserProfile profile,
    EvolutionData evolution,
  ) {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final now = DateTime.now();
    final loggedDays = evolution.loggedDaysCount;
    final subtitle = loggedDays == 0
        ? 'Log meals this week to unlock your rhythm'
        : '$loggedDays active day${loggedDays == 1 ? '' : 's'} in this cycle';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Caloric',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'Baseline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Target:',
                      style: TextStyle(
                        color: Color(0xFF027B3D),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      profile.dailyCalorieTarget.toString(),
                      style: const TextStyle(
                        color: Color(0xFF027B3D),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.asMap().entries.map((entry) {
              final dayIndex = entry.key;
              final dayName = entry.value;

              // Find calorie data for this weekday in the last 7 days
              final weekdayToDate = now.subtract(
                Duration(days: now.weekday - 1 - dayIndex),
              );
              final dayId = DateFormat('yyyy-MM-dd').format(weekdayToDate);
              final caloriePoint = evolution.calorieHistory.firstWhere(
                (p) => p.dayId == dayId,
                orElse: () => CaloriePoint(calories: 0, dayId: dayId),
              );

              final ratio = profile.dailyCalorieTarget > 0
                  ? (caloriePoint.calories / profile.dailyCalorieTarget).clamp(
                      0.1,
                      1.2,
                    )
                  : 0.1;
              final isTargetMet =
                  caloriePoint.calories > profile.dailyCalorieTarget * 0.8;

              return Column(
                children: [
                  Container(
                    width: 12,
                    height: (60 * ratio).toDouble(),
                    decoration: BoxDecoration(
                      color: isTargetMet
                          ? const Color(0xFF027B3D)
                          : const Color(0xFF027B3D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayName,
                    style: const TextStyle(
                      color: Colors.black26,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEnergyCard(
    BuildContext context,
    UserProfile profile,
    EvolutionData evolution,
  ) {
    final averageCalories = evolution.averageCaloriesPerLoggedDay;
    final difference = averageCalories - profile.dailyCalorieTarget;
    final summary = evolution.loggedDaysCount == 0
        ? 'Start logging meals to estimate your daily energy pattern.'
        : difference.abs() <= 150
        ? 'Your average intake is hovering close to your target.'
        : difference > 0
        ? 'Your current intake is trending above target.'
        : 'Your current intake is trending below target.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.zap, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Metabolic Engine',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text(
                summary,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    averageCalories.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'kcal/avg',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthConcernCard(
    BuildContext context,
    UserProfile profile,
    EvolutionData evolution,
  ) {
    final healthData = evolution.healthConcernData;
    final healthScore = healthData.healthScore;
    final totalMeals = healthData.totalMeals;
    
    final scoreColor = healthScore >= 0.7
        ? const Color(0xFF027B3D)
        : healthScore >= 0.4
            ? const Color(0xFFF59E0B)
            : Colors.red;
    
    final scoreLabel = healthScore >= 0.7
        ? 'Excellent'
        : healthScore >= 0.4
            ? 'Good'
            : 'Needs Work';
    
    final dominatLabel = healthData.dominantConcern == 'healthy'
        ? 'Healthy Choices'
        : healthData.dominantConcern == 'avoid'
            ? 'Limit These'
            : 'Moderate Choices';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal Health Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalMeals == 0
                        ? 'Log meals to see analysis'
                        : '$totalMeals meals this week',
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.heart,
                      color: scoreColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildHealthStatItem(
                  'Healthy',
                  healthData.healthyMeals,
                  const Color(0xFF027B3D),
                  totalMeals,
                ),
              ),
              Expanded(
                child: _buildHealthStatItem(
                  'Moderate',
                  healthData.moderateMeals,
                  const Color(0xFFF59E0B),
                  totalMeals,
                ),
              ),
              Expanded(
                child: _buildHealthStatItem(
                  'Avoid',
                  healthData.avoidMeals,
                  Colors.red,
                  totalMeals,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (totalMeals > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    if (healthData.healthyMeals > 0)
                      Expanded(
                        flex: healthData.healthyMeals,
                        child: Container(color: const Color(0xFF027B3D)),
                      ),
                    if (healthData.moderateMeals > 0)
                      Expanded(
                        flex: healthData.moderateMeals,
                        child: Container(color: const Color(0xFFF59E0B)),
                      ),
                    if (healthData.avoidMeals > 0)
                      Expanded(
                        flex: healthData.avoidMeals,
                        child: Container(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Avg: ${healthData.averageCalories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  dominatLabel,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'P: ${healthData.averageProtein.toStringAsFixed(0)}g  C: ${healthData.averageCarbs.toStringAsFixed(0)}g  F: ${healthData.averageFat.toStringAsFixed(0)}g',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthStatItem(String label, int count, Color color, int total) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '$percentage%',
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(
    BuildContext context,
    UserProfile profile,
    EvolutionData evolution,
  ) {
    final achievements = [
      {
        'label': 'Profile Ready',
        'icon': LucideIcons.circleCheck,
        'color': Colors.green,
      },
      {
        'label': evolution.loggedMealCount > 0
            ? '${evolution.loggedMealCount} Meals Logged'
            : 'First Meal Pending',
        'icon': LucideIcons.utensils,
        'color': Colors.blue,
      },
      {
        'label': evolution.loggedDaysCount >= 3
            ? 'Consistency Building'
            : 'Need 3 Active Days',
        'icon': LucideIcons.shieldCheck,
        'color': Colors.purple,
      },
      {
        'label': _daysOnTarget(profile, evolution) > 0
            ? '${_daysOnTarget(profile, evolution)} Target Hits'
            : 'Target Lock Pending',
        'icon': LucideIcons.crown,
        'color': Colors.amber,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Achievements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Spacer(),
            Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF027B3D),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: achievements
              .map(
                (ach) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ach['icon'] as IconData,
                        color: (ach['color'] as Color).withValues(alpha: 0.8),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ach['label'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildEditorsNote(
    BuildContext context,
    UserProfile profile,
    EvolutionData evolution,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF027B3D),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "THE VITALITY VERDICT",
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _vitalityVerdict(profile, evolution),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _vitalitySubcopy(profile, evolution),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  List<WeightPoint> _buildChartWeightHistory(
    UserProfile profile,
    EvolutionData evolution,
  ) {
    final points = [...evolution.weightHistory];
    final now = DateTime.now();

    if (points.isEmpty) {
      return [
        WeightPoint(
          weight: profile.weightKg,
          date: now.subtract(const Duration(days: 34)),
        ),
        WeightPoint(weight: profile.weightKg, date: now),
      ];
    }

    if ((points.last.weight - profile.weightKg).abs() > 0.01 ||
        !DateUtils.isSameDay(points.last.date, now)) {
      points.add(WeightPoint(weight: profile.weightKg, date: now));
    }

    if (points.length == 1) {
      points.insert(
        0,
        WeightPoint(
          weight: points.first.weight,
          date: points.first.date.subtract(const Duration(days: 34)),
        ),
      );
    }

    return points;
  }

  Color _progressColor(UserProfile profile, double progress) {
    switch (profile.goal) {
      case ProfileGoal.lose:
        return progress <= 0 ? const Color(0xFF027B3D) : Colors.orange;
      case ProfileGoal.gain:
        return progress >= 0 ? const Color(0xFF027B3D) : Colors.orange;
      case ProfileGoal.maintain:
        return progress.abs() <= 1 ? const Color(0xFF027B3D) : Colors.orange;
    }
  }

  String _progressHeadline(UserProfile profile, double progress) {
    if (progress.abs() < 0.05) return '0.0 kg';
    final prefix = progress > 0 ? '+' : '';
    return '$prefix${progress.toStringAsFixed(1)} kg';
  }

  String _weightTrajectoryMessage(UserProfile profile, double progress) {
    switch (profile.goal) {
      case ProfileGoal.lose:
        return progress <= 0
            ? 'Your weight trend is moving in the direction of your fat-loss goal.'
            : 'Your weight trend is rising. A steadier calorie rhythm can help.';
      case ProfileGoal.gain:
        return progress >= 0
            ? 'Your weight trend is supporting your muscle-gain objective.'
            : 'Your weight trend is dipping. Consider more consistent fueling.';
      case ProfileGoal.maintain:
        return progress.abs() <= 1
            ? 'Your weight is staying stable, which fits your maintenance goal.'
            : 'Your weight is drifting away from maintenance range.';
    }
  }

  double _suggestedTargetWeight(UserProfile profile) {
    switch (profile.goal) {
      case ProfileGoal.lose:
        return (profile.weightKg - 4).clamp(35, 250).toDouble();
      case ProfileGoal.gain:
        return (profile.weightKg + 4).clamp(35, 250).toDouble();
      case ProfileGoal.maintain:
        return profile.weightKg;
    }
  }

  int _daysOnTarget(UserProfile profile, EvolutionData evolution) {
    if (profile.dailyCalorieTarget <= 0) return 0;
    return evolution.calorieHistory.where((point) {
      if (point.calories == 0) return false;
      final minTarget = profile.dailyCalorieTarget * 0.8;
      final maxTarget = profile.dailyCalorieTarget * 1.1;
      return point.calories >= minTarget && point.calories <= maxTarget;
    }).length;
  }

  String _vitalityVerdict(UserProfile profile, EvolutionData evolution) {
    if (evolution.loggedMealCount == 0) {
      return 'Log your first meals\nto unlock a true editorial verdict.';
    }

    final targetDays = _daysOnTarget(profile, evolution);
    if (targetDays >= 4) {
      return 'Your intake discipline is\nbuilding genuine momentum.';
    }

    if (evolution.averageCaloriesPerLoggedDay > profile.dailyCalorieTarget) {
      return 'Your logged meals suggest\nyou are eating above target.';
    }

    return 'Your logged meals reveal\nroom for a steadier nutrition rhythm.';
  }

  String _vitalitySubcopy(UserProfile profile, EvolutionData evolution) {
    if (evolution.loggedMealCount == 0) {
      return 'Once meals are logged, this page will translate them into weight and calorie momentum.';
    }

    return '${evolution.loggedMealCount} meals across ${evolution.loggedDaysCount} active day'
        '${evolution.loggedDaysCount == 1 ? '' : 's'} are informing this evaluation.';
  }
}
