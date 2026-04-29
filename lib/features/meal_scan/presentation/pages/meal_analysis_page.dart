import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/core/widgets/app_image.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/meal_scan/data/local_food_catalog.dart';
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
                        ? Image.network(
                            scanState.imageFile!.path,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(scanState.imageFile!.path),
                            fit: BoxFit.cover,
                          )
                  else if (resolvedImagePath != null)
                    AppImage(
                      imagePath: resolvedImagePath,
                      fit: BoxFit.cover,
                      fallback: Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          LucideIcons.imageOff,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        LucideIcons.utensils,
                        size: 60,
                        color: Colors.grey,
                      ),
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
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Meal Items',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showEditSheet(context, ref, result),
                        child: const Text(
                          'Edit Items',
                          style: TextStyle(
                            color: Color(0xFF027B3D),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    result.detectedItems.isEmpty
                        ? 'Add visible foods manually if AI could not identify them'
                        : 'AI estimate from the photo. Review before logging',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (result.detectedItems.isEmpty)
                    _buildEmptyItemsCard(context, ref, result)
                  else
                    ...result.detectedItems.map(
                      (item) =>
                          _buildItemCard(context, item, result.healthLabel),
                    ),

                  const SizedBox(height: 32),

                  // Nutri-Insight
                  _buildNutriInsightCard(
                    result.suggestions.firstOrNull ??
                        (result.healthLabel == 'avoid'
                            ? 'Consider healthier alternatives for this meal.'
                            : result.healthLabel == 'moderate'
                            ? 'A decent choice, but look for ways to add more nutrients.'
                            : 'Your meal is well-balanced!'),
                    result.healthLabel,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(
        context,
        result.totalCalories,
        ref,
      ),
    );
  }

  Widget _buildEmptyItemsCard(
    BuildContext context,
    WidgetRef ref,
    MealAnalysis result,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.listPlus,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            'Add foods from the catalog',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use the photo as a reference, then select the visible foods and adjust portions.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showEditSheet(context, ref, result),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Food'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    DetectedFoodItem item,
    String mealHealthLabel,
  ) {
    final theme = Theme.of(context);
    // Determine health label color based on meal context or simple keywords
    final name = item.name.toLowerCase();

    // Default to meal's health label if it's "avoid"
    bool isUnhealthy =
        mealHealthLabel == 'avoid' &&
        (name.contains('fried') ||
            name.contains('samosa') ||
            name.contains('sweet'));
    bool isHealthy =
        name.contains('dal') ||
        name.contains('veg') ||
        name.contains('salad') ||
        name.contains('fruit');

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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${item.quantity.toStringAsFixed(1)} ${item.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(item.calories * item.quantity).round()} kcal',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutriInsightCard(String insight, String healthLabel) {
    final bool isAvoid = healthLabel == 'avoid';
    final Color bgColor = isAvoid
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFE7F3ED);
    final Color iconColor = isAvoid
        ? const Color(0xFFEF4444)
        : const Color(0xFF027B3D);
    final Color textColor = isAvoid
        ? const Color(0xFF7F1D1D)
        : const Color(0xFF0D3B2E);

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
                size: 20,
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF027B3D),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        onPressed: () => _logMeal(context, ref),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Log this Meal',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$total kcal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    MealAnalysis result,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EditItemsSheet(result: result);
      },
    );
  }

  Future<void> _logMeal(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;

    try {
      await ref
          .read(mealScanControllerProvider.notifier)
          .saveCurrentMeal(uid: uid);
      ref.invalidate(dailySummaryProvider);
      ref.invalidate(recentMealsProvider);
      ref.read(mealScanControllerProvider.notifier).reset();
      if (context.mounted) context.go('/dashboard');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
      );
    }
  }

  String? _resolveImagePath(String baseUrl, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('http') || AppImage.isLocalPath(imageUrl)) {
      return imageUrl;
    }
    return '$baseUrl$imageUrl';
  }
}

List<DetectedFoodItem> _mergeFoodItem(
  List<DetectedFoodItem> currentItems,
  DetectedFoodItem newItem,
) {
  final items = List<DetectedFoodItem>.from(currentItems);
  final existingIndex = items.indexWhere((item) => item.name == newItem.name);

  if (existingIndex >= 0) {
    final current = items[existingIndex];
    items[existingIndex] = current.copyWith(
      quantity: (current.quantity + 1).clamp(0.1, 5.0).toDouble(),
    );
    return items;
  }

  items.add(newItem);
  return items;
}

MealAnalysis _mealWithItems(
  MealAnalysis analysis,
  List<DetectedFoodItem> items,
) {
  final totals = _mealMacroTotals(items);

  return analysis.copyWith(
    detectedItems: items,
    totalCalories: totals['totalCalories'],
    healthLabel: _mealHealthLabel(totals['totalCalories'] ?? 0),
    suggestions: _mealSuggestions(totals),
  );
}

Map<String, int> _mealMacroTotals(List<DetectedFoodItem> items) {
  var calories = 0;
  var protein = 0;
  var carbs = 0;
  var fat = 0;

  for (final item in items) {
    calories += (item.calories * item.quantity).round();
    protein += (item.protein * item.quantity).round();
    carbs += (item.carbs * item.quantity).round();
    fat += (item.fat * item.quantity).round();
  }

  return {
    'totalCalories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };
}

String _mealHealthLabel(int calories) {
  if (calories >= 800) return 'avoid';
  if (calories <= 450) return 'healthy';
  return 'moderate';
}

List<String> _mealSuggestions(Map<String, int> totals) {
  final calories = totals['totalCalories'] ?? 0;
  final protein = totals['protein'] ?? 0;
  return [
    'This estimate is based on the foods and portions you selected.',
    if (protein < 15)
      'Protein looks light. Add dal, paneer, eggs, curd, tofu, or lean meat if it matches the meal.',
    if (calories >= 800)
      'This is calorie-dense. Consider a smaller portion or lighter next meal.',
  ];
}

class _EditItemsSheet extends ConsumerStatefulWidget {
  final MealAnalysis result;

  const _EditItemsSheet({required this.result});

  @override
  ConsumerState<_EditItemsSheet> createState() => _EditItemsSheetState();
}

class _EditItemsSheetState extends ConsumerState<_EditItemsSheet> {
  late List<DetectedFoodItem> _items;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List<DetectedFoodItem>.from(widget.result.detectedItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _save() {
    final newResult = _mealWithItems(widget.result, _items);

    ref.read(mealScanControllerProvider.notifier).updateResult(newResult);
    Navigator.pop(context);
  }

  Future<void> _addFood() async {
    final selected = await showModalBottomSheet<DetectedFoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FoodCatalogPicker(),
    );

    if (selected == null) return;
    _addItem(selected);
  }

  void _addItem(DetectedFoodItem item) {
    setState(() => _items = _mergeFoodItem(_items, item));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Edit Items',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addFood,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Food'),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      'No foods added yet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final itemCalories = (item.calories * item.quantity)
                          .round();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$itemCalories kcal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF027B3D),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    setState(() => _items.removeAt(index));
                                  },
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    size: 17,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Qty: ${item.quantity.toStringAsFixed(1)} ${item.unit}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Expanded(
                                  child: Slider(
                                    value: item.quantity,
                                    min: 0.1,
                                    max: 5.0,
                                    activeColor: const Color(0xFF027B3D),
                                    onChanged: (v) {
                                      setState(() {
                                        _items[index] = item.copyWith(
                                          quantity: v,
                                        );
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _FoodCatalogPicker extends StatefulWidget {
  const _FoodCatalogPicker();

  @override
  State<_FoodCatalogPicker> createState() => _FoodCatalogPickerState();
}

class _FoodCatalogPickerState extends State<_FoodCatalogPicker> {
  final _searchController = TextEditingController();
  List<DetectedFoodItem> _results = LocalFoodCatalog.items;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() => _results = LocalFoodCatalog.search(query));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Add Food',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
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
          TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(LucideIcons.search, size: 18),
              hintText: 'Search foods',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (context, index) => Divider(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              itemBuilder: (context, index) {
                final item = _results[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${item.calories} kcal per ${item.unit} • P ${item.protein}g • C ${item.carbs}g • F ${item.fat}g',
                  ),
                  trailing: const Icon(LucideIcons.plus, size: 18),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
