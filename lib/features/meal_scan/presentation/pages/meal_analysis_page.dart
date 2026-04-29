import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/core/widgets/app_image.dart';
import 'package:mealmitra/features/meal_scan/presentation/controllers/meal_scan_controller.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';
import 'package:mealmitra/features/dashboard/data/dashboard_repository.dart';

class MealAnalysisPage extends ConsumerWidget {
  const MealAnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(mealScanControllerProvider).state;
    final result = scanState.result;
    final resolvedImagePath = _resolveImagePath(
      ref.watch(apiClientProvider).baseUrl,
      result?.imageUrl,
    );

    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('No analysis data available')),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image/Header
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(LucideIcons.x, color: Colors.white, size: 20),
              ),
              onPressed: () => context.go('/dashboard'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (scanState.imageFile != null)
                    kIsWeb 
                        ? Image.network(scanState.imageFile!.path, fit: BoxFit.cover)
                        : Image.file(File(scanState.imageFile!.path), fit: BoxFit.cover)
                  else if (resolvedImagePath != null)
                    AppImage(
                      imagePath: resolvedImagePath,
                      fit: BoxFit.cover,
                      fallback: Container(
                        color: Colors.grey[200],
                        child: const Icon(LucideIcons.imageOff, size: 40, color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey[200],
                      child: const Icon(LucideIcons.utensils, size: 60, color: Colors.grey),
                    ),
                  // Darken the top a bit for better visibility of the X button
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Colors.black26, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF9F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Detected Items',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showEditSheet(context, ref, result),
                        child: const Text('Edit Scan', 
                          style: TextStyle(color: Color(0xFF027B3D), fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'AI Analysis based on visual volume',
                    style: TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),

                  // Item Cards
                  ...result.detectedItems.map((item) => _buildItemCard(item, result.healthLabel)),

                  const SizedBox(height: 32),

                  // Nutri-Insight
                  _buildNutriInsightCard(
                    result.suggestions.firstOrNull ?? 
                    (result.healthLabel == 'avoid' 
                      ? 'Consider healthier alternatives for this meal.' 
                      : result.healthLabel == 'moderate' 
                        ? 'A decent choice, but look for ways to add more nutrients.' 
                        : 'Your meal is well-balanced!'),
                    result.healthLabel
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(context, result.totalCalories, ref),
    );
  }

  Widget _buildItemCard(dynamic item, String mealHealthLabel) {
    // Determine health label color based on meal context or simple keywords
    final name = item.name.toLowerCase();
    
    // Default to meal's health label if it's "avoid"
    bool isUnhealthy = mealHealthLabel == 'avoid' && (name.contains('fried') || name.contains('samosa') || name.contains('sweet'));
    bool isHealthy = name.contains('dal') || name.contains('veg') || name.contains('salad') || name.contains('fruit');
    
    final Color color;
    final String label;

    if (isUnhealthy || mealHealthLabel == 'avoid' && !isHealthy) {
      color = const Color(0xFFEF4444); // Red
      label = 'AVOID';
    } else if (isHealthy && mealHealthLabel != 'avoid') {
      color = const Color(0xFF027B3D); // Green
      label = 'GREEN';
    } else {
      color = const Color(0xFFEAB308); // Yellow
      label = 'YELLOW';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const Text(
                  'Visual Analysis Estimate',
                  style: TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.calories} kcal',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutriInsightCard(String insight, String healthLabel) {
    final bool isAvoid = healthLabel == 'avoid';
    final Color bgColor = isAvoid ? const Color(0xFFFEF2F2) : const Color(0xFFE7F3ED);
    final Color iconColor = isAvoid ? const Color(0xFFEF4444) : const Color(0xFF027B3D);
    final Color textColor = isAvoid ? const Color(0xFF7F1D1D) : const Color(0xFF0D3B2E);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: iconColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAvoid ? LucideIcons.triangleAlert : LucideIcons.lightbulb,
                color: iconColor,
                size: 20
              ),
              const SizedBox(width: 12),
              Text(
                'Nutri-Insight',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, int total, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF027B3D),
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        ),
        onPressed: () {
          ref.invalidate(dailySummaryProvider);
          ref.invalidate(recentMealsProvider);
          ref.read(mealScanControllerProvider.notifier).reset();
          context.go('/dashboard');
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Log this Meal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$total kcal', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, dynamic result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EditItemsSheet(result: result);
      },
    );
  }

  String? _resolveImagePath(String baseUrl, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('http') || AppImage.isLocalPath(imageUrl)) {
      return imageUrl;
    }
    return '$baseUrl$imageUrl';
  }
}

class _EditItemsSheet extends ConsumerStatefulWidget {
  final dynamic result;

  const _EditItemsSheet({required this.result});

  @override
  ConsumerState<_EditItemsSheet> createState() => _EditItemsSheetState();
}

class _EditItemsSheetState extends ConsumerState<_EditItemsSheet> {
  late List<DetectedFoodItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List<DetectedFoodItem>.from(widget.result.detectedItems);
  }

  void _save() {
    final originalResult = widget.result;
    
    // Recalculate total calories based on updated quantities
    int newTotalCals = 0;
    for (final item in _items) {
      newTotalCals += (item.calories * item.quantity).round();
    }

    final newResult = originalResult.copyWith(
      detectedItems: _items,
      totalCalories: newTotalCals,
    );

    ref.read(mealScanControllerProvider.notifier).updateResult(newResult);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Edit Portions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 20)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                          Text('${(item.calories * item.quantity).round()} kcal', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF027B3D))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Qty: ${item.quantity.toStringAsFixed(1)} ${item.unit}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: item.quantity,
                              min: 0.1,
                              max: 5.0,
                              activeColor: const Color(0xFF027B3D),
                              onChanged: (v) {
                                setState(() {
                                  _items[index] = item.copyWith(quantity: v);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF027B3D),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
