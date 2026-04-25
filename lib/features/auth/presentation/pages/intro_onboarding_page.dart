import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

/// A premium, interactive intro onboarding shown to first-time users.
/// Covers app features with rich animations before leading to sign-up/sign-in.
class IntroOnboardingPage extends StatefulWidget {
  const IntroOnboardingPage({super.key});

  @override
  State<IntroOnboardingPage> createState() => _IntroOnboardingPageState();
}

class _IntroOnboardingPageState extends State<IntroOnboardingPage>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;

  static const _primaryGreen = Color(0xFF027B3D);
  static const _darkGreen = Color(0xFF015A2C);
  static const _lightGreen = Color(0xFFE8F5E9);

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.camera_alt_rounded,
      emoji: '📸',
      title: 'Scan Your Meals',
      subtitle: 'Point your camera at any Indian meal',
      description:
          'Our AI instantly identifies food items, estimates calories, and breaks down macros — all from a single photo.',
      gradient: [Color(0xFF027B3D), Color(0xFF03A94D)],
      features: ['Instant Recognition', 'Indian Cuisine Expert', 'Accurate Macros'],
    ),
    _OnboardingSlide(
      icon: Icons.insights_rounded,
      emoji: '📊',
      title: 'Smart Insights',
      subtitle: 'Personalized nutrition guidance',
      description:
          'Get health labels, meal suggestions, and daily calorie tracking — all tailored to your body and goals.',
      gradient: [Color(0xFF0D7C66), Color(0xFF14A085)],
      features: ['Health Labels', 'Goal Tracking', 'Daily Summary'],
    ),
    _OnboardingSlide(
      icon: Icons.trending_up_rounded,
      emoji: '🏆',
      title: 'Track Progress',
      subtitle: 'Watch your evolution over time',
      description:
          'Visualize your weight trends, calorie patterns, and nutrition history with beautiful interactive charts.',
      gradient: [Color(0xFF015A2C), Color(0xFF027B3D)],
      features: ['Weight Charts', 'Calorie Trends', 'Weekly Reports'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);
    if (mounted) {
      context.go('/sign-in');
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  _lightGreen.withValues(alpha: 0.3),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Floating particles
          ..._buildParticles(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 20),
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          color: _primaryGreen.withValues(alpha: 0.6),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _slideController.reset();
                      _slideController.forward();
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) =>
                        _buildSlide(_slides[index], index),
                  ),
                ),

                // Page indicators + navigation
                _buildBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: FadeTransition(
        opacity: _slideController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // Animated icon with gradient circle
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: slide.gradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: slide.gradient[0].withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      slide.emoji,
                      style: const TextStyle(fontSize: 56),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                slide.title,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _darkGreen,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                slide.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _primaryGreen.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                slide.description,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Feature chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: slide.features.map((f) => _buildFeatureChip(f, slide.gradient[0])).toList(),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final isLastPage = _currentPage == _slides.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? _primaryGreen
                      : _primaryGreen.withValues(alpha: 0.2),
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Main CTA button
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLastPage
                      ? [_primaryGreen, const Color(0xFF03A94D)]
                      : [_primaryGreen, _primaryGreen],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastPage ? 'Get Started' : 'Next',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLastPage
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (isLastPage) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/sign-in'),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        color: _primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildParticles() {
    final random = Random(42);
    return List.generate(8, (index) {
      final size = 30.0 + random.nextDouble() * 80;
      final top = random.nextDouble() * 800;
      final left = random.nextDouble() * 400;
      final opacity = 0.02 + random.nextDouble() * 0.04;

      return Positioned(
        top: top,
        left: left,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 1000 + index * 200),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value * opacity,
              child: child,
            );
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryGreen,
            ),
          ),
        ),
      );
    });
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;
  final List<String> features;

  const _OnboardingSlide({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.features,
  });
}
