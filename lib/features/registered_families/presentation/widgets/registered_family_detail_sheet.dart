import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/registered_family.dart';

/// Read-only inspection of one cached family record — reused both from
/// the Registered Families list (tap a row) and from Phase 3's "View
/// record" duplicate-match action, so there's exactly one place that
/// renders this data. Never issues a network request: everything shown
/// here already came from the local cache the caller passed in.
Future<void> showRegisteredFamilyDetailSheet(
  BuildContext context,
  RegisteredFamily family,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _RegisteredFamilyDetailSheet(family: family),
  );
}

class _RegisteredFamilyDetailSheet extends StatelessWidget {
  const _RegisteredFamilyDetailSheet({required this.family});

  final RegisteredFamily family;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              family.headOfFamilyName.isEmpty
                  ? l10n.staffFamiliesUnnamedFamily
                  : family.headOfFamilyName,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.staffFamiliesRegisteredIn(family.barangayName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.groups_outlined,
              label: l10n.staffFamiliesMemberCount(family.memberCount),
            ),
            if (family.homeAddress != null && family.homeAddress!.isNotEmpty)
              _DetailRow(icon: Icons.home_outlined, label: family.homeAddress!),
            if (family.evacuationCenterName != null)
              _DetailRow(
                icon: Icons.night_shelter_outlined,
                label: family.evacuationCenterName!,
              ),
            if (family.is4psBeneficiary)
              _DetailRow(
                icon: Icons.verified_outlined,
                label: l10n.staffReg4psBeneficiaryLabel,
              ),
            if (family.createdAt != null)
              _DetailRow(
                icon: Icons.event_outlined,
                label: DateFormat.yMMMd().add_jm().format(family.createdAt!),
              ),
            if (family.memberNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.staffFamiliesMembersSectionTitle,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              for (final name in family.memberNames)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(name),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
