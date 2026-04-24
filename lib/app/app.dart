import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/app/router/app_router.dart';
import 'package:mealmitra/app/theme/app_theme.dart';

class MealMitraApp extends ConsumerWidget {
  const MealMitraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MealMitra',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
