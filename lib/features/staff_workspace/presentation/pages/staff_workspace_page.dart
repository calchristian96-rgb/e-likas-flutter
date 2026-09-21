import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
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
    if (context.mounted) context.go('/settings');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffWorkspaceTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (session.isFromCache) _OfflineSessionBanner(l10n: l10n),
          StaffIdentityCard(session: session),
          const SizedBox(height: 20),
          // Grouped by workflow rather than one flat list — mirrors
          // Settings' own sectioning. No standalone "Sync Now" action
          // here: it used to push every pending queue at once with no
          // indication that's what it did, easy to mistake for a
          // scoped action given where it sat (right above Logout).
          // Pending Registrations and EC Board — the two screens that
          // actually have something to sync — each already have their
          // own Sync Now exactly where that queue is visible.
          _SectionLabel(title: l10n.staffWorkspaceFamilyRegistrationSection),
          _WorkspaceAction(
            icon: Icons.person_add_alt_1_outlined,
            iconColor: theme.colorScheme.primary,
            label: l10n.staffWorkspaceRegisterFamily,
            subtitle: l10n.staffWorkspaceRegisterFamilySubtitle,
            onTap: () => context.push('/settings/staff/register-family'),
          ),
          _WorkspaceAction(
            icon: Icons.pending_actions_outlined,
            iconColor: semantic.warning,
            label: l10n.staffWorkspacePendingRegistrations,
            subtitle: l10n.staffWorkspacePendingRegistrationsSubtitle,
            onTap: () => context.push('/settings/staff/pending-registrations'),
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: l10n.staffWorkspaceEvacuationCentersSection),
          // EC Board is its own top-level entry point (not reached via
          // Evacuation Centers management) — ahead of the management
          // actions below since it's the primary fast-entry workflow
          // for staff already at a center.
          _WorkspaceAction(
            icon: Icons.fact_check_outlined,
            iconColor: theme.colorScheme.primary,
            label: l10n.ecBoardTitle,
            subtitle: l10n.ecBoardWorkspaceActionSubtitle,
            onTap: () => context.push('/settings/staff/ec-board'),
          ),
          _WorkspaceAction(
            icon: Icons.add_business_outlined,
            iconColor: semantic.navy,
            label: l10n.staffAddEvacuationCenter,
            subtitle: l10n.staffAddEvacuationCenterSubtitle,
            onTap: () => context.push('/settings/staff/evacuation-centers/add'),
          ),
          _WorkspaceAction(
            icon: Icons.home_work_outlined,
            iconColor: theme.colorScheme.tertiary,
            label: l10n.staffManageEvacuationCenters,
            subtitle: l10n.staffManageEvacuationCentersSubtitle,
            onTap: () => context.push('/settings/staff/evacuation-centers'),
          ),
          const SizedBox(height: 16),
          _SectionLabel(title: l10n.staffWorkspaceRecordsSection),
          _WorkspaceAction(
            icon: Icons.groups_outlined,
            iconColor: semantic.success,
            label: l10n.staffWorkspaceAllEvacuees,
            subtitle: l10n.staffWorkspaceAllEvacueesSubtitle,
            onTap: () => context.push('/settings/staff/all-evacuees'),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: semantic.navy,
          letterSpacing: 0.6,
        ),
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
