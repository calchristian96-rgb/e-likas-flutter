import '../../../../core/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../outbox/presentation/outbox_providers.dart';
import '../../../staff_auth/domain/entities/staff_session.dart';
import '../../../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../../staff_auth/presentation/widgets/staff_identity_card.dart';

class StaffWorkspacePage extends StatelessWidget {
  const StaffWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(
      builder: (context, session) => _StaffWorkspaceBody(session: session),
    );
  }
}

class _StaffWorkspaceBody extends ConsumerWidget {
  const _StaffWorkspaceBody({required this.session});

  final StaffSession session;

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.staffLogoutDialogTitle),
        content: Text(l10n.staffLogoutDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.staffLogoutDialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(staffAuthProvider.notifier).logout();
    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffWorkspaceTitle)),
      body: ListView(
        padding: pagePadding(context),
        children: [
          if (session.isFromCache) _OfflineSessionBanner(l10n: l10n),
          StaffIdentityCard(session: session),
          const SizedBox(height: 16),
          // What this device still has to send (C15): the answer first.
          if (session.isFieldOfficial) ...[
            _WorkspaceAction(
              icon: Icons.sync,
              iconColor: theme.colorScheme.primary,
              label: l10n.staffSyncRow,
              subtitle: switch (ref.watch(syncSummaryProvider).value) {
                null => '…',
                final s when s.isEmpty => l10n.syncAllDone,
                final s when s.needAttention > 0 =>
                  '${l10n.syncWaitingCount(s.waiting)} · '
                      '${l10n.syncAttentionCount(s.needAttention)}',
                final s => l10n.syncWaitingCount(s.waiting),
              },
              onTap: () => context.push('/staff/more/sync'),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          // Field work lives in the tabs (EC Board, Relief, Barangay);
          // here only the official's centers (location, facility
          // requests). Center details are added and edited on the web.
          if (session.isFieldOfficial)
            _WorkspaceAction(
              icon: Icons.home_work_outlined,
              iconColor: theme.colorScheme.primary,
              label: l10n.staffManageEvacuationCenters,
              subtitle: l10n.staffMyCentersSubtitle,
              onTap: () => context.push('/staff/more/evacuation-centers'),
            ),
          if (session.can(StaffPermission.supportReport) ||
              session.hasOperationsAccess)
            _WorkspaceAction(
              icon: Icons.bug_report_outlined,
              iconColor: theme.colorScheme.primary,
              label: l10n.reportTitle,
              subtitle: l10n.reportSubtitle,
              onTap: () => context.push('/staff/more/report'),
            ),
          // The resident app (Part 3.1), still signed in.
          _WorkspaceAction(
            icon: Icons.public,
            iconColor: theme.colorScheme.primary,
            label: l10n.staffMorePublic,
            subtitle: l10n.staffMorePublicSubtitle,
            onTap: () => context.go('/home'),
          ),
          const SizedBox(height: 16),
          _WorkspaceAction(
            icon: Icons.logout_outlined,
            iconColor: theme.colorScheme.error,
            label: l10n.staffWorkspaceLogout,
            subtitle: l10n.staffWorkspaceLogoutSubtitle,
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _OfflineSessionBanner extends StatelessWidget {
  const _OfflineSessionBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.staffSessionOfflineBanner,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceAction extends StatelessWidget {
  const _WorkspaceAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
