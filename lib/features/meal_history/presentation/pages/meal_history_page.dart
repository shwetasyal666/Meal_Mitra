import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/core/widgets/app_image.dart';
import 'package:mealmitra/features/dashboard/data/dashboard_repository.dart';
import 'package:mealmitra/features/meal_history/domain/meal_record.dart';
import 'package:mealmitra/features/meal_history/presentation/widgets/meal_details_sheet.dart';

class MealHistoryPage extends ConsumerWidget {
  const MealHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final mealsAsync = ref.watch(recentMealsProvider);
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    final dateStr = isToday ? "Today's Slate" : DateFormat('MMMM d').format(selectedDate);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 32),
              Text(
                dateStr,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 34,
                ),
              ),
              Text(
                isToday ? 'Fine-tune your vitality through mindful mapping.' : 'Reviewing your historical vitality map.',
                style: const TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),

              // Timeline
              mealsAsync.when(
                data: (meals) => _buildTimeline(context, ref, meals),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Center(child: Text('Error loading history')),
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFE7F3ED),
          child: Icon(LucideIcons.user, size: 18, color: Color(0xFF027B3D)),
        ),
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

  Widget _buildTimeline(BuildContext context, WidgetRef ref, List<dynamic> meals) {
    final slots = [
      {'label': 'Breakfast', 'time': '08:00 AM', 'icon': LucideIcons.sun},
      {'label': 'Lunch', 'time': '01:30 PM', 'icon': LucideIcons.utensils},
      {'label': 'Snack', 'time': '04:30 PM', 'icon': LucideIcons.apple},
      {'label': 'Dinner', 'time': '08:00 PM', 'icon': LucideIcons.moon},
    ];

    return Column(
      children: slots.map((slot) {
        final meal = meals.cast<dynamic>().firstWhere(
          (m) => m.mealType.toLowerCase() == slot['label'].toString().toLowerCase(),
          orElse: () => null,
        );

        return _buildTimelineItem(
          context,
          ref,
          label: slot['label'] as String,
          time: slot['time'] as String,
          icon: slot['icon'] as IconData,
          meal: meal,
          isLast: slot['label'] == 'Dinner',
        );
      }).toList(),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String time,
    required IconData icon,
    dynamic meal,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical Line + Icon
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: meal != null ? const Color(0xFF4ADE80) : const Color(0xFFE7F3ED),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, 
                  color: meal != null ? const Color(0xFF0D3B2E) : const Color(0xFF027B3D).withValues(alpha: 0.4), 
                  size: 20
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(color: Color(0xFFEAB308), fontSize: 10, fontWeight: FontWeight.w800),
                ),
                Row(
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: meal != null ? Colors.black : Colors.black26,
                      ),
                    ),
                    const Spacer(),
                    if (meal == null)
                      _buildScanButton(context)
                    else
                      const Icon(LucideIcons.maximize, color: Color(0xFF027B3D), size: 18),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(color: Color(0xFF027B3D), shape: BoxShape.circle),
                      child: IconButton(
                        onPressed: () => context.push('/scan'),
                        icon: const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ),
                  ],
                ),
                if (meal != null)
                  _buildMealCard(ref, meal, context)
                else
                  const SizedBox(height: 48),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/scan'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.scan, size: 14, color: Color(0xFF027B3D)),
            SizedBox(width: 8),
            Text('Scan Plate', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF027B3D)
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(WidgetRef ref, dynamic mealData, BuildContext context) {
    final api = ref.watch(apiClientProvider);
    final meal = mealData is MealRecord ? mealData : MealRecord.fromMap(mealData['id'] ?? '', mealData);
    final imageUrl = _resolveImagePath(api.baseUrl, meal.imageUrl);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => MealDetailsSheet(meal: meal),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppImage(
                imagePath: imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                fallback: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(LucideIcons.utensils, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal Logged',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  Text(
                    '${meal.totalCalories} kcal • ${meal.protein}g Protein',
                    style: const TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _resolveImagePath(String baseUrl, String imageUrl) {
    if (imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('http') || AppImage.isLocalPath(imageUrl)) {
      return imageUrl;
    }
    return '$baseUrl$imageUrl';
  }
}
