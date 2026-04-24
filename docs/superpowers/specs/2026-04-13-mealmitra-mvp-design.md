# MealMitra MVP Design

## Overview

MealMitra is a Flutter mobile app for Indian meal scanning and calorie guidance. The MVP focuses on practical usability over perfect recognition accuracy. Users sign in, capture or select meal photos, receive a normalized meal analysis, and track daily intake against a profile-aware calorie target.

The product is structured around a Flutter client and a Firebase backend. The mobile app owns user experience, local state, camera/gallery flows, and rendering. Firebase owns authentication, storage, persistence, and server-side orchestration of third-party AI and nutrition APIs.

## Product Goals

- Scan Indian meals from a photo.
- Estimate calories at a meal and food-item level.
- Classify meal healthiness as `good`, `moderate`, or `avoid`.
- Provide actionable quantity suggestions such as reducing rice or limiting rotis.
- Store cloud-synced profile and meal history from day one.

## Non-Goals For MVP

- Custom-trained food recognition models.
- Perfect portion estimation.
- Disease-specific clinical nutrition advice.
- Voice input, hardware integrations, or advanced B2B workflows.

## Users And Context

Primary users come from the PRD's target audience:

- Working professionals who want quick meal guidance.
- Gym beginners or weight-loss users who want calorie awareness.
- Users managing lifestyle conditions such as diabetes, PCOS, or blood pressure.
- Students and homemakers who want simple, visual food feedback.

The product must handle common Indian meal patterns, including thalis, rotis, dal, rice, regional dishes, and snack-heavy diets. The architecture must support imperfect recognition and mixed-plate ambiguity without breaking the user experience.

## Architecture

The MVP uses a single Flutter application backed by Firebase.

- Flutter handles onboarding, authentication-aware navigation, profile setup, camera/gallery intake, scan progress, results display, and meal history.
- Firebase Authentication manages identity.
- Firebase Storage stores uploaded meal images.
- Cloud Firestore stores user profiles, meals, and daily summaries.
- Cloud Functions own API keys, call vision and nutrition providers, normalize results, and persist analysis output.

The app does not call third-party AI or nutrition providers directly. Instead, it uploads an image, invokes a Cloud Function, and receives one normalized `meal analysis` response. This keeps secrets off-device and protects the mobile app from provider churn.

## Recommended Approach

Three architecture options were considered:

1. Flutter app with Firebase backend as the source of truth.
2. Flutter-heavy client with minimal backend wrapping.
3. Event-driven backend pipeline with asynchronous analysis orchestration.

Option 1 is the chosen design because it best matches the PRD's MVP scope while keeping user data secure and the client simple.

## Project Structure

```text
mealmitra/
  lib/
    main.dart
    app/
      app.dart
      bootstrap.dart
      router/
      theme/
    core/
      config/
      constants/
      errors/
      utils/
      services/
        firebase/
        camera/
        storage/
    shared/
      widgets/
      models/
    features/
      auth/
        data/
        domain/
        presentation/
      profile/
        data/
        domain/
        presentation/
      dashboard/
        data/
        domain/
        presentation/
      meal_scan/
        data/
          sources/
          repositories/
        domain/
          entities/
          repositories/
          usecases/
        presentation/
          pages/
          widgets/
          controllers/
      meal_history/
        data/
        domain/
        presentation/
      recommendations/
        data/
        domain/
        presentation/
  functions/
    src/
      index.ts
      config/
      shared/
        errors/
        logger/
        types/
      modules/
        analyze-meal/
          analyzeMeal.ts
          visionProvider.ts
          nutritionProvider.ts
          healthClassifier.ts
          quantitySuggestion.ts
          responseMapper.ts
        auth/
        profiles/
        meals/
    package.json
    tsconfig.json
  firebase.json
  firestore.rules
  firestore.indexes.json
  storage.rules
```

## Structure Rationale

- The Flutter app is organized by feature so scan, profile, and history logic stay isolated and easy to evolve.
- Shared infrastructure lives in `core/`, but only truly cross-cutting code belongs there.
- `meal_scan` owns capture and analysis flow.
- `recommendations` owns reusable suggestion behavior and UI concerns that can surface outside the scan screen.
- Cloud Functions are grouped by business capability rather than Firebase primitive, which makes provider swapping and rule changes safer.

## Data Model

### User Profile

```text
users/{uid}
  displayName
  age
  gender
  heightCm
  weightKg
  goal
  activityLevel
  healthFlags
  dailyCalorieTarget
  createdAt
  updatedAt
```

### Meals

```text
users/{uid}/meals/{mealId}
  imageUrl
  mealType
  capturedAt
  detectedItems
  totalCalories
  healthLabel
  suggestions
  source
  analysisVersion
  status
```

Where:

- `mealType` is one of breakfast, lunch, dinner, or snack.
- `detectedItems` contains normalized entries such as name, confidence, estimated portion, and calories.
- `healthLabel` is one of `good`, `moderate`, or `avoid`.
- `status` is one of `processing`, `completed`, or `failed`.

### Daily Summaries

```text
users/{uid}/daily_summaries/{yyyy-mm-dd}
  totalCalories
  mealCount
  caloriesByMealType
  lastMealAt
```

This summary document supports fast dashboard reads without requiring the app to aggregate all meals on every launch.

## End-To-End Request Flow

1. The user signs in with Firebase Authentication.
2. The user captures or selects a meal image in Flutter.
3. The app uploads the image to Firebase Storage in a user-scoped path.
4. The app invokes a callable or HTTPS Cloud Function named around the meal analysis use case.
5. The Cloud Function verifies authentication and validates that the image belongs to the requesting user.
6. The function sends the image to the selected vision provider.
7. Provider output is mapped into internal food-item types.
8. Nutrition estimation logic computes food-item and total calorie values.
9. Rule-based classification assigns a `good`, `moderate`, or `avoid` label.
10. Quantity suggestion logic creates actionable advice such as reducing rice or limiting bread count.
11. The function writes the normalized meal document to Firestore.
12. The function updates the corresponding daily summary.
13. The function returns a normalized analysis payload to the app.
14. The app renders the result and refreshes local history state.

## Backend Responsibilities

The `analyze-meal` backend module is responsible for:

- Validating auth and ownership.
- Fetching the uploaded image reference.
- Calling external providers.
- Normalizing responses into a stable contract.
- Applying India-focused health and quantity rules.
- Writing meal and summary records.
- Returning a client-safe response.

This module boundary allows provider changes without rewriting Flutter presentation code.

## Flutter Responsibilities

The Flutter app is responsible for:

- Authentication-aware app startup and routing.
- Profile capture and editing.
- Camera and gallery input flows.
- Upload progress and analysis status presentation.
- Meal result rendering.
- Dashboard and history rendering from Firestore-backed data.
- Friendly retry and failure states.

## Error Handling

The scan experience should behave as a clear state machine:

`idle -> uploading -> analyzing -> completed | failed`

Expected behavior:

- If upload fails, the app keeps the selected image in memory for a retry.
- If the Cloud Function fails or an external provider times out, the user sees a simple retry-oriented error message.
- If the food is mixed or ambiguous, the backend can still return a low-confidence but usable response with conservative estimates.
- Failed analyses may be stored when useful for diagnostics, but the user experience should not depend on reading provider error details.

## Security

- All uploads and data access require a signed-in Firebase user.
- Storage paths are user-scoped, for example `users/{uid}/meals/{mealId}.jpg`.
- Firestore rules only allow a user to read and write their own profile, meals, and summaries.
- API keys live only in Cloud Functions configuration or secret storage.
- The app never stores third-party provider secrets.
- Backend responses exclude raw provider internals unless needed for internal diagnostics.

## Testing Boundaries

### Flutter

Focus on:

- Auth gate behavior.
- Profile flow behavior.
- Scan state transitions.
- Upload/analyze loading states.
- Result rendering for successful and failed analyses.
- Dashboard and history presentation using mocked repositories.

### Cloud Functions

Focus on:

- Unit tests for `healthClassifier`.
- Unit tests for `quantitySuggestion`.
- Unit tests for response mapping and data normalization.
- Integration-style tests for `analyzeMeal` with mocked vision and nutrition providers.

This gives good confidence in the app contract and the rule-based India-focused logic without requiring real external API calls in every test run.

## MVP Delivery Shape

The PRD's three-week MVP timeline maps cleanly onto this design:

- Week 1: Flutter app shell, auth, profile, dashboard shell, camera/gallery flow.
- Week 2: Storage upload path, Cloud Function scaffolding, provider integration, normalized meal response.
- Week 3: Health classification, quantity suggestions, meal history, daily summaries, and polish.

## Open Risks

- Indian mixed-plate recognition will be imperfect in the MVP.
- Portion estimation is heuristic-based and should be presented as approximate.
- Provider latency or quota issues can affect scan experience.
- The initial rule engine for health classification will need real-world tuning after launch.

## Mitigations

- Use normalized backend contracts so providers can be swapped or improved later.
- Present results as estimates, not clinical advice.
- Prefer conservative, actionable suggestions over false precision.
- Version backend analysis outputs so recommendation logic can evolve without breaking old meal records.

## Success Criteria For This Architecture

- The Flutter app can complete sign-in, profile setup, meal capture, upload, analysis, and history retrieval using a stable Firebase-backed flow.
- The backend can analyze a meal image and return normalized calories, health label, and quantity suggestions.
- User meal history and daily summaries are cloud-synced from the first MVP release.
- The client remains independent of provider-specific APIs and secrets.
