import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/core/widgets/app_image.dart';
import 'package:mealmitra/features/dashboard/data/dashboard_repository.dart';
import 'package:mealmitra/features/profile/data/profile_repository.dart';
import 'package:mealmitra/features/meal_history/presentation/widgets/meal_details_sheet.dart';
import 'package:mealmitra/features/meal_history/domain/meal_record.dart';
import 'package:mealmitra/features/dashboard/presentation/widgets/recommendations_sheet.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  static const double _dateItemWidth = 54;
  static const double _dateItemGap = 12;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  ScrollController? _dateScrollController;

  ScrollController get _resolvedDateScrollController =>
      _dateScrollController ??= ScrollController();

  @override
  void initState() {
    super.initState();
    _resolvedDateScrollController;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resetDashboardDateToToday();
      _scrollDateStripToToday();
    });
  }

  @override
  void dispose() {
    _dateScrollController?.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _resetDashboardDateToToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDate = ref.read(selectedDateProvider);

    if (!DateUtils.isSameDay(selectedDate, today)) {
      ref.read(selectedDateProvider.notifier).updateDate(today);
    }
  }

  void _scrollDateStripToToday() {
    final controller = _resolvedDateScrollController;

    if (!controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollDateStripToToday();
      });
      return;
    }

    final maxOffset = controller.position.maxScrollExtent;
    controller.jumpTo(maxOffset);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final summary = ref.watch(dailySummaryProvider);
    final meals = ref.watch(recentMealsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Let MainLayout handle it
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(context),

            // Content
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF027B3D),
                onRefresh: () async {
                  ref.invalidate(dailySummaryProvider);
                  ref.invalidate(recentMealsProvider);
                },
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      children: [
                        // Date Selector
                        _buildDateSelector(context, ref, selectedDate),
                        const SizedBox(height: 24),

                        // Greeting + calorie card
                        _buildCalorieCard(profile, summary),
                        const SizedBox(height: 32),

                        // Recent scans header
                        Row(
                          children: [
                            Text(
                              'Recent Scans',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.go('/history'),
                              child: const Text(
                                'View Diary',
                                style: TextStyle(
                                  color: Color(0xFF027B3D),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Horizontal Scan List
                        _buildHorizontalScanList(meals),
                        const SizedBox(height: 32),

                        // Vitality Score Card
                        _buildVitalityScoreCard(),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
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
          _buildIconBtn(LucideIcons.bell, () {}),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    final now = DateTime.now();
    final dates = List.generate(
      31,
      (index) => now.subtract(Duration(days: 30 - index)),
    );

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        padding: EdgeInsets.zero,
        controller: _resolvedDateScrollController,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final isToday = DateUtils.isSameDay(date, now);

          return GestureDetector(
            onTap: () {
              ref.read(selectedDateProvider.notifier).updateDate(date);
              if (isToday) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _scrollDateStripToToday();
                });
              }
            },
            child: Container(
              width: _dateItemWidth,
              margin: const EdgeInsets.only(right: _dateItemGap),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF027B3D) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.black.withValues(alpha: 0.04),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF027B3D).withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.black26,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF027B3D),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black54, size: 20),
      ),
    );
  }

  Widget _buildCalorieCard(
    AsyncValue<dynamic> profile,
    AsyncValue<dynamic> summary,
  ) {
    return profile.when(
      data: (value) {
        final target = value?.dailyCalorieTarget ?? 2000;
        final consumed = summary.value?.totalCalories ?? 0;
        final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
        final isOverLimit = target > 0 && consumed > target;
        final progressColor = isOverLimit ? const Color(0xFFEF4444) : const Color(0xFF027B3D);

        return Column(
          children: [
            const SizedBox(height: 10),
            // Gauge
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 16,
                      color: progressColor.withValues(alpha: 0.04),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutQuart,
                      builder: (context, value, _) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 16,
                          strokeCap: StrokeCap.round,
                          color: progressColor,
                        );
                      },
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ENERGY BALANCE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.black38,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            consumed.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: isOverLimit ? progressColor : Colors.black,
                              fontSize: 54,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            ' / $target',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black26,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isOverLimit ? 'kcal over limit' : 'kcal consumed',
                        style: TextStyle(
                          color: progressColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Macro summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroBar(
                  'PROTEIN',
                  summary.value?.totalProtein ?? 0,
                  ((target * 0.3) / 4).round(),
                  const Color(0xFF027B3D),
                ),
                _buildMacroBar(
                  'CARBS',
                  summary.value?.totalCarbs ?? 0,
                  ((target * 0.4) / 4).round(),
                  const Color(0xFFEAB308),
                ),
                _buildMacroBar(
                  'FATS',
                  summary.value?.totalFats ?? 0,
                  ((target * 0.3) / 9).round(),
                  const Color(0xFFEF4444),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(child: Text('Error loading stats')),
    );
  }

  Widget _buildMacroBar(String label, int current, int target, Color color) {
    final progress = (current / target).clamp(0.0, 1.0);
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.black38,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 8,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 8,
            height: 60 * progress,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${current}g',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: ' / ${target}g',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black26,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalScanList(AsyncValue<List<dynamic>> meals) {
    return SizedBox(
      height: 180,
      child: meals.when(
        data: (mealList) {
          if (mealList.isEmpty) {
            return const Center(child: Text('No scans today'));
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mealList.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) => _buildScanCard(mealList[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Error loading scans')),
      ),
    );
  }

  Widget _buildScanCard(dynamic mealData) {
    final api = ref.watch(apiClientProvider);
    // Ensure we have a MealRecord object
    final meal = mealData is MealRecord
        ? mealData
        : MealRecord.fromMap(mealData['id'] ?? '', mealData);
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
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                      imagePath: imageUrl,
                      fit: BoxFit.cover,
                      fallback: Container(color: Colors.grey[100]),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF027B3D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LOGGED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.mealType.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '${meal.totalCalories} kcal',
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
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

  Widget _buildVitalityScoreCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F3ED),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.sparkles, color: Color(0xFF027B3D), size: 20),
              SizedBox(width: 12),
              Text(
                'Vitality Insight',
                style: TextStyle(
                  color: Color(0xFF0D3B2E),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'You\'re doing great! Your fiber intake is up 20% today compared to your weekly average.',
            style: TextStyle(
              color: Color(0xFF0D3B2E),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const RecommendationsSheet(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF027B3D),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: const Text('Explore Recommendations'),
          ),
        ],
      ),
    );
  }
}
