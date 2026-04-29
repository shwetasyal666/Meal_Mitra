/// Central app configuration.
/// Toggle `useFirebase` to switch between backend implementations.
class AppConfig {
  AppConfig._();

  /// Set to `true` to use Firebase Auth + Firestore.
  /// Set to `false` to use the existing Node.js backend.
  static const bool useFirebase = true;

  /// GitHub repository in `owner/repo` format used for APK release checks.
  static const String githubRepo = String.fromEnvironment(
    'GITHUB_REPO',
    defaultValue: 'shwetasyal666/Meal_Mitra',
  );

  /// Cloudinary config for client-side uploads.
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: '',
  );
  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'mealmitra_unsigned',
  );

  /// Preferred: point this at a small Cloudflare Worker / serverless proxy so
  /// provider API keys are not shipped inside the APK.
  static const String foodAiProxyUrl = String.fromEnvironment(
    'FOOD_AI_PROXY_URL',
    defaultValue: '',
  );

  /// Direct OpenRouter key fallback. Useful for testing, but any key embedded
  /// in a mobile APK should be treated as public.
  static const String openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );

  static const String _foodAiModel = String.fromEnvironment(
    'FOOD_AI_MODEL',
    defaultValue: 'openrouter/free',
  );
  static String get foodAiModel =>
      _foodAiModel.trim().isEmpty ? 'openrouter/free' : _foodAiModel;

  /// Google Sign-In Client ID for Web.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
}
