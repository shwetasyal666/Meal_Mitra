import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/core/services/camera/camera_capture_service.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/dashboard/data/dashboard_repository.dart';
import 'package:mealmitra/features/meal_scan/presentation/controllers/meal_scan_controller.dart';

class MealScanPage extends ConsumerStatefulWidget {
  const MealScanPage({super.key});

  @override
  ConsumerState<MealScanPage> createState() => _MealScanPageState();
}

class _MealScanPageState extends ConsumerState<MealScanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  String _selectedMealType = 'Lunch';
  bool _isPickerActive = false;

  @override
  void initState() {
    super.initState();
    _setInitialMealType();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scannerAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );
  }

  void _setInitialMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _selectedMealType = 'Breakfast';
    } else if (hour < 16) {
      _selectedMealType = 'Lunch';
    } else if (hour < 19) {
      _selectedMealType = 'Snack';
    } else {
      _selectedMealType = 'Dinner';
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleCapture() async {
    if (_isPickerActive) return;
    setState(() => _isPickerActive = true);
    try {
      final file = await ref.read(cameraCaptureServiceProvider).captureFromCamera();
      if (file != null && mounted) {
        _startAnalysis(file);
      }
    } finally {
      if (mounted) setState(() => _isPickerActive = false);
    }
  }

  Future<void> _handleGallery() async {
    if (_isPickerActive) return;
    setState(() => _isPickerActive = true);
    try {
      final file = await ref.read(cameraCaptureServiceProvider).selectFromGallery();
      if (file != null && mounted) {
        _startAnalysis(file);
      }
    } finally {
      if (mounted) setState(() => _isPickerActive = false);
    }
  }

  Future<void> _startAnalysis(XFile file) async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;

    final mealType = _selectedMealType;

    // Check for duplicates
    final meals = ref.read(recentMealsProvider).value ?? [];
    final existingMeal = (meals as List).where(
      (m) => m.mealType.toLowerCase() == mealType.toLowerCase(),
    ).firstOrNull;

    if (existingMeal != null && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplicate Meal Detected'),
          content: Text('You already have a $mealType logged for today. Would you like to replace it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Delete existing meal
      try {
        await ref.read(mealScanRepositoryProvider).deleteMeal(existingMeal.id);
        // Invalidate summary and meals to refresh dashboard
        ref.invalidate(dailySummaryProvider);
        ref.invalidate(recentMealsProvider);
      } catch (e) {
        debugPrint('Failed to delete existing meal: $e');
      }
    }

    ref.read(mealScanControllerProvider.notifier).scan(
          uid: uid,
          imageFile: file,
          mealType: mealType,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(mealScanControllerProvider).state;
    final isProcessing = scanState.status == MealScanStatus.uploading ||
        scanState.status == MealScanStatus.analyzing;

    // Listen for completion and navigate
    ref.listen(mealScanControllerProvider, (previous, next) {
      if (next.state.status == MealScanStatus.completed) {
        context.push('/analysis');
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Camera Preview (Background)
          Positioned.fill(
            child: Container(
              color: Colors.grey[900],
              child: const Icon(LucideIcons.camera, color: Colors.white24, size: 80),
            ),
          ),

          // Scanning Overlay
          _buildScannerOverlay(isProcessing),

          // UI Controls
          SafeArea(
            child: Column(
              children: [
                _buildTopControls(context),
                const SizedBox(height: 16),
                _buildMealTypeSelector(),
                const Spacer(),
                if (!isProcessing) _buildBottomControls(),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Error Overlay
          if (scanState.status == MealScanStatus.failed)
            _buildErrorOverlay(scanState.errorMessage ?? 'Analysis failed'),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(bool isProcessing) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main Frame
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          
          // corners
          ..._buildCorners(),

          // Scanning Badge
          if (isProcessing)
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF027B3D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SCANNING...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Scanning Line
          if (isProcessing)
            AnimatedBuilder(
              animation: _scannerAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 280 * _scannerAnimation.value,
                  child: Container(
                    width: 260,
                    height: 2,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [Colors.transparent, Color(0xFF4ADE80), Colors.transparent],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const double length = 40.0;
    const double thickness = 4.0;

    return [
      // Top Left
      Positioned(top: 0, left: 0, child: _cornerBlock(top: thickness, left: length)),
      Positioned(top: 0, left: 0, child: _cornerBlock(top: length, left: thickness)),
      // Top Right
      Positioned(top: 0, right: 0, child: _cornerBlock(top: thickness, left: length)),
      Positioned(top: 0, right: 0, child: _cornerBlock(top: length, left: thickness)),
      // Bottom Left
      Positioned(bottom: 0, left: 0, child: _cornerBlock(top: thickness, left: length)),
      Positioned(bottom: 0, left: 0, child: _cornerBlock(top: length, left: thickness)),
      // Bottom Right
      Positioned(bottom: 0, right: 0, child: _cornerBlock(top: thickness, left: length)),
      Positioned(bottom: 0, right: 0, child: _cornerBlock(top: length, left: thickness)),
    ];
  }

  Widget _cornerBlock({required double top, required double left}) {
    return Container(
      width: left,
      height: top,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTopControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(LucideIcons.x, color: Colors.white),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Text(
              'Point at your thali for best results',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.zap, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _handleGallery,
            icon: const Icon(LucideIcons.image, color: Colors.white, size: 28),
          ),
          GestureDetector(
            onTap: _handleCapture,
            child: Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.sparkles, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    final types = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: types.map((type) {
            final isSelected = _selectedMealType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedMealType = type),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF027B3D) : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(String message) {
    return Positioned(
      bottom: 120,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.circleAlert, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
