class ReleaseVersion {
  const ReleaseVersion({
    required this.appVersion,
    required this.buildNumber,
  });

  final String appVersion;
  final int buildNumber;

  String get label => '$appVersion (build $buildNumber)';
}

ReleaseVersion parseInstalledVersion({
  required String appVersion,
  required String buildNumber,
}) {
  return ReleaseVersion(
    appVersion: appVersion.trim(),
    buildNumber: int.tryParse(buildNumber.trim()) ?? 0,
  );
}

ReleaseVersion? parseGitHubReleaseTag(String tagName) {
  final match = RegExp(
    r'^[vV]?(\d+\.\d+\.\d+)-build-(\d+)$',
  ).firstMatch(tagName.trim());
  if (match == null) return null;

  return ReleaseVersion(
    appVersion: match.group(1)!,
    buildNumber: int.parse(match.group(2)!),
  );
}

int compareReleaseVersions(ReleaseVersion current, ReleaseVersion latest) {
  final currentParts = _normalizeVersion(current.appVersion);
  final latestParts = _normalizeVersion(latest.appVersion);
  final maxLength = currentParts.length > latestParts.length
      ? currentParts.length
      : latestParts.length;

  for (var index = 0; index < maxLength; index++) {
    final currentPart = index < currentParts.length ? currentParts[index] : 0;
    final latestPart = index < latestParts.length ? latestParts[index] : 0;
    if (currentPart != latestPart) {
      return currentPart.compareTo(latestPart);
    }
  }

  return current.buildNumber.compareTo(latest.buildNumber);
}

List<int> _normalizeVersion(String version) {
  return version
      .trim()
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();
}
