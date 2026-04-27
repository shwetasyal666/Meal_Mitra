/// Central app configuration.
/// Toggle `useFirebase` to switch between backend implementations.
class AppConfig {
  AppConfig._();

  /// Set to `true` to use Firebase Auth + Firestore.
  /// Set to `false` to use the existing Node.js backend.
  static const bool useFirebase = true;

  /// Gemini API key for client-side analysis (Firebase mode only).
  /// In backend mode, the key stays on the server.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Cloudinary config for client-side uploads (profile pictures in Firebase mode).
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
