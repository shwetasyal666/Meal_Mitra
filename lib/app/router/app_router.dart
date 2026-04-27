import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmitra/app/layout/main_layout.dart';
import 'package:mealmitra/features/auth/data/auth_repository.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/auth/presentation/pages/sign_in_page.dart';
import 'package:mealmitra/features/auth/presentation/pages/sign_up_page.dart';
import 'package:mealmitra/features/auth/presentation/pages/onboarding_page.dart';
import 'package:mealmitra/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:mealmitra/features/dashboard/presentation/pages/evolution_page.dart';
import 'package:mealmitra/features/meal_history/presentation/pages/meal_history_page.dart';
import 'package:mealmitra/features/meal_scan/presentation/pages/meal_scan_page.dart';
import 'package:mealmitra/features/meal_scan/presentation/pages/meal_analysis_page.dart';
import 'package:mealmitra/features/profile/data/profile_repository.dart';
import 'package:mealmitra/features/profile/presentation/pages/profile_page.dart';
import 'package:mealmitra/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:mealmitra/features/auth/presentation/pages/email_verification_page.dart';
import 'package:mealmitra/features/auth/presentation/pages/intro_onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final hasSeenIntroProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasSeenIntro') ?? false;
});

final emailVerifiedProvider = FutureProvider<bool>((ref) async {
  // Watch auth state so this re-evaluates when the user logs in or out
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) return false;
  return ref.read(authRepositoryProvider).isEmailVerified();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasSeenIntroState = ref.watch(hasSeenIntroProvider);
  final emailVerifiedState = ref.watch(emailVerifiedProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(path: '/intro', builder: (context, state) => const IntroOnboardingPage()),
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInPage()),
      GoRoute(path: '/sign-up', builder: (context, state) => const SignUpPage()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(path: '/verify-email', builder: (context, state) => const EmailVerificationPage()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
      
      // Main Shell for persistent BottomNav
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(
            location: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
          GoRoute(path: '/evolution', builder: (context, state) => const EvolutionPage()),
          GoRoute(path: '/history', builder: (context, state) => const MealHistoryPage()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        ],
      ),

      // Full screen routes
      GoRoute(path: '/scan', builder: (context, state) => const MealScanPage()),
      GoRoute(path: '/analysis', builder: (context, state) => const MealAnalysisPage()),
    ],
    redirect: (context, state) {
      if (authState.isLoading || hasSeenIntroState.isLoading) return null;

      final hasSeenIntro = hasSeenIntroState.value ?? false;
      final isLoggedIn = authState.value != null;
      final matchedLocation = state.matchedLocation;
      
      final isOnAuthPage = matchedLocation == '/sign-in' || 
                           matchedLocation == '/sign-up' || 
                           matchedLocation == '/forgot-password';
      final isIntroPage = matchedLocation == '/intro';

      if (!hasSeenIntro && !isIntroPage) return '/intro';
      if (hasSeenIntro && isIntroPage && !isLoggedIn) return '/sign-in';

      if (!isLoggedIn && !isOnAuthPage && !isIntroPage) return '/sign-in';
      if (isLoggedIn && (isOnAuthPage || isIntroPage) && matchedLocation != '/') return '/';

      if (isLoggedIn) {
        if (emailVerifiedState.isLoading) return null;
        final isVerified = emailVerifiedState.value ?? false;
        
        if (!isVerified && matchedLocation != '/verify-email') {
          return '/verify-email';
        }
        
        if (isVerified && matchedLocation == '/verify-email') {
          return '/';
        }

        if (isVerified) {
          final currentProfile = ref.watch(currentProfileProvider);
          if (currentProfile.isLoading) return null;
          
          final hasProfile = currentProfile.value != null;
          final isOnOnboarding = matchedLocation == '/onboarding';
          final isOnProfile = matchedLocation == '/profile';

          if (!hasProfile && !isOnOnboarding && !isOnProfile) return '/onboarding';
          if (hasProfile && matchedLocation == '/') return '/dashboard';
        }
      }

      return null;
    },
  );
});
