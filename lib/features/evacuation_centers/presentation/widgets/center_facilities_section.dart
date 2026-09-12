import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/center_facility.dart';
import '../providers/evacuation_centers_provider.dart';
import 'facility_type_display.dart';

/// The Evacuation Center Details page's Facilities section — a
/// self-contained, independently-loading `ConsumerWidget` so a slow or
/// failed facilities request never blocks or fails the rest of the
/// page (photo, status, capacity, occupancy, address, Get Directions,
/// View on Map all come from the existing list-based
/// `centerByIdProvider` and are completely unaffected by this widget).
class CenterFacilitiesSection extends ConsumerWidget {
  const CenterFacilitiesSection({super.key, required this.centerId});

  final int centerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final facilitiesAsync = ref.watch(centerFacilitiesProvider(centerId));

    return facilitiesAsync.when(
      loading: () => const _FacilitiesLoading(),
      error: (error, _) => ErrorState(
        message: l10n.couldNotLoadFacilities,
        onRetry: () => ref.invalidate(centerFacilitiesProvider(centerId)),
      ),
      data: (facilities) {
        if (facilities.isEmpty) {
          return EmptyState(
            message: l10n.facilitiesNotAvailable,
            icon: Icons.checklist_outlined,
          );
        }
        return _FacilitiesChecklist(facilities: facilities);
      },
    );
  }
}

class _FacilitiesLoading extends StatelessWidget {
  const _FacilitiesLoading();

  @override
  Widget build(BuildContext context) {
    // Same compact inline-spinner treatment as CenterPhotoCard's own
    // loading state — a small, calm indicator, not a full-page spinner.
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

/// Renders the fixed 19-type checklist, reconciled against whichever
/// subset of types the API actually returned a record for. This is
/// "Option A+B" resolved deliberately, not guessed: the backend only
/// ever sends records that exist (confirmed against
/// `PublicController::evacuationCenter()` — `facilities` is a plain
/// `->map()` over the loaded relation, never padded to 19), so every
/// known type without a matching record is shown as "not recorded"
/// rather than silently omitted — the checklist always shows all 19
/// rows, matching the web version's "19-type checklist" concept,
/// while never fabricating an availability or a note for a type with
/// no backend record at all.
class _FacilitiesChecklist extends StatelessWidget {
  const _FacilitiesChecklist({required this.facilities});

  final List<CenterFacility> facilities;

  @override
  Widget build(BuildContext context) {
    final byType = {for (final f in facilities) f.facilityType: f};

    return Column(
      children: [
        for (final type in evacuationCenterFacilityTypeValues)
          _FacilityRow(facilityType: type, facility: byType[type]),
      ],
    );
  }
}

class _FacilityRow extends StatelessWidget {
  const _FacilityRow({required this.facilityType, required this.facility});

  final String facilityType;

  /// Null when the API returned no record for this type at all —
  /// distinct from a record that exists with `isAvailable: false`.
  final CenterFacility? facility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final label = localizedFacilityType(context, facilityType);
    final record = facility;

    final isAvailable = record?.isAvailable ?? false;
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final labelColor = isAvailable ? null : mutedColor;

    // Status line: real quantity when available, an explicit
    // "unavailable" when a record exists but marks it so, or a
    // neutral "not recorded" when no record exists at all — three
    // distinct, accurate states, never conflated into one guess.
    final String statusText;
    if (record == null) {
      statusText = l10n.facilityNotRecorded;
    } else if (isAvailable) {
      statusText = record.quantity > 0
          ? l10n.facilityQuantityAvailable(record.quantity)
          : l10n.facilityAvailable;
    } else {
      statusText = l10n.facilityUnavailable;
    }

    // Only ever shown for a real record with a real note — never
    // fabricated for a null concernsAndNeeds or a missing record.
    final note = record?.concernsAndNeeds;
    final hasNote = note != null && note.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: isAvailable ? theme.colorScheme.primary : mutedColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: labelColor,
                  ),
                ),
                Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
                ),
                if (hasNote)
                  Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
