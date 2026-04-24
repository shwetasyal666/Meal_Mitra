# MealMitra MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first working MealMitra MVP with Firebase-backed auth, profile onboarding, camera/gallery meal capture, Cloud Function meal analysis, cloud-synced history, and daily calorie summaries.

**Architecture:** Keep the Flutter app feature-first and user-experience focused, with Firebase Auth, Firestore, Storage, and Cloud Functions as the backend source of truth. The mobile app captures images, uploads them, and renders results; Cloud Functions own API secrets, meal analysis orchestration, rule-based health scoring, quantity suggestions, and persistence.

**Tech Stack:** Flutter, Dart, `flutter_riverpod`, `go_router`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `cloud_functions`, `google_sign_in`, `image_picker`, TypeScript, Firebase Functions v2, Firebase Emulator Suite, `vitest`, `zod`

---

## Assumptions Locked In By This Plan

- Firebase project id: `mealmitra-dev`
- Initial auth provider: Google sign-in
- Initial meal capture implementation: `image_picker` using `ImageSource.camera` and `ImageSource.gallery`
- Initial AI integration shape: Cloud Functions call a real vision endpoint through `visionProvider.ts`, then normalize calorie estimates through `nutritionProvider.ts`
- The mobile app writes user profile data directly to Firestore, while meal analysis writes happen only from Cloud Functions

## File Structure Map

### Flutter app

- `pubspec.yaml`: add Firebase, routing, state, image, and test packages
- `lib/main.dart`: bootstrap entrypoint
- `lib/app/bootstrap.dart`: initialize Flutter bindings and Firebase
- `lib/app/app.dart`: root `MaterialApp.router`
- `lib/app/router/app_router.dart`: route tree and auth/profile redirects
- `lib/app/theme/app_theme.dart`: app theme and color system
- `lib/core/config/app_environment.dart`: collection names, function names, and storage path helpers
- `lib/core/errors/app_exception.dart`: shared UI-safe exception type
- `lib/core/services/firebase/firebase_providers.dart`: Riverpod providers for Firebase services
- `lib/core/services/camera/camera_capture_service.dart`: camera/gallery picker wrapper
- `lib/core/services/storage/meal_image_storage_service.dart`: upload image and return storage path
- `lib/features/auth/data/auth_repository.dart`: auth interface and Firebase implementation
- `lib/features/auth/presentation/controllers/auth_controller.dart`: auth state provider
- `lib/features/auth/presentation/pages/sign_in_page.dart`: Google sign-in screen
- `lib/features/profile/domain/user_profile.dart`: user profile entity
- `lib/features/profile/domain/daily_calorie_target_calculator.dart`: target calculation helper
- `lib/features/profile/data/profile_repository.dart`: Firestore-backed profile repository
- `lib/features/profile/presentation/pages/profile_page.dart`: onboarding/edit profile page
- `lib/features/dashboard/domain/daily_summary.dart`: dashboard summary entity
- `lib/features/dashboard/data/dashboard_repository.dart`: read today summary and recent meals
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`: home page with summary and scan CTA
- `lib/features/meal_history/domain/meal_record.dart`: meal history entity
- `lib/features/meal_history/data/meal_history_repository.dart`: read meal history
- `lib/features/meal_history/presentation/pages/meal_history_page.dart`: meal history list
- `lib/features/meal_scan/domain/meal_analysis.dart`: callable response model
- `lib/features/meal_scan/data/meal_scan_repository.dart`: upload + callable function integration
- `lib/features/meal_scan/presentation/controllers/meal_scan_controller.dart`: scan state machine
- `lib/features/meal_scan/presentation/pages/meal_scan_page.dart`: capture, progress, retry, and result rendering
- `lib/features/meal_scan/presentation/widgets/analysis_result_card.dart`: result UI

### Firebase / backend

- `.firebaserc`: project alias configuration
- `firebase.json`: emulator and deploy targets
- `firestore.rules`: Firestore ownership rules
- `firestore.indexes.json`: summary/history indexes
- `storage.rules`: Storage ownership rules
- `functions/package.json`: scripts and dependencies
- `functions/tsconfig.json`: TypeScript build config
- `functions/vitest.config.ts`: function test config
- `functions/src/index.ts`: function exports
- `functions/src/config/env.ts`: env and secret parsing
- `functions/src/shared/errors/appError.ts`: structured backend error
- `functions/src/shared/types/mealAnalysis.ts`: request/response types
- `functions/src/modules/analyze-meal/visionProvider.ts`: calls the selected vision endpoint
- `functions/src/modules/analyze-meal/nutritionProvider.ts`: calorie normalization provider
- `functions/src/modules/analyze-meal/healthClassifier.ts`: `good` / `moderate` / `avoid`
- `functions/src/modules/analyze-meal/quantitySuggestion.ts`: actionable suggestions
- `functions/src/modules/analyze-meal/responseMapper.ts`: provider output to app contract
- `functions/src/modules/analyze-meal/analyzeMeal.ts`: callable function handler
- `functions/src/modules/meals/saveMealAnalysis.ts`: meal write + daily summary transaction

### Tests

- `test/app/app_bootstrap_test.dart`
- `test/features/auth/presentation/auth_gate_test.dart`
- `test/features/profile/presentation/profile_page_test.dart`
- `test/features/dashboard/presentation/dashboard_page_test.dart`
- `test/features/meal_scan/presentation/meal_scan_controller_test.dart`
- `functions/test/modules/analyze-meal/analyzeMeal.test.ts`
- `functions/test/modules/analyze-meal/healthClassifier.test.ts`
- `functions/test/modules/analyze-meal/quantitySuggestion.test.ts`
- `functions/test/security/firestore.rules.test.ts`

## Task 1: Bootstrap The App Shell

**Files:**
- Modify: `pubspec.yaml`, `lib/main.dart`
- Create: `lib/app/bootstrap.dart`
- Create: `lib/app/app.dart`
- Create: `lib/app/router/app_router.dart`
- Create: `lib/app/theme/app_theme.dart`
- Create: `lib/core/config/app_environment.dart`
- Create: `lib/core/errors/app_exception.dart`
- Test: `test/app/app_bootstrap_test.dart`

- [ ] **Step 1: Write the failing app shell test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmitra/app/app.dart';

void main() {
  testWidgets('shows the branded loading shell', (tester) async {
    await tester.pumpWidget(const MealMitraApp());

    expect(find.text('MealMitra'), findsOneWidget);
    expect(find.text('Preparing your food scanner'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `flutter test test/app/app_bootstrap_test.dart -r expanded`
Expected: FAIL because `MealMitraApp` does not exist yet.

- [ ] **Step 3: Add the app dependencies**

Run:

```bash
flutter pub add flutter_riverpod go_router firebase_core firebase_auth cloud_firestore firebase_storage cloud_functions google_sign_in image_picker intl
flutter pub add --dev mocktail
```

Expected: `pubspec.yaml` and `pubspec.lock` update successfully.

- [ ] **Step 4: Create the bootstrap, app shell, and base router**

```dart
// lib/main.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/app/app.dart';
import 'package:mealmitra/app/bootstrap.dart';

Future<void> main() async {
  await bootstrap();
  runApp(const ProviderScope(child: MealMitraApp()));
}

// lib/app/bootstrap.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:mealmitra/firebase_options.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// lib/app/app.dart
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
      title: 'MealMitra',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}

// lib/app/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'MealMitra',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 12),
                  Text('Preparing your food scanner'),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
});

// lib/app/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF17624A),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F3EC),
      useMaterial3: true,
    );
  }
}

// lib/core/config/app_environment.dart
class AppEnvironment {
  static const usersCollection = 'users';
  static const mealsCollection = 'meals';
  static const dailySummariesCollection = 'daily_summaries';
  static const analyzeMealFunction = 'analyzeMeal';
}

// lib/core/errors/app_exception.dart
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}
```

- [ ] **Step 5: Generate Firebase options for the Flutter app**

Run:

```bash
dart pub global activate flutterfire_cli
firebase login
firebase use --add mealmitra-dev
flutterfire configure --project=mealmitra-dev --platforms=android,ios,web --out=lib/firebase_options.dart
```

Expected: `lib/firebase_options.dart` is created and the Android/iOS/Web Firebase config is updated.

- [ ] **Step 6: Run the test again and verify it passes**

Run:

```bash
flutter test test/app/app_bootstrap_test.dart -r expanded
flutter analyze
```

Expected: PASS for the widget test, and `flutter analyze` reports no new issues.

- [ ] **Step 7: Commit the shell**

```bash
git init
git add pubspec.yaml pubspec.lock lib/main.dart lib/app lib/core test/app lib/firebase_options.dart
git commit -m "feat: bootstrap mealmitra app shell"
```

## Task 2: Implement Auth Gate And Sign-In

**Files:**
- Create: `lib/core/services/firebase/firebase_providers.dart`
- Create: `lib/features/auth/data/auth_repository.dart`
- Create: `lib/features/auth/presentation/controllers/auth_controller.dart`
- Create: `lib/features/auth/presentation/pages/sign_in_page.dart`
- Modify: `lib/app/router/app_router.dart`
- Test: `test/features/auth/presentation/auth_gate_test.dart`

- [ ] **Step 1: Write the failing auth gate test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/app/app.dart';
import 'package:mealmitra/features/auth/data/auth_repository.dart';

class FakeSignedOutAuthRepository implements AuthRepository {
  @override
  Stream<String?> authStateChanges() => Stream.value(null);

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('signed out users see the sign-in screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeSignedOutAuthRepository()),
        ],
        child: const MealMitraApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the auth gate test to confirm it fails**

Run: `flutter test test/features/auth/presentation/auth_gate_test.dart -r expanded`
Expected: FAIL because `AuthRepository` and the sign-in screen do not exist yet.

- [ ] **Step 3: Add the Google sign-in package**

Run:

```bash
flutter pub add google_sign_in
firebase use --add mealmitra-dev
flutterfire configure --project=mealmitra-dev --platforms=android,ios,web --out=lib/firebase_options.dart
```

Expected: dependency resolution succeeds and Firebase auth config is refreshed.

- [ ] **Step 4: Implement the auth repository, controller, and redirect-aware router**

```dart
// lib/core/services/firebase/firebase_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) => FirebaseFunctions.instance);

// lib/features/auth/data/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mealmitra/core/services/firebase/firebase_providers.dart';

abstract class AuthRepository {
  Stream<String?> authStateChanges();
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
    GoogleSignIn(),
  );
});

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._googleSignIn);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<String?> authStateChanges() {
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Future<void> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return;
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}

// lib/features/auth/presentation/controllers/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/features/auth/data/auth_repository.dart';

final authStateProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// lib/features/auth/presentation/pages/sign_in_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/features/auth/data/auth_repository.dart';

class SignInPage extends ConsumerWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => ref.read(authRepositoryProvider).signInWithGoogle(),
          child: const Text('Continue with Google'),
        ),
      ),
    );
  }
}

// lib/app/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/auth/presentation/pages/sign_in_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Scaffold(body: SizedBox.shrink())),
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInPage()),
    ],
    redirect: (context, state) {
      if (authState.isLoading) return null;
      if (authState.value == null && state.matchedLocation != '/sign-in') {
        return '/sign-in';
      }
      return null;
    },
  );
});
```

- [ ] **Step 5: Run the auth tests and smoke test**

Run:

```bash
flutter test test/app/app_bootstrap_test.dart test/features/auth/presentation/auth_gate_test.dart -r expanded
flutter analyze
```

Expected: both tests PASS and the analyzer stays clean.

- [ ] **Step 6: Commit the auth layer**

```bash
git add lib/core/services/firebase lib/features/auth lib/app/router test/features/auth pubspec.yaml pubspec.lock
git commit -m "feat: add firebase auth gate and sign-in flow"
```

## Task 3: Build Profile Onboarding And Profile Persistence

**Files:**
- Create: `lib/features/profile/domain/user_profile.dart`
- Create: `lib/features/profile/domain/daily_calorie_target_calculator.dart`
- Create: `lib/features/profile/data/profile_repository.dart`
- Create: `lib/features/profile/presentation/pages/profile_page.dart`
- Modify: `lib/app/router/app_router.dart`
- Test: `test/features/profile/presentation/profile_page_test.dart`

- [ ] **Step 1: Write the failing profile onboarding test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmitra/features/profile/domain/daily_calorie_target_calculator.dart';

void main() {
  test('calculates a reduced target for fat loss', () {
    final target = DailyCalorieTargetCalculator.calculate(
      age: 28,
      heightCm: 170,
      weightKg: 74,
      goal: ProfileGoal.lose,
      activityLevel: ActivityLevel.moderate,
    );

    expect(target, 1910);
  });
}
```

- [ ] **Step 2: Run the profile test to confirm it fails**

Run: `flutter test test/features/profile/presentation/profile_page_test.dart -r expanded`
Expected: FAIL because the calculator and profile model do not exist yet.

- [ ] **Step 3: Implement the profile entity and calorie target calculator**

```dart
// lib/features/profile/domain/user_profile.dart
enum ProfileGoal { lose, maintain, gain }
enum ActivityLevel { low, moderate, high }

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activityLevel,
    required this.dailyCalorieTarget,
  });

  final String uid;
  final String displayName;
  final int age;
  final double heightCm;
  final double weightKg;
  final ProfileGoal goal;
  final ActivityLevel activityLevel;
  final int dailyCalorieTarget;

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'goal': goal.name,
        'activityLevel': activityLevel.name,
        'dailyCalorieTarget': dailyCalorieTarget,
      };

  static UserProfile fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      displayName: map['displayName'] as String,
      age: map['age'] as int,
      heightCm: (map['heightCm'] as num).toDouble(),
      weightKg: (map['weightKg'] as num).toDouble(),
      goal: ProfileGoal.values.byName(map['goal'] as String),
      activityLevel: ActivityLevel.values.byName(map['activityLevel'] as String),
      dailyCalorieTarget: map['dailyCalorieTarget'] as int,
    );
  }
}

// lib/features/profile/domain/daily_calorie_target_calculator.dart
import 'package:mealmitra/features/profile/domain/user_profile.dart';

class DailyCalorieTargetCalculator {
  static int calculate({
    required int age,
    required double heightCm,
    required double weightKg,
    required ProfileGoal goal,
    required ActivityLevel activityLevel,
  }) {
    final bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    final multiplier = switch (activityLevel) {
      ActivityLevel.low => 1.2,
      ActivityLevel.moderate => 1.375,
      ActivityLevel.high => 1.55,
    };
    final maintenance = bmr * multiplier;
    final adjusted = switch (goal) {
      ProfileGoal.lose => maintenance - 300,
      ProfileGoal.maintain => maintenance,
      ProfileGoal.gain => maintenance + 250,
    };
    return adjusted.round();
  }
}
```

- [ ] **Step 4: Implement the Firestore repository, profile page, and profile redirect**

```dart
// lib/features/profile/data/profile_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/core/config/app_environment.dart';
import 'package:mealmitra/core/services/firebase/firebase_providers.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/profile/domain/user_profile.dart';

abstract class ProfileRepository {
  Stream<UserProfile?> watchCurrentProfile();
  Future<void> saveProfile(UserProfile profile);
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirestoreProfileRepository(
    ref.watch(firestoreProvider),
    ref.watch(authStateProvider).value,
  );
});

final currentProfileProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).watchCurrentProfile();
});

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String? _uid;

  @override
  Stream<UserProfile?> watchCurrentProfile() {
    if (_uid == null) return const Stream.empty();
    return _firestore
        .collection(AppEnvironment.usersCollection)
        .doc(_uid)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return UserProfile.fromMap(snapshot.id, data);
    });
  }

  @override
  Future<void> saveProfile(UserProfile profile) {
    return _firestore
        .collection(AppEnvironment.usersCollection)
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }
}

// lib/features/profile/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/profile/data/profile_repository.dart';
import 'package:mealmitra/features/profile/domain/daily_calorie_target_calculator.dart';
import 'package:mealmitra/features/profile/domain/user_profile.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  ProfileGoal _goal = ProfileGoal.lose;
  ActivityLevel _activity = ActivityLevel.moderate;

  Future<void> _save() async {
    final uid = ref.read(authStateProvider).value!;
    final age = int.parse(_age.text);
    final height = double.parse(_height.text);
    final weight = double.parse(_weight.text);
    final target = DailyCalorieTargetCalculator.calculate(
      age: age,
      heightCm: height,
      weightKg: weight,
      goal: _goal,
      activityLevel: _activity,
    );

    final profile = UserProfile(
      uid: uid,
      displayName: _name.text.trim(),
      age: age,
      heightCm: height,
      weightKg: weight,
      goal: _goal,
      activityLevel: _activity,
      dailyCalorieTarget: target,
    );

    await ref.read(profileRepositoryProvider).saveProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _age, decoration: const InputDecoration(labelText: 'Age')),
          TextField(controller: _height, decoration: const InputDecoration(labelText: 'Height (cm)')),
          TextField(controller: _weight, decoration: const InputDecoration(labelText: 'Weight (kg)')),
          ElevatedButton(onPressed: _save, child: const Text('Save profile')),
        ],
      ),
    );
  }
}
```

Update `lib/app/router/app_router.dart` so that:

```dart
if (authState.value != null && currentProfile.isLoading) return null;
if (authState.value != null && currentProfile.value == null && state.matchedLocation != '/profile') {
  return '/profile';
}
```

- [ ] **Step 5: Run profile tests and analyzer**

Run:

```bash
flutter test test/features/profile/presentation/profile_page_test.dart -r expanded
flutter analyze
```

Expected: PASS and clean analysis.

- [ ] **Step 6: Commit the profile flow**

```bash
git add lib/features/profile lib/app/router test/features/profile
git commit -m "feat: add profile onboarding and calorie targets"
```

## Task 4: Add Dashboard And Meal History Reads

**Files:**
- Create: `lib/features/dashboard/domain/daily_summary.dart`
- Create: `lib/features/dashboard/data/dashboard_repository.dart`
- Create: `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- Create: `lib/features/meal_history/domain/meal_record.dart`
- Create: `lib/features/meal_history/data/meal_history_repository.dart`
- Create: `lib/features/meal_history/presentation/pages/meal_history_page.dart`
- Modify: `lib/app/router/app_router.dart`
- Test: `test/features/dashboard/presentation/dashboard_page_test.dart`

- [ ] **Step 1: Write the failing dashboard test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmitra/features/dashboard/domain/daily_summary.dart';

void main() {
  test('daily summary formats calories correctly', () {
    const summary = DailySummary(
      dayId: '2026-04-13',
      totalCalories: 1240,
      mealCount: 3,
      lastMealAtIso: '2026-04-13T13:10:00.000Z',
    );

    expect(summary.progressLabel(1900), '1240 / 1900 kcal');
  });
}
```

- [ ] **Step 2: Run the dashboard test to confirm it fails**

Run: `flutter test test/features/dashboard/presentation/dashboard_page_test.dart -r expanded`
Expected: FAIL because `DailySummary` does not exist yet.

- [ ] **Step 3: Implement the summary and history entities**

```dart
// lib/features/dashboard/domain/daily_summary.dart
class DailySummary {
  const DailySummary({
    required this.dayId,
    required this.totalCalories,
    required this.mealCount,
    required this.lastMealAtIso,
  });

  final String dayId;
  final int totalCalories;
  final int mealCount;
  final String lastMealAtIso;

  String progressLabel(int targetCalories) => '$totalCalories / $targetCalories kcal';

  static DailySummary fromMap(String dayId, Map<String, dynamic> map) {
    return DailySummary(
      dayId: dayId,
      totalCalories: map['totalCalories'] as int? ?? 0,
      mealCount: map['mealCount'] as int? ?? 0,
      lastMealAtIso: map['lastMealAt'] as String? ?? '',
    );
  }
}

// lib/features/meal_history/domain/meal_record.dart
class MealRecord {
  const MealRecord({
    required this.id,
    required this.mealType,
    required this.totalCalories,
    required this.healthLabel,
    required this.capturedAtIso,
  });

  final String id;
  final String mealType;
  final int totalCalories;
  final String healthLabel;
  final String capturedAtIso;

  static MealRecord fromMap(String id, Map<String, dynamic> map) {
    return MealRecord(
      id: id,
      mealType: map['mealType'] as String? ?? 'meal',
      totalCalories: map['totalCalories'] as int? ?? 0,
      healthLabel: map['healthLabel'] as String? ?? 'moderate',
      capturedAtIso: map['capturedAt'] as String? ?? '',
    );
  }
}
```

- [ ] **Step 4: Implement the Firestore repositories and dashboard page**

```dart
// lib/features/dashboard/data/dashboard_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/core/config/app_environment.dart';
import 'package:mealmitra/core/services/firebase/firebase_providers.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/dashboard/domain/daily_summary.dart';
import 'package:mealmitra/features/meal_history/domain/meal_record.dart';

final todaySummaryProvider = StreamProvider<DailySummary?>((ref) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection(AppEnvironment.usersCollection)
      .doc(uid)
      .collection(AppEnvironment.dailySummariesCollection)
      .doc(DateTime.now().toIso8601String().substring(0, 10))
      .snapshots()
      .map((doc) => doc.data() == null ? null : DailySummary.fromMap(doc.id, doc.data()!));
});

final recentMealsProvider = StreamProvider<List<MealRecord>>((ref) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection(AppEnvironment.usersCollection)
      .doc(uid)
      .collection(AppEnvironment.mealsCollection)
      .orderBy('capturedAt', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => MealRecord.fromMap(doc.id, doc.data())).toList());
});

// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mealmitra/features/dashboard/data/dashboard_repository.dart';
import 'package:mealmitra/features/profile/data/profile_repository.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final summary = ref.watch(todaySummaryProvider);
    final meals = ref.watch(recentMealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/scan'),
        label: const Text('Scan meal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          profile.when(
            data: (value) => Text(summary.value?.progressLabel(value?.dailyCalorieTarget ?? 0) ?? '0 / 0 kcal'),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Could not load profile'),
          ),
          const SizedBox(height: 16),
          ...meals.valueOrNull?.map((meal) => ListTile(
                title: Text(meal.mealType),
                subtitle: Text('${meal.totalCalories} kcal'),
                trailing: Text(meal.healthLabel),
              )) ??
              const [Text('No meals yet')],
        ],
      ),
    );
  }
}
```

Update `lib/app/router/app_router.dart` to include `/dashboard` and `/history` routes and send signed-in users with profiles to `/dashboard`.

- [ ] **Step 5: Run dashboard tests and analyzer**

Run:

```bash
flutter test test/features/dashboard/presentation/dashboard_page_test.dart -r expanded
flutter analyze
```

Expected: PASS and no new analysis problems.

- [ ] **Step 6: Commit dashboard and history reads**

```bash
git add lib/features/dashboard lib/features/meal_history lib/app/router test/features/dashboard
git commit -m "feat: add dashboard and meal history reads"
```

## Task 5: Implement Capture, Upload, And Scan State

**Files:**
- Create: `lib/core/services/camera/camera_capture_service.dart`
- Create: `lib/core/services/storage/meal_image_storage_service.dart`
- Create: `lib/features/meal_scan/domain/meal_analysis.dart`
- Create: `lib/features/meal_scan/data/meal_scan_repository.dart`
- Create: `lib/features/meal_scan/presentation/controllers/meal_scan_controller.dart`
- Create: `lib/features/meal_scan/presentation/pages/meal_scan_page.dart`
- Create: `lib/features/meal_scan/presentation/widgets/analysis_result_card.dart`
- Modify: `lib/app/router/app_router.dart`
- Test: `test/features/meal_scan/presentation/meal_scan_controller_test.dart`

- [ ] **Step 1: Write the failing scan controller test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';
import 'package:mealmitra/features/meal_scan/presentation/controllers/meal_scan_controller.dart';

void main() {
  test('controller enters completed state after a successful scan', () async {
    final controller = MealScanController.fake(
      result: const MealAnalysis(
        mealId: 'meal-1',
        totalCalories: 540,
        healthLabel: 'moderate',
        suggestions: ['Reduce rice by 30%'],
      ),
    );

    await controller.scanDemoMeal();

    expect(controller.state.status, MealScanStatus.completed);
    expect(controller.state.result?.totalCalories, 540);
  });
}
```

- [ ] **Step 2: Run the scan controller test to confirm it fails**

Run: `flutter test test/features/meal_scan/presentation/meal_scan_controller_test.dart -r expanded`
Expected: FAIL because the scan controller and analysis model do not exist yet.

- [ ] **Step 3: Implement the camera service, storage service, and analysis model**

```dart
// lib/core/services/camera/camera_capture_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraCaptureService {
  CameraCaptureService(this._picker);
  final ImagePicker _picker;

  Future<File?> captureFromCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    return image == null ? null : File(image.path);
  }

  Future<File?> selectFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    return image == null ? null : File(image.path);
  }
}

// lib/core/services/storage/meal_image_storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class MealImageStorageService {
  MealImageStorageService(this._storage);
  final FirebaseStorage _storage;

  Future<String> uploadMealImage({
    required String uid,
    required String mealId,
    required File imageFile,
  }) async {
    final path = 'users/$uid/meals/$mealId.jpg';
    await _storage.ref(path).putFile(imageFile);
    return path;
  }
}

// lib/features/meal_scan/domain/meal_analysis.dart
class MealAnalysis {
  const MealAnalysis({
    required this.mealId,
    required this.totalCalories,
    required this.healthLabel,
    required this.suggestions,
  });

  final String mealId;
  final int totalCalories;
  final String healthLabel;
  final List<String> suggestions;

  factory MealAnalysis.fromMap(Map<String, dynamic> map) {
    return MealAnalysis(
      mealId: map['mealId'] as String,
      totalCalories: map['totalCalories'] as int,
      healthLabel: map['healthLabel'] as String,
      suggestions: List<String>.from(map['suggestions'] as List<dynamic>),
    );
  }
}
```

- [ ] **Step 4: Implement the repository, controller state machine, and scan page**

```dart
// lib/features/meal_scan/data/meal_scan_repository.dart
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:mealmitra/core/config/app_environment.dart';
import 'package:mealmitra/core/services/storage/meal_image_storage_service.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

class MealScanRepository {
  MealScanRepository(this._storage, this._functions, this._uuid);

  final MealImageStorageService _storage;
  final FirebaseFunctions _functions;
  final Uuid _uuid;

  Future<MealAnalysis> analyzeMeal({
    required String uid,
    required File imageFile,
    required String mealType,
  }) async {
    final mealId = _uuid.v4();
    final storagePath = await _storage.uploadMealImage(
      uid: uid,
      mealId: mealId,
      imageFile: imageFile,
    );

    final callable = _functions.httpsCallable(AppEnvironment.analyzeMealFunction);
    final response = await callable.call({
      'mealId': mealId,
      'storagePath': storagePath,
      'mealType': mealType,
      'capturedAt': Timestamp.now().toDate().toIso8601String(),
    });

    return MealAnalysis.fromMap(Map<String, dynamic>.from(response.data as Map));
  }
}

// lib/features/meal_scan/presentation/controllers/meal_scan_controller.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

enum MealScanStatus { idle, uploading, analyzing, completed, failed }

class MealScanState {
  const MealScanState({
    this.status = MealScanStatus.idle,
    this.result,
    this.errorMessage,
  });

  final MealScanStatus status;
  final MealAnalysis? result;
  final String? errorMessage;
}

class MealScanController extends ChangeNotifier {
  MealScanController.fake({required MealAnalysis result})
      : _demoResult = result,
        _repository = null,
        state = const MealScanState();

  MealScanController(this._repository) : _demoResult = null, state = const MealScanState();

  final dynamic _repository;
  final MealAnalysis? _demoResult;
  MealScanState state;

  Future<void> scanDemoMeal() async {
    state = const MealScanState(status: MealScanStatus.analyzing);
    notifyListeners();
    state = MealScanState(status: MealScanStatus.completed, result: _demoResult);
    notifyListeners();
  }

  Future<void> scan({
    required String uid,
    required File imageFile,
    required String mealType,
  }) async {
    try {
      state = const MealScanState(status: MealScanStatus.uploading);
      notifyListeners();
      final result = await _repository.analyzeMeal(
        uid: uid,
        imageFile: imageFile,
        mealType: mealType,
      );
      state = MealScanState(status: MealScanStatus.completed, result: result);
      notifyListeners();
    } catch (error) {
      state = MealScanState(
        status: MealScanStatus.failed,
        errorMessage: error.toString(),
      );
      notifyListeners();
    }
  }
}
```

- [ ] **Step 5: Run scan tests and targeted analysis**

Run:

```bash
flutter test test/features/meal_scan/presentation/meal_scan_controller_test.dart -r expanded
flutter analyze
```

Expected: PASS and no new analyzer errors.

- [ ] **Step 6: Commit the scan flow**

```bash
git add lib/core/services/camera lib/core/services/storage lib/features/meal_scan lib/app/router test/features/meal_scan
git commit -m "feat: add meal capture upload and scan state"
```

## Task 6: Scaffold Cloud Functions And Callable Contract

**Files:**
- Create: `.firebaserc`
- Create: `firebase.json`
- Create: `functions/package.json`
- Create: `functions/tsconfig.json`
- Create: `functions/vitest.config.ts`
- Create: `functions/src/index.ts`
- Create: `functions/src/config/env.ts`
- Create: `functions/src/shared/errors/appError.ts`
- Create: `functions/src/shared/types/mealAnalysis.ts`
- Create: `functions/src/modules/analyze-meal/analyzeMeal.ts`
- Test: `functions/test/modules/analyze-meal/analyzeMeal.test.ts`

- [ ] **Step 1: Write the failing callable contract test**

```ts
import { describe, expect, it } from 'vitest';
import { analyzeMealHandler } from '../../../src/modules/analyze-meal/analyzeMeal';

describe('analyzeMealHandler', () => {
  it('throws when auth is missing', async () => {
    await expect(
      analyzeMealHandler({
        auth: null,
        data: {
          mealId: 'meal-1',
          storagePath: 'users/user-1/meals/meal-1.jpg',
          mealType: 'lunch',
          capturedAt: '2026-04-13T12:00:00.000Z',
        },
      } as never),
    ).rejects.toThrow(/auth/i);
  });
});
```

- [ ] **Step 2: Run the backend test to confirm it fails**

Run: `npm --prefix functions test -- analyzeMeal.test.ts`
Expected: FAIL because the functions workspace and handler do not exist yet.

- [ ] **Step 3: Create the functions workspace and test tooling**

```json
// .firebaserc
{
  "projects": {
    "default": "mealmitra-dev"
  }
}
```

```json
// firebase.json
{
  "functions": {
    "source": "functions"
  }
}
```

```json
// functions/package.json
{
  "name": "mealmitra-functions",
  "private": true,
  "engines": {
    "node": "20"
  },
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "test": "vitest run"
  }
}
```

```json
// functions/tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "lib",
    "rootDir": ".",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src", "test"]
}
```

```ts
// functions/vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['test/**/*.test.ts'],
  },
});
```

Run:

```bash
npm --prefix functions install firebase-admin firebase-functions zod
npm --prefix functions install -D typescript vitest @types/node @firebase/rules-unit-testing
```

Expected: `functions/package-lock.json` is created and dependencies install successfully.

- [ ] **Step 4: Implement the callable contract, env parser, and auth validation**

```ts
// functions/src/shared/errors/appError.ts
export class AppError extends Error {
  constructor(
    readonly code: 'unauthenticated' | 'invalid-argument' | 'internal',
    message: string,
  ) {
    super(message);
  }
}

// functions/src/shared/types/mealAnalysis.ts
import { z } from 'zod';

export const analyzeMealRequestSchema = z.object({
  mealId: z.string().min(1),
  storagePath: z.string().min(1),
  mealType: z.enum(['breakfast', 'lunch', 'dinner', 'snack']),
  capturedAt: z.string().min(1),
});

export type AnalyzeMealRequest = z.infer<typeof analyzeMealRequestSchema>;

export interface AnalyzeMealResponse {
  mealId: string;
  totalCalories: number;
  healthLabel: 'good' | 'moderate' | 'avoid';
  suggestions: string[];
  analysisVersion: string;
}

// functions/src/config/env.ts
export const env = {
  region: 'asia-south1',
  analysisVersion: 'v1',
  visionEndpoint: process.env.VISION_API_ENDPOINT ?? '',
  visionApiKey: process.env.VISION_API_KEY ?? '',
};

// functions/src/modules/analyze-meal/analyzeMeal.ts
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { analyzeMealRequestSchema } from '../../shared/types/mealAnalysis';
import { env } from '../../config/env';

export async function analyzeMealHandler(request: {
  auth: { uid: string } | null;
  data: unknown;
}) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication is required');
  }

  analyzeMealRequestSchema.parse(request.data);

  return {
    mealId: (request.data as { mealId: string }).mealId,
    totalCalories: 0,
    healthLabel: 'moderate' as const,
    suggestions: [],
    analysisVersion: env.analysisVersion,
  };
}

export const analyzeMeal = onCall({ region: env.region }, analyzeMealHandler);

// functions/src/index.ts
import * as admin from 'firebase-admin';
import { analyzeMeal } from './modules/analyze-meal/analyzeMeal';

admin.initializeApp();

export { analyzeMeal };
```

- [ ] **Step 5: Run backend tests and build**

Run:

```bash
npm --prefix functions test -- analyzeMeal.test.ts
npm --prefix functions run build
```

Expected: the callable contract test passes and the TypeScript build succeeds.

- [ ] **Step 6: Commit the backend scaffold**

```bash
git add .firebaserc firebase.json functions
git commit -m "feat: scaffold firebase functions callable contract"
```

## Task 7: Implement Meal Analysis Logic And Persistence

**Files:**
- Create: `functions/src/modules/analyze-meal/visionProvider.ts`
- Create: `functions/src/modules/analyze-meal/nutritionProvider.ts`
- Create: `functions/src/modules/analyze-meal/healthClassifier.ts`
- Create: `functions/src/modules/analyze-meal/quantitySuggestion.ts`
- Create: `functions/src/modules/analyze-meal/responseMapper.ts`
- Create: `functions/src/modules/meals/saveMealAnalysis.ts`
- Modify: `functions/src/modules/analyze-meal/analyzeMeal.ts`
- Test: `functions/test/modules/analyze-meal/healthClassifier.test.ts`
- Test: `functions/test/modules/analyze-meal/quantitySuggestion.test.ts`

- [ ] **Step 1: Write the failing classifier and suggestion tests**

```ts
import { describe, expect, it } from 'vitest';
import { classifyHealthLabel } from '../../../src/modules/analyze-meal/healthClassifier';
import { buildQuantitySuggestions } from '../../../src/modules/analyze-meal/quantitySuggestion';

describe('healthClassifier', () => {
  it('marks fried high calorie meals as avoid', () => {
    const label = classifyHealthLabel({
      totalCalories: 920,
      foodNames: ['samosa', 'sweet chai'],
    });
    expect(label).toBe('avoid');
  });
});

describe('quantitySuggestion', () => {
  it('suggests reducing rice for weight loss', () => {
    const suggestions = buildQuantitySuggestions({
      goal: 'lose',
      foodNames: ['rice', 'dal', 'sabzi'],
      totalCalories: 680,
    });
    expect(suggestions).toContain('Reduce rice by 30%');
  });
});
```

- [ ] **Step 2: Run the analysis tests to confirm they fail**

Run: `npm --prefix functions test -- healthClassifier.test.ts quantitySuggestion.test.ts`
Expected: FAIL because the classifier and suggestion modules do not exist yet.

- [ ] **Step 3: Implement the classifier, suggestion builder, and response mapper**

```ts
// functions/src/modules/analyze-meal/healthClassifier.ts
export function classifyHealthLabel(input: {
  totalCalories: number;
  foodNames: string[];
}): 'good' | 'moderate' | 'avoid' {
  const names = input.foodNames.map((name) => name.toLowerCase());
  const hasFriedFood = names.some((name) => ['samosa', 'pakora', 'poori'].includes(name));
  const hasSweetDrink = names.some((name) => ['sweet chai', 'cola'].includes(name));

  if (input.totalCalories >= 850 || hasFriedFood || hasSweetDrink) {
    return 'avoid';
  }
  if (input.totalCalories >= 550) {
    return 'moderate';
  }
  return 'good';
}

// functions/src/modules/analyze-meal/quantitySuggestion.ts
export function buildQuantitySuggestions(input: {
  goal: 'lose' | 'maintain' | 'gain';
  foodNames: string[];
  totalCalories: number;
}): string[] {
  const suggestions: string[] = [];
  const names = input.foodNames.map((name) => name.toLowerCase());

  if (input.goal === 'lose' && names.includes('rice')) {
    suggestions.push('Reduce rice by 30%');
  }
  if (input.goal === 'lose' && names.filter((name) => name === 'roti').length > 2) {
    suggestions.push('2 rotis are enough');
  }
  if (input.totalCalories > 750) {
    suggestions.push('Pair this meal with a lighter next meal');
  }

  return suggestions;
}

// functions/src/modules/analyze-meal/responseMapper.ts
import { AnalyzeMealRequest, AnalyzeMealResponse } from '../../shared/types/mealAnalysis';

export function mapAnalyzeMealResponse(input: {
  request: AnalyzeMealRequest;
  totalCalories: number;
  healthLabel: 'good' | 'moderate' | 'avoid';
  suggestions: string[];
}): AnalyzeMealResponse {
  return {
    mealId: input.request.mealId,
    totalCalories: input.totalCalories,
    healthLabel: input.healthLabel,
    suggestions: input.suggestions,
  };
}
```

- [ ] **Step 4: Implement the provider adapters and Firestore write path**

```ts
// functions/src/modules/analyze-meal/visionProvider.ts
import { env } from '../../config/env';
import { AppError } from '../../shared/errors/appError';

export interface VisionFoodCandidate {
  name: string;
  confidence: number;
}

export async function detectFoodsFromImage(storagePath: string): Promise<VisionFoodCandidate[]> {
  const response = await fetch(env.visionEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${env.visionApiKey}`,
    },
    body: JSON.stringify({
      imagePath: storagePath,
      locale: 'en-IN',
      maxItems: 6,
    }),
  });

  if (!response.ok) {
    throw new AppError('internal', `Vision provider failed with status ${response.status}`);
  }

  const payload = await response.json() as {
    items: Array<{ name: string; confidence: number }>;
  };

  return payload.items;
}

// functions/src/modules/analyze-meal/nutritionProvider.ts
const calorieLookup: Record<string, number> = {
  rice: 220,
  dal: 160,
  sabzi: 140,
  roti: 120,
  samosa: 260,
  idli: 65,
  dosa: 180,
};

export function estimateTotalCalories(foodNames: string[]): number {
  return foodNames.reduce(
    (sum, food) => sum + (calorieLookup[food.toLowerCase()] ?? 120),
    0,
  );
}

// functions/src/modules/meals/saveMealAnalysis.ts
import * as admin from 'firebase-admin';
import { AnalyzeMealRequest, AnalyzeMealResponse } from '../../shared/types/mealAnalysis';

export async function saveMealAnalysis(
  uid: string,
  request: AnalyzeMealRequest,
  response: AnalyzeMealResponse,
): Promise<void> {
  const firestore = admin.firestore();
  const mealRef = firestore.doc(`users/${uid}/meals/${request.mealId}`);
  const dayId = request.capturedAt.substring(0, 10);
  const summaryRef = firestore.doc(`users/${uid}/daily_summaries/${dayId}`);

  await firestore.runTransaction(async (transaction) => {
    transaction.set(mealRef, {
      mealType: request.mealType,
      capturedAt: request.capturedAt,
      status: 'completed',
      totalCalories: response.totalCalories,
      healthLabel: response.healthLabel,
      suggestions: response.suggestions,
      imagePath: request.storagePath,
    });

    const summary = await transaction.get(summaryRef);
    const currentCalories = summary.data()?['totalCalories'] as int? ?? 0;
    const currentMeals = summary.data()?['mealCount'] as int? ?? 0;

    transaction.set(summaryRef, {
      totalCalories: currentCalories + response.totalCalories,
      mealCount: currentMeals + 1,
      lastMealAt: request.capturedAt,
    });
  });
}

// functions/src/modules/analyze-meal/analyzeMeal.ts
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { analyzeMealRequestSchema } from '../../shared/types/mealAnalysis';
import { detectFoodsFromImage } from './visionProvider';
import { estimateTotalCalories } from './nutritionProvider';
import { classifyHealthLabel } from './healthClassifier';
import { buildQuantitySuggestions } from './quantitySuggestion';
import { mapAnalyzeMealResponse } from './responseMapper';
import { saveMealAnalysis } from '../meals/saveMealAnalysis';

export async function analyzeMealHandler(request: {
  auth: { uid: string } | null;
  data: unknown;
}) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication is required');
  }

  const parsed = analyzeMealRequestSchema.parse(request.data);
  const foods = await detectFoodsFromImage(parsed.storagePath);
  const foodNames = foods.map((food) => food.name);
  const totalCalories = estimateTotalCalories(foodNames);
  const userDoc = await admin.firestore().doc(`users/${request.auth.uid}`).get();
  const goal = (userDoc.data()?['goal'] as 'lose' | 'maintain' | 'gain'?) ?? 'maintain';
  const healthLabel = classifyHealthLabel({
    totalCalories: totalCalories,
    foodNames: foodNames,
  });
  const suggestions = buildQuantitySuggestions({
    goal: goal,
    foodNames: foodNames,
    totalCalories: totalCalories,
  });

  const response = mapAnalyzeMealResponse(
    {
      request: parsed,
      totalCalories: totalCalories,
      healthLabel: healthLabel,
      suggestions: suggestions,
    },
  );

  await saveMealAnalysis(request.auth.uid, parsed, response);
  return response;
}
```

- [ ] **Step 5: Run backend logic tests and build**

Run:

```bash
npm --prefix functions test -- healthClassifier.test.ts quantitySuggestion.test.ts analyzeMeal.test.ts
npm --prefix functions run build
```

Expected: all backend tests PASS and the build completes.

- [ ] **Step 6: Commit the analysis pipeline**

```bash
git add functions/src/modules/analyze-meal functions/src/modules/meals functions/test/modules/analyze-meal
git commit -m "feat: add meal analysis rules and persistence"
```

## Task 8: Lock Down Rules, Emulator Config, And Verification

**Files:**
- Modify: `firebase.json`
- Create: `firestore.rules`
- Create: `firestore.indexes.json`
- Create: `storage.rules`
- Create: `functions/test/security/firestore.rules.test.ts`
- Modify: `README.md`

- [ ] **Step 1: Write the failing Firestore rules test**

```ts
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { beforeAll, describe, expect, it } from 'vitest';
import fs from 'node:fs/promises';

let testEnv: Awaited<ReturnType<typeof initializeTestEnvironment>>;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'mealmitra-dev',
    firestore: {
      rules: await fs.readFile('../../../firestore.rules', 'utf8'),
    },
  });
});

describe('firestore rules', () => {
  it('blocks one user from reading another user meal', async () => {
    const owner = testEnv.authenticatedContext('owner').firestore();
    const attacker = testEnv.authenticatedContext('attacker').firestore();

    await assertSucceeds(owner.doc('users/owner/meals/meal-1').set({ totalCalories: 420 }));
    await assertFails(attacker.doc('users/owner/meals/meal-1').get());
  });
});
```

- [ ] **Step 2: Run the rules test to confirm it fails**

Run: `firebase emulators:exec --project=mealmitra-dev "npm --prefix functions test -- firestore.rules.test.ts"`
Expected: FAIL because the rules file does not exist yet.

- [ ] **Step 3: Implement Firestore rules, Storage rules, and emulator config**

```json
// firebase.json
{
  "functions": {
    "source": "functions"
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "emulators": {
    "auth": { "port": 9099 },
    "functions": { "port": 5001 },
    "firestore": { "port": 8080 },
    "storage": { "port": 9199 },
    "ui": { "enabled": true }
  }
}
```

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /meals/{mealId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /daily_summaries/{dayId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "meals",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "mealType", "order": "ASCENDING" },
        { "fieldPath": "capturedAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/meals/{fileName} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

- [ ] **Step 4: Document the local setup in the README**

```md
## Local Setup

1. Install the Firebase CLI and FlutterFire CLI.
2. Run `flutterfire configure --project=mealmitra-dev --platforms=android,ios,web --out=lib/firebase_options.dart`.
3. Install Flutter and Functions dependencies:
   - `flutter pub get`
   - `npm --prefix functions install`
   - Set `VISION_API_ENDPOINT`
   - Set `VISION_API_KEY`
4. Start local emulators:
   - `firebase emulators:start --project=mealmitra-dev`
5. Run the app:
   - `flutter run`
```

- [ ] **Step 5: Run the final verification suite**

Run:

```bash
flutter test
flutter analyze
npm --prefix functions test
npm --prefix functions run build
firebase emulators:exec --project=mealmitra-dev "npm --prefix functions test -- firestore.rules.test.ts"
```

Expected: all tests PASS, analysis stays clean, and emulator-backed rules verification succeeds.

- [ ] **Step 6: Commit the rules and verification setup**

```bash
git add firebase.json firestore.rules firestore.indexes.json storage.rules README.md functions/test/security
git commit -m "feat: add firebase rules and verification workflow"
```
