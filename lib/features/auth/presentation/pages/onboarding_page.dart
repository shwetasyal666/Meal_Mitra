import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/profile/data/profile_repository.dart';
import 'package:mealmitra/features/profile/domain/daily_calorie_target_calculator.dart';
import 'package:mealmitra/features/profile/domain/user_profile.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1 — Body Metrics
  final _ageController = TextEditingController(text: '25');
  String _gender = 'Male';
  double _height = 170;
  double _weight = 70;

  // Step 2 — Goals
  ProfileGoal _goal = ProfileGoal.maintain;
  ActivityLevel _activity = ActivityLevel.moderate;

  // Step 3 — Health Conditions
  final List<String> _availableConditions = [
    'Diabetes',
    'Hypertension',
    'High Cholesterol',
    'Thyroid',
    'PCOS',
    'Heart Disease',
  ];
  final Set<String> _selectedConditions = {};
  bool _noConditions = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate age
      final age = int.tryParse(_ageController.text);
      if (age == null || age < 10 || age > 120) {
        _showError('Please enter a valid age (10-120)');
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _saveProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final uid = ref.read(authStateProvider).value;
      if (uid == null) return;

      final age = int.parse(_ageController.text);
      final target = DailyCalorieTargetCalculator.calculate(
        age: age,
        heightCm: _height,
        weightKg: _weight,
        gender: _gender,
        goal: _goal,
        activityLevel: _activity,
      );

      final conditions = _noConditions
          ? <String>[]
          : _selectedConditions.toList();

      // Fetch the displayName set during registration (uses raw fetch, not completeness-checked)
      final displayName =
          await ref.read(profileRepositoryProvider).fetchDisplayName() ?? '';

      final profile = UserProfile(
        uid: uid,
        displayName: displayName,
        gender: _gender,
        age: age,
        heightCm: _height,
        weightKg: _weight,
        goal: _goal,
        activityLevel: _activity,
        dailyCalorieTarget: target,
        healthConditions: conditions,
      );

      await ref.read(profileRepositoryProvider).saveProfile(profile);
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      if (mounted) _showError('Failed to save profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient background
          // Container(
          //   decoration: const BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topCenter,
          //       end: Alignment.bottomCenter,
          //       colors: [
          //         Color(0xFF0D5C4B),
          //         Color(0xFF147A5E),
          //         Color(0xFF1A8F6E),
          //       ],
          //     ),
          //   ),
          // ),

          // Floating decorative bubbles
          ..._buildFloatingBubbles(),

          SafeArea(
            child: Column(
              children: [
                // Top bar with back button and step indicator
                _buildTopBar(),

                // Step progress bar
                _buildProgressBar(),

                const SizedBox(height: 8),

                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1BodyMetrics(),
                      _buildStep2Goals(),
                      _buildStep3Health(),
                    ],
                  ),
                ),

                // Bottom navigation buttons
                _buildBottomButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final stepTitles = ['Body Metrics', 'Your Goals', 'Health Info'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              onPressed: _previousStep,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
                size: 20,
              ),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                stepTitles[_currentStep],
                key: ValueKey(_currentStep),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Text(
            '${_currentStep + 1}/3',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive
                    ? const Color(0xFF027B3D)
                    : Colors.black.withValues(alpha: 0.2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── STEP 1: Body Metrics ─────────────────────────────────────────────

  Widget _buildStep1BodyMetrics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Illustration
            _buildStepIcon(Icons.accessibility_new_rounded),
            const SizedBox(height: 8),
            Text(
              'Tell us about yourself',
              style: TextStyle(
                color: Color(0xFF027B3D).withValues(alpha: 0.8),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 28),

            // Gender Selection
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Sex at Birth', Icons.people_outline),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildGenderChoice('Male', '👨')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildGenderChoice('Female', '👩')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Age input
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Age', Icons.cake_outlined),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.08),
                      hintText: '25',
                      hintStyle: TextStyle(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      suffixText: 'years',
                      suffixStyle: TextStyle(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Height slider
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Height', Icons.height_rounded),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _height.round().toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'cm',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF027B3D),
                      inactiveTrackColor: Colors.black.withValues(alpha: 0.15),
                      thumbColor: const Color(0xFF027B3D),
                      overlayColor: const Color(0xFF027B3D).withValues(alpha: 0.2),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: _height,
                      min: 100,
                      max: 250,
                      onChanged: (v) => setState(() => _height = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '100 cm',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '250 cm',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Weight slider
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Weight', Icons.monitor_weight_outlined),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _weight.round().toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'kg',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF027B3D),
                      inactiveTrackColor: Colors.black.withValues(alpha: 0.15),
                      thumbColor: const Color(0xFF027B3D),
                      overlayColor: const Color(0xFF027B3D).withValues(alpha: 0.2),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: _weight,
                      min: 30,
                      max: 200,
                      onChanged: (v) => setState(() => _weight = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '30 kg',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '200 kg',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── STEP 2: Goals & Activity ─────────────────────────────────────────

  Widget _buildStep2Goals() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildStepIcon(Icons.flag_rounded),
          const SizedBox(height: 8),
          Text(
            'What do you want to achieve?',
            style: TextStyle(
              color: Color(0xFF027B3D).withValues(alpha: 0.8),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),

          // Goal selection cards
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Goal', Icons.track_changes_rounded),
                const SizedBox(height: 16),
                ...ProfileGoal.values.map((goal) => _buildGoalCard(goal)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Activity level cards
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel(
                  'Activity Level',
                  Icons.directions_run_rounded,
                ),
                const SizedBox(height: 16),
                ...ActivityLevel.values.map(
                  (level) => _buildActivityCard(level),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGoalCard(ProfileGoal goal) {
    final isSelected = _goal == goal;
    final labels = {
      ProfileGoal.lose: ('Lose Weight', '🔥', 'Reduce body fat & slim down'),
      ProfileGoal.maintain: ('Maintain', '⚖️', 'Keep your current weight'),
      ProfileGoal.gain: ('Gain Weight', '💪', 'Build muscle & mass'),
    };
    final (title, emoji, subtitle) = labels[goal]!;

    return GestureDetector(
      onTap: () => setState(() => _goal = goal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF027B3D).withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF027B3D)
                : Colors.black.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF027B3D)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF027B3D)
                      : Colors.black.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityLevel level) {
    final isSelected = _activity == level;
    final labels = {
      ActivityLevel.low: ('Sedentary', '🪑', 'Little or no exercise'),
      ActivityLevel.moderate: ('Moderate', '🚶', 'Exercise 3-5 days/week'),
      ActivityLevel.high: ('Active', '🏃', 'Exercise 6-7 days/week'),
    };
    final (title, emoji, subtitle) = labels[level]!;

    return GestureDetector(
      onTap: () => setState(() => _activity = level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF027B3D).withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF027B3D)
                : Colors.black.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF027B3D)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF027B3D)
                      : Colors.black.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 3: Health Conditions ────────────────────────────────────────

  Widget _buildStep3Health() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildStepIcon(Icons.health_and_safety_rounded),
          const SizedBox(height: 8),
          Text(
            'Any health conditions we should know?',
            style: TextStyle(
              color: Color(0xFF027B3D).withValues(alpha: 0.8),
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'This helps us personalize your meal recommendations',
            style: TextStyle(
              color: Color(0xFF027B3D).withValues(alpha: 0.5),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel(
                  'Select all that apply',
                  Icons.checklist_rounded,
                ),
                const SizedBox(height: 16),

                // "None" option
                _buildConditionChip(
                  label: 'None of the above',
                  emoji: '✅',
                  isSelected: _noConditions,
                  onTap: () {
                    setState(() {
                      _noConditions = !_noConditions;
                      if (_noConditions) _selectedConditions.clear();
                    });
                  },
                ),
                const SizedBox(height: 10),

                Divider(color: Colors.black.withValues(alpha: 0.1)),
                const SizedBox(height: 10),

                // Health conditions
                ..._availableConditions.map((condition) {
                  final emoji = _conditionEmoji(condition);
                  final isSelected = _selectedConditions.contains(condition);
                  return _buildConditionChip(
                    label: condition,
                    emoji: emoji,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _noConditions = false;
                        if (isSelected) {
                          _selectedConditions.remove(condition);
                        } else {
                          _selectedConditions.add(condition);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGenderChoice(String label, String emoji) {
    final isSelected = _gender == label;
    return GestureDetector(
      onTap: () => setState(() => _gender = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF027B3D).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF027B3D)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionChip({
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF027B3D).withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF027B3D)
                : Colors.black.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isSelected
                    ? const Color(0xFF027B3D)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF027B3D)
                      : Colors.black.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _conditionEmoji(String condition) {
    return switch (condition) {
      'Diabetes' => '🩸',
      'Hypertension' => '❤️‍🩹',
      'High Cholesterol' => '🫀',
      'Thyroid' => '🦋',
      'PCOS' => '🩺',
      'Heart Disease' => '💗',
      _ => '🏥',
    };
  }

  // ─── Shared UI components ─────────────────────────────────────────────

  Widget _buildBottomButtons() {
    final isLastStep = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        children: [
          // Main action button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Color(0xFF027B3D),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF027B3D).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: _isSaving ? null : _nextStep,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: Color(0xFF027B3D),
                shadowColor: Color(0xFF027B3D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (!isLastStep) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.rocket_launch_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
            ),
          ),

          if (_currentStep == 2) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _noConditions = true;
                        _selectedConditions.clear();
                      });
                      _saveProfile();
                    },
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: Color(0xFF027B3D).withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIcon(IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Color(0xFF027B3D).withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: Color(0xFF027B3D).withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Icon(icon, size: 36, color: const Color(0xFF027B3D)),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF027B3D).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFF027B3D).withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF027B3D).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF027B3D)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF027B3D),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFloatingBubbles() {
    final random = Random(77);
    return List.generate(5, (index) {
      final size = 50.0 + random.nextDouble() * 100;
      final top = random.nextDouble() * 800;
      final left = random.nextDouble() * 400;
      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(
              0xFF027B3D,
            ).withValues(alpha: 0.02 + random.nextDouble() * 0.03),
          ),
        ),
      );
    });
  }
}
