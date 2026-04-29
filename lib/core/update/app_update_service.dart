import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mealmitra/core/config/app_config.dart';
import 'package:mealmitra/core/update/update_info.dart';
import 'package:mealmitra/core/utils/version_utils.dart';

final appUpdateServiceProvider = Provider((ref) => AppUpdateService());

class AppUpdateService {
  final http.Client _client = http.Client();

  Future<AppUpdateInfo?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final remote = await _fetchRemoteRelease();

    if (remote == null) return null;
    if (compareVersions(currentVersion, remote.version) >= 0) {
      return null;
    }

    return AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: remote.version,
      mandatory: remote.mandatory,
      notes: remote.notes,
      apkUrl: remote.apkUrl,
      releaseUrl: remote.releaseUrl,
      publishedAt: remote.publishedAt,
    );
  }

  Future<String> downloadApk({
    required AppUpdateInfo update,
    required void Function(double progress) onProgress,
  }) async {
    if (update.apkUrl.isEmpty) {
      throw Exception('No APK asset is available for this release.');
    }

    final request = http.Request('GET', Uri.parse(update.apkUrl));
    final response = await _client.send(request).timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Download failed with status ${response.statusCode}.');
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/mealmitra-${update.latestVersion}.apk');
    if (await file.exists()) {
      await file.delete();
    }

    final sink = file.openWrite();
    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    if (!await file.exists()) {
      throw Exception('APK download did not complete.');
    }

    onProgress(1);
    return file.path;
  }

  Future<_RemoteRelease?> _fetchRemoteRelease() async {
    if (AppConfig.updateManifestUrl.isNotEmpty) {
      return _fetchHostedManifest(AppConfig.updateManifestUrl);
    }
    if (AppConfig.githubRepo.isNotEmpty) {
      return _fetchGitHubRelease(AppConfig.githubRepo);
    }
    return null;
  }

  Future<_RemoteRelease> _fetchHostedManifest(String manifestUrl) async {
    final response = await _client
        .get(Uri.parse(manifestUrl))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Update manifest request failed (${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return _RemoteRelease(
      version: payload['version']?.toString() ?? '',
      mandatory: payload['mandatory'] == true,
      notes: payload['notes']?.toString() ?? '',
      apkUrl: payload['apkUrl']?.toString() ?? '',
      releaseUrl: payload['releaseUrl']?.toString() ?? '',
      publishedAt: DateTime.tryParse(payload['publishedAt']?.toString() ?? ''),
    );
  }

  Future<_RemoteRelease> _fetchGitHubRelease(String repo) async {
    final response = await _client
        .get(
          Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GitHub release lookup failed (${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final assets = (payload['assets'] as List<dynamic>? ?? const []);
    final apkAsset = assets.cast<Map<String, dynamic>?>().firstWhere(
          (asset) => asset != null && (asset['name']?.toString().endsWith('.apk') ?? false),
          orElse: () => null,
        );

    final body = payload['body']?.toString() ?? '';
    return _RemoteRelease(
      version: payload['tag_name']?.toString() ?? '',
      mandatory: _parseMandatory(body),
      notes: _stripMandatoryMarkers(body),
      apkUrl: apkAsset?['browser_download_url']?.toString() ?? '',
      releaseUrl: payload['html_url']?.toString() ?? '',
      publishedAt: DateTime.tryParse(payload['published_at']?.toString() ?? ''),
    );
  }

  bool _parseMandatory(String body) {
    final normalized = body.toLowerCase();
    return normalized.contains('[mandatory]') ||
        normalized.contains('mandatory: true') ||
        normalized.contains('force_update: true');
  }

  String _stripMandatoryMarkers(String body) {
    return body
        .replaceAll('[mandatory]', '')
        .replaceAll('mandatory: true', '')
        .replaceAll('force_update: true', '')
        .trim();
  }
}

class _RemoteRelease {
  const _RemoteRelease({
    required this.version,
    required this.mandatory,
    required this.notes,
    required this.apkUrl,
    required this.releaseUrl,
    this.publishedAt,
  });

  final String version;
  final bool mandatory;
  final String notes;
  final String apkUrl;
  final String releaseUrl;
  final DateTime? publishedAt;
}
