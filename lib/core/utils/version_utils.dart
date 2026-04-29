int compareVersions(String current, String latest) {
  final currentParts = _normalizeVersion(current);
  final latestParts = _normalizeVersion(latest);
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

  return 0;
}

List<int> _normalizeVersion(String version) {
  final cleaned = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
  return cleaned
      .split('.')
      .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}
