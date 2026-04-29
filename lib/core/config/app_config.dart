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

  /// Google Sign-In Client ID for Web.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
}
