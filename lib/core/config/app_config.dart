/// Central app configuration.
/// Toggle `useFirebase` to switch between backend implementations.
class AppConfig {
  AppConfig._();

  /// Set to `true` to use Firebase Auth + Firestore.
  /// Set to `false` to use the existing Node.js backend.
  static const bool useFirebase = true;

  /// Optional hosted manifest endpoint for app updates.
  /// Expected shape:
  /// {
  ///   "version": "1.2.0",
  ///   "mandatory": false,
  ///   "notes": "Release notes",
  ///   "apkUrl": "https://...",
  ///   "releaseUrl": "https://..."
  /// }
  static const String updateManifestUrl = String.fromEnvironment(
    'UPDATE_MANIFEST_URL',
    defaultValue: '',
  );

  /// GitHub repository in `owner/repo` format used when no update manifest URL
  /// is provided.
  static const String githubRepo = String.fromEnvironment(
    'GITHUB_REPO',
    defaultValue: '',
  );

  /// Google Sign-In Client ID for Web.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
}
