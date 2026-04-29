import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

final apkInstallServiceProvider = Provider((ref) => ApkInstallService());

class ApkInstallService {
  static const MethodChannel _channel = MethodChannel('mealmitra/apk_install');

  Future<bool> canRequestPackageInstalls() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('canRequestPackageInstalls') ?? false;
  }

  Future<void> openUnknownSourcesSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('openUnknownSourcesSettings');
  }

  Future<void> installApk(String apkPath) async {
    final result = await OpenFilex.open(apkPath, type: 'application/vnd.android.package-archive');
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }

  Future<void> openReleasePage(String releaseUrl) async {
    if (releaseUrl.isEmpty) {
      throw Exception('No release page URL is configured.');
    }

    final uri = Uri.parse(releaseUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Could not open the release page.');
    }
  }
}
