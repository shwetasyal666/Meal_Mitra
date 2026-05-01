import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/features/profile/domain/user_profile.dart';
import 'package:mealmitra/features/water_tracker/data/water_tracker_repository.dart';
import 'package:mealmitra/features/water_tracker/domain/water_target.dart';

class WaterTrackerCard extends ConsumerWidget {
  const WaterTrackerCard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(waterTargetProviderFamily(profile));
    final glassesTaken = ref.watch(todayGlassesProvider);
    final analysis = WaterAnalysis.analyze(glassesTaken, target.dailyGlasses);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF0EA5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.cupSoda,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hydration Tracker',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Target: ${target.dailyGlasses.toInt()} glasses (${target.dailyLiters.toStringAsFixed(1)}L)',
                    style: const TextStyle(
                      color: Color(0xFF0369A7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(analysis.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$glassesTaken/${target.dailyGlasses.toInt()}',
                  style: TextStyle(
                    color: _statusColor(analysis.status),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildGlassGrid(context, ref, glassesTaken, target.dailyGlasses.toInt()),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (analysis.percentage / 100).clamp(0, 1),
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(
                _statusColor(analysis.status),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            analysis.verdict,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: _statusColor(analysis.status),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            analysis.subcopy,
            style: const TextStyle(
              color: Color(0xFF0369A7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassGrid(
    BuildContext context,
    WidgetRef ref,
    int glassesTaken,
    int targetGlasses,
  ) {
    final displayCount = targetGlasses.clamp(8, 16);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.8,
      ),
      itemCount: displayCount,
      itemBuilder: (context, index) {
        final isFilled = index < glassesTaken;

        return GestureDetector(
          onTap: () {
            if (isFilled) {
              ref.read(todayGlassesProvider.notifier).removeGlass();
            } else if (index == glassesTaken) {
              ref.read(todayGlassesProvider.notifier).addGlass();
            } else {
              ref.read(todayGlassesProvider.notifier).setGlasses(index + 1);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isFilled ? const Color(0xFF0EA5E9) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFilled ? const Color(0xFF0EA5E9) : const Color(0xFFBAE6FD),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                LucideIcons.cupSoda,
                size: 18,
                color: isFilled ? Colors.white : const Color(0xFF7DD3FC),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'complete':
        return const Color(0xFF059669);
      case 'almost':
        return const Color(0xFF0EA5E9);
      case 'halfway':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFFF97316);
      case 'very_low':
      case 'empty':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
