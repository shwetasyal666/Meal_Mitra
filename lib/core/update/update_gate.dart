import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/core/update/update_controller.dart';

class AppUpdateGate extends ConsumerWidget {
  const AppUpdateGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(appUpdateControllerProvider);

    if (updateState.isMandatory && updateState.hasUpdate) {
      return _MandatoryUpdateScreen(state: updateState);
    }

    if (!updateState.hasUpdate || updateState.dismissed) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _UpdateBanner(state: updateState),
        ),
      ],
    );
  }
}

class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appUpdateControllerProvider.notifier);
    final theme = Theme.of(context);
    final notes = state.update?.notes.trim();

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.download, color: Color(0xFF027B3D)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Version ${state.update?.latestVersion} is available',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: controller.dismissBanner,
                  icon: const Icon(LucideIcons.x, size: 18),
                ),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                notes,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (state.isDownloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: state.downloadProgress),
            ],
            if (state.requiresInstallPermission) ...[
              const SizedBox(height: 12),
              const Text(
                'Allow installs from this app in Android settings, then tap Install again.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.dismissBanner,
                    child: const Text('Later'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.isDownloading ? null : controller.primaryAction,
                    child: Text(
                      state.downloadedApkPath != null
                          ? 'Install'
                          : state.update?.hasApkDownload == true
                              ? 'Download'
                              : 'Open Release',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MandatoryUpdateScreen extends ConsumerWidget {
  const _MandatoryUpdateScreen({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appUpdateControllerProvider.notifier);
    final theme = Theme.of(context);
    final notes = state.update?.notes.trim();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.shieldAlert,
                    size: 40,
                    color: Color(0xFF027B3D),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Update required',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Version ${state.update?.latestVersion} must be installed before you can keep using MealMitra.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      notes,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (state.isDownloading) ...[
                    const SizedBox(height: 20),
                    LinearProgressIndicator(value: state.downloadProgress),
                  ],
                  if (state.requiresInstallPermission) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Android needs permission to install APKs from this app. Enable it in settings, then come back and continue.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isDownloading ? null : controller.primaryAction,
                      child: Text(
                        state.downloadedApkPath != null
                            ? 'Install update'
                            : state.update?.hasApkDownload == true
                                ? 'Download update'
                                : 'Open release',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
