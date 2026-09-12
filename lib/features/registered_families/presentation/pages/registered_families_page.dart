import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../domain/entities/registered_families_snapshot.dart';
import '../../domain/entities/registered_family.dart';
import '../providers/registered_families_provider.dart';
import '../widgets/registered_family_detail_sheet.dart';

/// "Registered Families" — the actual `GET /families` roster this
/// staff account is authorized to see (server-scoped, see
/// `RegisteredFamiliesRepository`'s doc comment), cached for offline
/// viewing. Deliberately named for what the data actually is (family
/// units, each with a member count) rather than "All Evacuees," which
/// would imply a flat per-person roster the backend doesn't return.
class RegisteredFamiliesPage extends StatelessWidget {
  const RegisteredFamiliesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(
      builder: (context, session) => const _RegisteredFamiliesBody(),
    );
  }
}

class _RegisteredFamiliesBody extends ConsumerWidget {
  const _RegisteredFamiliesBody();

  Future<void> _handleRefresh(WidgetRef ref) async {
    ref.invalidate(registeredFamiliesProvider);
    try {
      await ref.read(registeredFamiliesProvider.future);
    } catch (_) {
      // The error state below already handles this — this callback
      // just needs to let the pull-to-refresh spinner finish.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snapshotAsync = ref.watch(registeredFamiliesProvider);
    final groupedAsync = ref.watch(registeredFamiliesGroupedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffFamiliesPageTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Always visible — online, offline, no cache, cache
                // present, error, or mid-refresh — the registration
                // form doesn't depend on this list ever having loaded.
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/settings/staff/register-family'),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(l10n.staffWorkspaceRegisterFamily),
                ),
                const SizedBox(height: 8),
                _FreshnessLine(snapshotAsync: snapshotAsync, l10n: l10n),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _handleRefresh(ref),
              child: groupedAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return _CenteredScrollable(
                      child: Text(
                        l10n.staffFamiliesEmptyState,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) =>
                        _BarangaySection(group: groups[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _CenteredScrollable(
                  child: ErrorState(
                    message: _describeError(error, l10n),
                    onRetry: () => ref.invalidate(registeredFamiliesProvider),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _describeError(Object error, AppLocalizations l10n) {
    if (error is NetworkFailure) return l10n.staffFamiliesNoCacheMessage;
    if (error is Failure) return error.message;
    return l10n.staffFamiliesLoadError;
  }
}

class _FreshnessLine extends StatelessWidget {
  const _FreshnessLine({required this.snapshotAsync, required this.l10n});

  final AsyncValue<RegisteredFamiliesSnapshot> snapshotAsync;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final snapshot = snapshotAsync.value;
    final theme = Theme.of(context);
    String text;
    if (snapshot == null) {
      // Still loading, errored, or nothing cached yet — no freshness
      // claim to make.
      return const SizedBox.shrink();
    }
    final epochMs = snapshot.lastSyncedAtEpochMs;
    if (epochMs != null) {
      final formatted = DateFormat.yMMMd().add_jm().format(
        DateTime.fromMillisecondsSinceEpoch(epochMs),
      );
      text = l10n.staffFamiliesShowingAsOf(formatted);
    } else {
      text = l10n.staffFamiliesShowingSaved;
    }
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _BarangaySection extends StatelessWidget {
  const _BarangaySection({required this.group});

  final RegisteredFamiliesGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final barangayLabel = group.barangayName.isEmpty
        ? l10n.staffFamiliesUnknownBarangay
        : group.barangayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
          child: Text(
            '$barangayLabel (${group.families.length})',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        for (final family in group.families)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FamilyCard(family: family),
          ),
      ],
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.family});

  final RegisteredFamily family;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        subtitle: Text(l10n.staffFamiliesMemberCount(family.memberCount)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// Same reasoning as the Alerts/Evacuation Centers list pages:
/// `RefreshIndicator` needs a scrollable descendant even when there's
/// nothing (or just an error) to show.
class _CenteredScrollable extends StatelessWidget {
  const _CenteredScrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        );
      },
    );
  }
}
