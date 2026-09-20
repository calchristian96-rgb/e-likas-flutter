import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/providers/home_provider.dart';
import '../../l10n/app_localizations.dart';

/// A connectivity-aware "Sync Now" AppBar action, reused everywhere a
/// screen can trigger `StaffSyncService.run()` (Pending Registrations,
/// EC Board) — one place to get "disabled with a clear reason when
/// offline" right, instead of each screen leaving its own sync button
/// always tappable and letting a run against no connection quietly
/// process nothing.
///
/// [isSyncing] and [onSync] stay owned by the caller (each screen already
/// tracks its own in-flight state to show a result snackbar afterwards)
/// — this widget only decides whether the action is currently allowed.
class SyncNowAction extends ConsumerWidget {
  const SyncNowAction({
    super.key,
    required this.isSyncing,
    required this.onSync,
  });

  final bool isSyncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isConnected = ref.watch(connectivityStatusProvider).value ?? false;
    final canSync = isConnected && !isSyncing;

    return IconButton(
      icon: isSyncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync_outlined),
      tooltip: isConnected
          ? l10n.staffWorkspaceSyncNow
          : l10n.staffSyncRequiresConnectionMessage,
      onPressed: canSync ? onSync : null,
    );
  }
}
