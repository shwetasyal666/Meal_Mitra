import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/features/dashboard/data/dashboard_repository.dart';
import 'package:mealmitra/features/profile/data/profile_repository.dart';

class RecommendationsSheet extends ConsumerStatefulWidget {
  const RecommendationsSheet({super.key});

  @override
  ConsumerState<RecommendationsSheet> createState() => _RecommendationsSheetState();
}

class _RecommendationsSheetState extends ConsumerState<RecommendationsSheet> {
  bool _isLoading = true;
  List<String> _insights = [];

  @override
  void initState() {
    super.initState();
    _generateInsights();
  }

  Future<void> _generateInsights() async {
    // Artificial delay to simulate AI processing
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;

    final profile = ref.read(currentProfileProvider).value;
    final summary = ref.read(dailySummaryProvider).value;

    final List<String> newInsights = [];

    if (profile == null || summary == null) {
      newInsights.add("Start logging meals to receive personalized AI recommendations.");
    } else {
      final target = profile.dailyCalorieTarget;
      final consumed = summary.totalCalories;

      // Calories insight
      if (consumed < target * 0.8) {
        newInsights.add("You're well below your calorie target. Consider a nutritious snack to keep your energy levels steady.");
      } else if (consumed > target) {
        newInsights.add("You've exceeded your daily calorie target. Focus on lighter meals and hydration for the rest of the day.");
      } else {
        newInsights.add("You're right on track with your calorie goals today. Keep up the balanced eating!");
      }

      // Macros insight (Simplified target estimations: Protein 30%, Carbs 40%, Fats 30%)
      final proteinTarget = ((target * 0.3) / 4).round();
      if (summary.totalProtein < proteinTarget * 0.5) {
        newInsights.add("Your protein consumption is a bit low today. Try adding some lean meats, lentils, or dairy to your next meal.");
      }

      final carbsTarget = ((target * 0.4) / 4).round();
      if (summary.totalCarbs > carbsTarget * 1.2) {
        newInsights.add("Carb intake is slightly high. Opt for fibrous vegetables or healthy fats instead of grains for dinner.");
      }

      // Lifestyle / Regional info generic insight
      if (profile.cuisinePreference.isNotEmpty && profile.cuisinePreference != 'Any') {
        newInsights.add("To match your ${profile.cuisinePreference} preference, explore traditional recipes that align with your ${profile.healthFocus} focus!");
      } else {
        newInsights.add("Hydration is key. Make sure you're drinking enough water alongside your meals!");
      }
    }

    setState(() {
      _insights = newInsights;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Color(0xFF027B3D), size: 24),
              const SizedBox(width: 12),
              const Text('AI Recommendations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 20)),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Padding(
               padding: EdgeInsets.symmetric(vertical: 40),
               child: Center(
                 child: Column(
                   children: [
                     CircularProgressIndicator(color: Color(0xFF027B3D)),
                     SizedBox(height: 16),
                     Text('Analyzing your nutritional data...', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                   ],
                 ),
               ),
            )
          else
            Column(
              children: _insights.map((insight) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F3ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF027B3D).withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.circleCheck, color: Color(0xFF027B3D), size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight,
                          style: const TextStyle(color: Color(0xFF0D3B2E), fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                )
              ).toList(),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF027B3D),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
