class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentLabel,
    required this.latestLabel,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.mandatory,
    required this.notes,
    required this.apkUrl,
    required this.releaseUrl,
    this.publishedAt,
  });

  final String currentLabel;
  final String latestLabel;
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final bool mandatory;
  final String notes;
  final String apkUrl;
  final String releaseUrl;
  final DateTime? publishedAt;

  bool get hasApkDownload => apkUrl.isNotEmpty;
}
