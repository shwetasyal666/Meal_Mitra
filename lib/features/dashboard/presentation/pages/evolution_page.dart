import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/features/evolution/domain/evolution_data.dart';
import 'package:mealmitra/features/profile/data/profile_repository.dart';
import 'package:mealmitra/features/evolution/data/evolution_repository.dart';
import 'package:intl/intl.dart';

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
          data: (profile) => evolutionAsync.when(
            data: (evolution) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    style: TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),

                  _buildWeightEvolutionCard(context, profile!, evolution),
                  const SizedBox(height: 24),

                  _buildWeeklyAverageCard(context, profile, evolution),
                  const SizedBox(height: 24),

                  _buildActiveEnergyCard(context),
                  const SizedBox(height: 24),

                  _buildAchievementsSection(context),
                  const SizedBox(height: 24),

                  _buildEditorsNote(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading evolution data: $e')),
          ),
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

  Widget _buildWeightEvolutionCard(BuildContext context, dynamic profile, dynamic evolution) {
    final startWeight = evolution.weightHistory.isNotEmpty ? evolution.weightHistory.first.weight : profile.weightKg;
    final currentWeight = profile.weightKg;
    final progress = currentWeight - startWeight;
    final progressColor = progress <= 0 ? const Color(0xFF027B3D) : Colors.orange;

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
                    '${progress > 0 ? '+' : ''}${progress.toStringAsFixed(1)} kg', 
                    style: TextStyle(color: progressColor, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)
                  ),
                  const Text('TOTAL PROGRESS', 
                    style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${currentWeight.toStringAsFixed(1)} kg', 
                    style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900)
                  ),
                  const Text('CURRENT WEIGHT', 
                    style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w800)
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF027B3D), borderRadius: BorderRadius.circular(8)),
                    child: Text('Target: 70kg', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 140,
            child: evolution.weightHistory.length < 2 
              ? const Center(child: Text('Updating trajectory...', style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold)))
              : LineChart(
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
                        spots: evolution.weightHistory.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value.weight);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('START', style: TextStyle(color: Colors.black26, fontSize: 9, fontWeight: FontWeight.w800)),
              Text('PROGRESSION', style: TextStyle(color: Colors.black26, fontSize: 9, fontWeight: FontWeight.w800)),
              Text('TODAY', style: TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAverageCard(BuildContext context, dynamic profile, dynamic evolution) {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final now = DateTime.now();
    
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Caloric', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('Baseline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Consistency is key', style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFE7F3ED), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const Text('Target:', style: TextStyle(color: Color(0xFF027B3D), fontSize: 10, fontWeight: FontWeight.w800)),
                    Text(profile.dailyCalorieTarget.toString(), style: const TextStyle(color: Color(0xFF027B3D), fontSize: 14, fontWeight: FontWeight.w900)),
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
              final weekdayToDate = now.subtract(Duration(days: now.weekday - 1 - dayIndex));
              final dayId = DateFormat('yyyy-MM-dd').format(weekdayToDate);
              final caloriePoint = evolution.calorieHistory.firstWhere(
                (p) => p.dayId == dayId, 
                orElse: () => CaloriePoint(calories: 0, dayId: dayId)
              );
              
              final ratio = (caloriePoint.calories / profile.dailyCalorieTarget).clamp(0.1, 1.2);
              final isTargetMet = caloriePoint.calories > profile.dailyCalorieTarget * 0.8;

              return Column(
                children: [
                  Container(
                    width: 12,
                    height: (60 * ratio).toDouble(),
                    decoration: BoxDecoration(
                      color: isTargetMet ? const Color(0xFF027B3D) : const Color(0xFF027B3D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(dayName, style: const TextStyle(color: Colors.black26, fontSize: 8, fontWeight: FontWeight.w800)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEnergyCard(BuildContext context) {
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
            decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
            child: const Icon(LucideIcons.zap, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Metabolic Engine', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text('Your steady caloric intake stabilizes metabolism.', style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('520', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                  SizedBox(width: 4),
                  Text('kcal/avg', style: TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    final achievements = [
      {'label': 'Profile Ready', 'icon': LucideIcons.circleCheck, 'color': Colors.green},
      {'label': 'Vitals Synced', 'icon': LucideIcons.refreshCw, 'color': Colors.blue},
      {'label': 'Metric King', 'icon': LucideIcons.crown, 'color': Colors.amber},
      {'label': 'Consistency', 'icon': LucideIcons.shieldCheck, 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Spacer(),
            Text('View All', style: TextStyle(color: Color(0xFF027B3D), fontSize: 12, fontWeight: FontWeight.bold)),
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
          children: achievements.map((ach) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                Icon(ach['icon'] as IconData, color: (ach['color'] as Color).withValues(alpha: 0.8), size: 24),
                const SizedBox(width: 12),
                Expanded(child: Text(ach['label'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildEditorsNote(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF027B3D),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("THE VITALITY VERDICT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          SizedBox(height: 8),
          Text("Precision in tracking\nleads to perfection in health.", 
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)
          ),
        ],
      ),
    );
  }
}
