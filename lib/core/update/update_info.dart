class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.mandatory,
    required this.notes,
    required this.apkUrl,
    required this.releaseUrl,
    this.publishedAt,
  });

  final String currentVersion;
  final String latestVersion;
  final bool mandatory;
  final String notes;
  final String apkUrl;
  final String releaseUrl;
  final DateTime? publishedAt;

  bool get hasApkDownload => apkUrl.isNotEmpty;
}
