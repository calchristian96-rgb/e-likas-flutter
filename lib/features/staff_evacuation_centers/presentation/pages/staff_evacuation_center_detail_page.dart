import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../../evacuation_centers/presentation/widgets/center_photo_card.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../../../staff_auth/domain/entities/staff_session.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../domain/center_edit_permission.dart';
import '../providers/staff_evacuation_centers_provider.dart';
import 'evacuation_center_form_page.dart';

/// Full authenticated detail for one center — the only screen that
/// decides whether Edit is shown (see `center_edit_permission.dart`),
/// since this is the only place that actually has `created_by`.
class StaffEvacuationCenterDetailPage extends StatelessWidget {
  const StaffEvacuationCenterDetailPage({super.key, required this.centerId});

  final int centerId;

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(
      builder: (context, session) =>
          _DetailBody(centerId: centerId, session: session),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.centerId, required this.session});

  final int centerId;
  final StaffSession session;

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    EvacuationCenter center,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EvacuationCenterFormPage(editingCenter: center),
      ),
    );
    // Covers every outcome (saved, cancelled) without needing to know
    // which one happened — a plain refresh is cheap and correct either
    // way, same pattern as PendingRegistrationDetailPage's own _openEdit.
    ref.invalidate(staffCenterDetailProvider(centerId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final centerAsync = ref.watch(staffCenterDetailProvider(centerId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.centerDetailsTitle)),
      body: centerAsync.when(
        data: (center) => _CenterDetailContent(
          center: center,
          session: session,
          onEdit: () => _openEdit(context, ref, center),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorState(
              message: l10n.couldNotLoadCenters,
              onRetry: () =>
                  ref.invalidate(staffCenterDetailProvider(centerId)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterDetailContent extends StatelessWidget {
  const _CenterDetailContent({
    required this.center,
    required this.session,
    required this.onEdit,
  });

  final EvacuationCenter center;
  final StaffSession session;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statusColor = centerStatusColor(context, center);
    final canEdit = canEditCenter(center: center, session: session);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(center.name, style: theme.textTheme.headlineSmall),
                  if (center.displayLocation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      center.displayLocation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StatusBadgeDot(color: statusColor),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(localizedCenterStatus(context, center.status))),
            Chip(label: Text(localizedCenterType(context, center.type))),
            if (!center.hasCoordinates)
              Chip(
                avatar: const Icon(Icons.location_off_outlined, size: 16),
                label: Text(l10n.centerNoLocationSet),
                backgroundColor: theme
                    .extension<AppSemanticColors>()
                    ?.warning
                    .withValues(alpha: 0.12),
              ),
          ],
        ),
        const SizedBox(height: 16),
        CenterPhotoCard(centerId: center.id, photoUrl: center.photoUrl),
        const SizedBox(height: 16),
        const Divider(height: 32),
        Text(l10n.overviewSectionTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (center.capacityFamilies != null)
              _InfoChip(
                label: l10n.centerFieldCapacityFamilies,
                value: '${center.capacityFamilies}',
              ),
            _InfoChip(
              label: l10n.overviewCapacity,
              value: '${center.capacityPersons}',
            ),
            if (center.currentOccupancy != null)
              _InfoChip(
                label: l10n.overviewCurrentOccupancy,
                value: '${center.currentOccupancy}',
              ),
          ],
        ),
        if (center.campManagerName != null ||
            center.campManagerContact != null) ...[
          const Divider(height: 32),
          Text(l10n.centerFieldCampManager, style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          if (center.campManagerName != null)
            _InfoRow(
              icon: Icons.person_outline,
              label: center.campManagerName!,
            ),
          if (center.campManagerContact != null)
            _InfoRow(
              icon: Icons.call_outlined,
              label: center.campManagerContact!,
            ),
        ],
        const SizedBox(height: 24),
        if (canEdit)
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.centerEditEvacuationCenter),
          )
        else
          Text(
            l10n.centerEditNotAllowed,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class StatusBadgeDot extends StatelessWidget {
  const StatusBadgeDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
