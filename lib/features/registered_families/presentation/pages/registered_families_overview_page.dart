import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/widgets/sync_now_action.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../family_registration/data/services/staff_sync_service.dart'
    show StaffSyncRunResult;
import '../../../family_registration/domain/entities/pending_registration.dart';
import '../../../family_registration/domain/entities/pending_registration_status.dart';
import '../../../family_registration/presentation/providers/pending_queue_provider.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../domain/entities/registered_family.dart';
import '../providers/registered_families_provider.dart';
import '../widgets/registered_family_detail_sheet.dart';

/// "Registered Families" — every family record this *device* holds,
/// split into "Not yet synced" (this device's own pending family
/// registration queue) and "Synced" (the server roster this account
/// can see, cached for offline). Any barangay: a barangay official may
/// legitimately register a displaced family from another barangay
/// (see `FamilyRegistrationFormPage`'s barangay field), and until that
/// record syncs this is the only screen it shows up on — the scoped
/// "Evacuees" roster only ever holds server data for the staff
/// member's own barangay.
///
/// Also where the old standalone "Pending Registrations" list lives
/// now: its content is exactly the "Not yet synced" section here, so
/// that page stays reachable only by its direct route rather than as a
/// separate Staff Dashboard entry. Tapping a pending record still opens
/// the same `PendingRegistrationDetailPage` (review/edit/delete).
class RegisteredFamiliesOverviewPage extends StatelessWidget {
  const RegisteredFamiliesOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(builder: (context, session) => const _Body());
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body();

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final StaffSyncRunResult result = await ref.read(
      staffSyncFamilyRegistrationsOnlyProvider,
    )();
    if (!mounted) return;
    setState(() => _syncing = false);
    final l10n = AppLocalizations.of(context);
    final message = result.wasOffline
        ? l10n.staffSyncRequiresConnectionMessage
        : result.stoppedForAuth
        ? l10n.staffSyncStoppedForAuthMessage
        : l10n.staffSyncCompletedMessage(result.processed);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refresh() async {
    ref.invalidate(pendingRegistrationsProvider);
    ref.invalidate(registeredFamiliesProvider);
    try {
      await ref.read(registeredFamiliesProvider.future);
    } catch (_) {
      // Shown by the Synced section's own error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pendingAsync = ref.watch(pendingRegistrationsProvider);
    final syncedAsync = ref.watch(registeredFamiliesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registeredFamiliesTitle),
        actions: [SyncNowAction(isSyncing: _syncing, onSync: _syncNow)],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Full family registration stays reachable here (and by
            // its direct route) now that it's no longer its own Staff
            // Dashboard entry — EC Board's Add Evacuee is the primary
            // fast-entry path, this is for recording a whole household.
            FilledButton.icon(
              onPressed: () => context.push('/settings/staff/register-family'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l10n.staffWorkspaceRegisterFamily),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.registeredFamiliesSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              icon: Icons.cloud_off_outlined,
              title: l10n.registeredFamiliesNotSyncedSection,
              count: pendingAsync.value?.length,
            ),
            const SizedBox(height: 8),
            ...pendingAsync.when(
              data: (items) => items.isEmpty
                  ? [_EmptyNote(text: l10n.staffPendingListEmpty)]
                  : [
                      for (final item in items) ...[
                        _PendingTile(summary: item),
                        const SizedBox(height: 8),
                      ],
                    ],
              loading: () => const [_Loading()],
              error: (_, _) => [_EmptyNote(text: l10n.staffPendingListError)],
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              icon: Icons.cloud_done_outlined,
              title: l10n.registeredFamiliesSyncedSection,
              count: syncedAsync.value?.families.length,
            ),
            const SizedBox(height: 8),
            ...syncedAsync.when(
              data: (snapshot) {
                final families = [...snapshot.families]
                  ..sort((a, b) {
                    final byBarangay = a.barangayName.toLowerCase().compareTo(
                      b.barangayName.toLowerCase(),
                    );
                    if (byBarangay != 0) return byBarangay;
                    // Same order as Evacuees: named heads first.
                    final aEmpty = a.headOfFamilyName.isEmpty;
                    final bEmpty = b.headOfFamilyName.isEmpty;
                    if (aEmpty != bEmpty) return aEmpty ? 1 : -1;
                    return a.headOfFamilyName.toLowerCase().compareTo(
                      b.headOfFamilyName.toLowerCase(),
                    );
                  });
                if (families.isEmpty) {
                  return [_EmptyNote(text: l10n.staffFamiliesEmptyState)];
                }
                return [
                  for (final family in families) ...[
                    _SyncedTile(family: family),
                    const SizedBox(height: 8),
                  ],
                ];
              },
              loading: () => const [_Loading()],
              error: (error, _) => [
                _EmptyNote(
                  text: error is NetworkFailure
                      ? l10n.staffFamiliesNoCacheMessage
                      : l10n.staffFamiliesLoadError,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: semantic.navy,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == null ? title : '$title ($count)',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.summary});

  final PendingRegistrationSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat.yMMMd().add_jm();
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => context.push(
          '/settings/staff/pending-registrations/${summary.localId}',
        ),
        leading: switch (summary.status) {
          PendingRegistrationStatus.needsAttention => Icon(
            Icons.error_outline,
            color: colorScheme.error,
          ),
          PendingRegistrationStatus.syncing => SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          PendingRegistrationStatus.pending => Icon(
            Icons.cloud_off_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
        },
        title: Text(
          summary.headOfFamilyName.isEmpty
              ? l10n.staffPendingNoHeadName
              : summary.headOfFamilyName,
        ),
        subtitle: Text(
          l10n.staffPendingSubtitle(
            summary.memberCount,
            summary.barangayName,
            dateFormat.format(summary.createdAt),
          ),
        ),
        trailing: summary.status == PendingRegistrationStatus.needsAttention
            ? Text(
                l10n.staffStatusNeedsAttention,
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _SyncedTile extends StatelessWidget {
  const _SyncedTile({required this.family});

  final RegisteredFamily family;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final barangay = family.barangayName.isEmpty
        ? l10n.staffFamiliesUnknownBarangay
        : family.barangayName;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => showRegisteredFamilyDetailSheet(context, family),
        leading: const CircleAvatar(child: Icon(Icons.family_restroom)),
        title: Text(
          family.headOfFamilyName.isEmpty
              ? l10n.staffFamiliesUnnamedFamily
              : family.headOfFamilyName,
        ),
        subtitle: Text(
          '${l10n.staffFamiliesMemberCount(family.memberCount)} • $barangay',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
