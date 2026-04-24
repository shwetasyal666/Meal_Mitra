import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmitra/app/layout/main_layout.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInPage()),
      GoRoute(path: '/sign-up', builder: (context, state) => const SignUpPage()),
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
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final matchedLocation = state.matchedLocation;
      final isOnAuthPage = matchedLocation == '/sign-in' || matchedLocation == '/sign-up';

      if (!isLoggedIn && !isOnAuthPage) return '/sign-in';
      if (isLoggedIn && isOnAuthPage) return '/';

      if (isLoggedIn) {
        final currentProfile = ref.watch(currentProfileProvider);
        if (currentProfile.isLoading) return null;
        
        final hasProfile = currentProfile.value != null;
        final isOnOnboarding = matchedLocation == '/onboarding';
        final isOnProfile = matchedLocation == '/profile';

        if (!hasProfile && !isOnOnboarding && !isOnProfile) return '/onboarding';
        if (hasProfile && matchedLocation == '/') return '/dashboard';
      }

      return null;
    },
  );
});
