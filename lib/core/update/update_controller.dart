import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/core/update/apk_install_service.dart';
import 'package:mealmitra/core/update/app_update_service.dart';
import 'package:mealmitra/core/update/update_info.dart';

final appUpdateControllerProvider =
    NotifierProvider<AppUpdateController, AppUpdateState>(
      AppUpdateController.new,
    );

class AppUpdateController extends Notifier<AppUpdateState> {
  late final AppUpdateService _updateService;
  late final ApkInstallService _apkInstallService;
  bool _scheduledInitialCheck = false;

  @override
  AppUpdateState build() {
    _updateService = ref.read(appUpdateServiceProvider);
    _apkInstallService = ref.read(apkInstallServiceProvider);

    if (!_scheduledInitialCheck) {
      _scheduledInitialCheck = true;
      Future.microtask(checkForUpdates);
    }

    return const AppUpdateState();
  }

  Future<void> checkForUpdates() async {
    if (state.isChecking) return;

    state = state.copyWith(isChecking: true, error: null);

    try {
      final update = await _updateService.checkForUpdate();
      state = state.copyWith(
        isChecking: false,
        update: update,
        dismissed: false,
        error: null,
        downloadedApkPath: null,
        downloadProgress: null,
        requiresInstallPermission: false,
      );
    } catch (error) {
      state = state.copyWith(isChecking: false, error: error.toString());
    }
  }

  Future<void> primaryAction() async {
    if (state.downloadedApkPath != null) {
      await installDownloadedApk();
      return;
    }
    await downloadAndInstall();
  }

  Future<void> downloadAndInstall() async {
    final update = state.update;
    if (update == null) return;

    if (!Platform.isAndroid || !update.hasApkDownload) {
      await _apkInstallService.openReleasePage(update.releaseUrl);
      return;
    }

    state = state.copyWith(
      isDownloading: true,
      downloadProgress: 0.0,
      error: null,
      requiresInstallPermission: false,
    );

    try {
      final apkPath = await _updateService.downloadApk(
        update: update,
        onProgress: (progress) {
          state = state.copyWith(
            isDownloading: true,
            downloadProgress: progress,
          );
        },
      );

      state = state.copyWith(
        isDownloading: false,
        downloadedApkPath: apkPath,
        downloadProgress: 1.0,
      );
      await installDownloadedApk();
    } catch (error) {
      state = state.copyWith(isDownloading: false, error: error.toString());
    }
  }

  Future<void> installDownloadedApk() async {
    final apkPath = state.downloadedApkPath;
    if (apkPath == null) {
      await downloadAndInstall();
      return;
    }

    try {
      final canInstall = await _apkInstallService.canRequestPackageInstalls();
      if (!canInstall) {
        state = state.copyWith(requiresInstallPermission: true);
        await _apkInstallService.openUnknownSourcesSettings();
        return;
      }

      state = state.copyWith(requiresInstallPermission: false, error: null);
      await _apkInstallService.installApk(apkPath);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  void dismissBanner() {
    if (state.isMandatory) return;
    state = state.copyWith(dismissed: true);
  }
}

class AppUpdateState {
  const AppUpdateState({
    this.isChecking = false,
    this.isDownloading = false,
    this.dismissed = false,
    this.requiresInstallPermission = false,
    this.update,
    this.error,
    this.downloadProgress,
    this.downloadedApkPath,
  });

  final bool isChecking;
  final bool isDownloading;
  final bool dismissed;
  final bool requiresInstallPermission;
  final AppUpdateInfo? update;
  final String? error;
  final double? downloadProgress;
  final String? downloadedApkPath;

  bool get hasUpdate => update != null;
  bool get isMandatory => update?.mandatory ?? false;

  static const _unset = Object();

  AppUpdateState copyWith({
    bool? isChecking,
    bool? isDownloading,
    bool? dismissed,
    bool? requiresInstallPermission,
    Object? update = _unset,
    Object? error = _unset,
    Object? downloadProgress = _unset,
    Object? downloadedApkPath = _unset,
  }) {
    return AppUpdateState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      dismissed: dismissed ?? this.dismissed,
      requiresInstallPermission:
          requiresInstallPermission ?? this.requiresInstallPermission,
      update: identical(update, _unset)
          ? this.update
          : update as AppUpdateInfo?,
      error: identical(error, _unset) ? this.error : error as String?,
      downloadProgress: identical(downloadProgress, _unset)
          ? this.downloadProgress
          : _progressFrom(downloadProgress),
      downloadedApkPath: identical(downloadedApkPath, _unset)
          ? this.downloadedApkPath
          : downloadedApkPath as String?,
    );
  }

  double? _progressFrom(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return value as double?;
  }
}
