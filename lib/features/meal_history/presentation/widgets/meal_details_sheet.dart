import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/core/widgets/app_image.dart';
import 'package:mealmitra/features/meal_history/domain/meal_record.dart';

class MealDetailsSheet extends ConsumerStatefulWidget {
  const MealDetailsSheet({super.key, required this.meal});

  final MealRecord meal;

  @override
  ConsumerState<MealDetailsSheet> createState() => _MealDetailsSheetState();
}

class _MealDetailsSheetState extends ConsumerState<MealDetailsSheet> {
  bool _showAllSuggestions = false;

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final api = ref.watch(apiClientProvider);
    final imageUrl = _resolveImagePath(api.baseUrl, meal.imageUrl);
    final theme = Theme.of(context);
    final visibleSuggestions = _showAllSuggestions
        ? meal.suggestions
        : meal.suggestions.take(1).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF027B3D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    meal.mealType.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF027B3D),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image & Stats
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AppImage(
                    imagePath: imageUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    fallback: Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[100],
                      child: const Icon(
                        LucideIcons.utensils,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${meal.totalCalories} kcal',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMacroTag(
                        LucideIcons.beef,
                        '${meal.protein}g Protein',
                        const Color(0xFF027B3D),
                      ),
                      const SizedBox(height: 4),
                      _buildMacroTag(
                        LucideIcons.wheat,
                        '${meal.carbs}g Carbs',
                        const Color(0xFFEAB308),
                      ),
                      const SizedBox(height: 4),
                      _buildMacroTag(
                        LucideIcons.droplets,
                        '${meal.fat}g Fats',
                        const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Suggestion Card
            if (meal.suggestions.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3ED),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          color: Color(0xFF027B3D),
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'VITALITY SUGGESTION',
                          style: TextStyle(
                            color: Color(0xFF027B3D),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...visibleSuggestions.map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF027B3D),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: const TextStyle(
                                  color: Color(0xFF0D3B2E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (meal.suggestions.length > 1)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllSuggestions = !_showAllSuggestions;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _showAllSuggestions
                              ? 'Show less'
                              : 'More (${meal.suggestions.length - 1})',
                          style: const TextStyle(
                            color: Color(0xFF027B3D),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Items List
            Text(
              'DETECTED ITEMS',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.3),
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ...meal.detectedItems.map((item) => _buildItemRow(item)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroTag(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(dynamic item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF027B3D),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          Text(
            '${item.calories} kcal',
            style: const TextStyle(
              color: Colors.black38,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
