import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../data/app_update_repository.dart';
import '../domain/update_decision.dart';
import 'providers/app_update_providers.dart';
import 'widgets/update_download_dialog.dart';
import 'widgets/update_offer_dialog.dart';

bool _promptOpen = false;

/// The silent, automatic check: on first screen after a cold start
/// ([coldStart]) and on app resume (throttled inside the repository).
/// Shows a dialog only when there is something to offer; every failure
/// is swallowed. Never awaited by callers, so it can't delay startup.
Future<void> runAutomaticUpdateCheck(
  BuildContext context,
  WidgetRef ref, {
  required bool coldStart,
}) async {
  try {
    if (_promptOpen) return;
    final offer = await ref
        .read(appUpdateRepositoryProvider)
        .checkAutomatically(coldStart: coldStart);
    if (offer == null || !context.mounted) return;
    await presentUpdateOffer(context, ref, offer);
  } catch (_) {
    // An update check must never surface an error to a resident.
  }
}

/// Settings → "Check for updates". Unlike the automatic check, tells the
/// resident the outcome.
Future<void> runManualUpdateCheck(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final result = await ref.read(appUpdateRepositoryProvider).checkManually();
  if (!context.mounted) return;
  switch (result.outcome) {
    case ManualCheckOutcome.offer:
      await presentUpdateOffer(context, ref, result.offer!);
    case ManualCheckOutcome.upToDate:
      messenger.showSnackBar(SnackBar(content: Text(l10n.updateUpToDate)));
    case ManualCheckOutcome.failed:
      messenger.showSnackBar(SnackBar(content: Text(l10n.updateCheckFailed)));
  }
}

Future<void> presentUpdateOffer(
  BuildContext context,
  WidgetRef ref,
  UpdateOffer offer,
) async {
  if (_promptOpen) return;
  _promptOpen = true;
  try {
    final repository = ref.read(appUpdateRepositoryProvider);
    final languageCode = Localizations.localeOf(context).languageCode;
    final updateNow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UpdateOfferDialog(
        manifest: offer.manifest,
        kind: offer.kind,
        languageCode: languageCode,
        onLater: () => Navigator.of(dialogContext).pop(false),
        onUpdateNow: () => Navigator.of(dialogContext).pop(true),
      ),
    );

    if (updateNow != true) {
      // A required update is deliberately never snoozed: asked again on
      // every launch.
      if (offer.kind == UpdateKind.optional) {
        await repository.snooze(offer.manifest.latestBuild);
      }
      return;
    }
    if (!context.mounted) return;

    final controller = ref.read(updateDownloadControllerProvider.notifier);
    // Not awaited: the dialog renders the controller's state while the
    // download runs.
    controller.start(offer.manifest);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDownloadDialog(manifest: offer.manifest),
    );
    controller.reset();
  } finally {
    _promptOpen = false;
  }
}
