import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/app_update_manifest.dart';
import '../providers/app_update_providers.dart';

/// Progress, verification, install hand-off and the failure state for
/// one update attempt. Driven entirely by
/// [updateDownloadControllerProvider]; the caller starts the download.
class UpdateDownloadDialog extends ConsumerWidget {
  const UpdateDownloadDialog({super.key, required this.manifest});

  final AppUpdateManifest manifest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(updateDownloadControllerProvider);
    final controller = ref.read(updateDownloadControllerProvider.notifier);

    void close() {
      controller.reset();
      Navigator.of(context).pop();
    }

    switch (state.phase) {
      case UpdateDownloadPhase.idle:
      case UpdateDownloadPhase.downloading:
      case UpdateDownloadPhase.verifying:
        final verifying = state.phase == UpdateDownloadPhase.verifying;
        final progress = state.progress;
        return AlertDialog(
          title: Text(l10n.updateDownloading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                // Determinate while the size is known; indeterminate while
                // verifying (the hash pass) or when the server sent no size.
                value: verifying ? null : progress,
              ),
              const SizedBox(height: 8),
              Text(
                verifying
                    ? l10n.updateVerifying
                    : progress == null
                    ? ''
                    : '${(progress * 100).floor()}%',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.cancel();
                Navigator.of(context).pop();
              },
              child: Text(l10n.updateCancel),
            ),
          ],
        );
      case UpdateDownloadPhase.ready:
        return AlertDialog(
          title: Text(l10n.updateReadyToInstall),
          content: Text(l10n.updateInstallHint),
          actions: [
            TextButton(onPressed: close, child: Text(l10n.updateLater)),
            FilledButton(
              onPressed: controller.installAgain,
              child: Text(l10n.updateInstall),
            ),
          ],
        );
      case UpdateDownloadPhase.failed:
        return AlertDialog(
          title: Text(l10n.updateFailedTitle),
          content: Text(l10n.updateFailedBody),
          actions: [
            TextButton(onPressed: close, child: Text(l10n.updateLater)),
            TextButton(
              onPressed: () =>
                  ref.read(externalUrlOpenerProvider)(manifest.apkUrl),
              child: Text(l10n.updateOpenInBrowser),
            ),
            FilledButton(
              onPressed: () => controller.start(manifest),
              child: Text(l10n.updateTryAgain),
            ),
          ],
        );
    }
  }
}
