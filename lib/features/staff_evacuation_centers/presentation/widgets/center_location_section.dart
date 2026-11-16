import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/result.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/network/staff_api_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../../outbox/domain/pending_action.dart';
import '../../../outbox/presentation/outbox_providers.dart';
import '../../../staff_auth/domain/entities/staff_session.dart';

/// Where one center stands on the map (backend map-api.md, GIS center
/// rows): a location, one waiting for CSWD, or none yet.
class CenterLocationState {
  const CenterLocationState({
    required this.hasLocation,
    this.pendingSubmittedAt,
    this.locationSource,
  });

  final bool hasLocation;

  /// A location sent by the barangay waits for CSWD (dashed on the web).
  final DateTime? pendingSubmittedAt;

  /// "OpenStreetMap - to be verified by barangay" when filled from OSM.
  final String? locationSource;

  bool get isPending => pendingSubmittedAt != null;
}

/// `GET /gis/center-locations` for the official's barangay, by center
/// id. Online only; empty when it cannot be read.
final centerLocationsProvider =
    FutureProvider.autoDispose<Map<int, CenterLocationState>>((ref) async {
      ref.watch(outboxRevisionProvider);
      try {
        final response = await ref
            .watch(staffApiClientProvider)
            .get('/gis/center-locations');
        final data =
            (response.data as Map<String, dynamic>)['data']
                as Map<String, dynamic>;
        final result = <int, CenterLocationState>{};
        for (final list in [data['without_location'], data['pending']]) {
          for (final row in list as List? ?? const []) {
            final c = row as Map<String, dynamic>;
            final pending = c['pending_location'] as Map<String, dynamic>?;
            result[c['id'] as int] = CenterLocationState(
              hasLocation: c['has_location'] == true,
              locationSource: c['location_source'] as String?,
              pendingSubmittedAt: pending == null
                  ? null
                  : DateTime.tryParse(
                          pending['submitted_at'] as String? ?? '',
                        )?.toLocal() ??
                        DateTime.now(),
            );
          }
        }
        return result;
      } catch (_) {
        return const {};
      }
    });

/// "Set location from this phone" (C19): stand at the center, read the
/// GPS, confirm, and the point goes to CSWD for approval through the
/// offline queue (an Unverified center takes it at once).
class CenterLocationSection extends ConsumerStatefulWidget {
  const CenterLocationSection({
    super.key,
    required this.center,
    required this.session,
  });

  final EvacuationCenter center;
  final StaffSession session;

  @override
  ConsumerState<CenterLocationSection> createState() =>
      _CenterLocationSectionState();
}

class _CenterLocationSectionState extends ConsumerState<CenterLocationSection> {
  bool _locating = false;

  bool get _canSet =>
      widget.session.can(StaffPermission.centersEdit) &&
      widget.session.barangayId != null &&
      widget.center.barangayId == widget.session.barangayId;

  Future<void> _setFromPhone() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _locating = true);
    final result = await ref.read(locationServiceProvider).getCurrentPosition();
    if (!mounted) return;
    setState(() => _locating = false);
    final position = switch (result) {
      Success(:final value) => value,
      Failed() => null,
    };
    if (position == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.couldNotDetermineLocation)));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.centerLocationConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${position.latitude.toStringAsFixed(6)}, '
              '${position.longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.centerLocationAccuracy(position.accuracy.round())),
            if (position.accuracy > 50) ...[
              const SizedBox(height: 8),
              Text(
                l10n.centerLocationLowAccuracy,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).extension<AppSemanticColors>()!.warning,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(l10n.centerLocationGoesToCswd),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.centerLocationSend),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await enqueueStaffAction(
      ref,
      kind: PendingActionKind.centerLocation,
      method: 'POST',
      path: '/gis/centers/${widget.center.id}/location',
      body: {'latitude': position.latitude, 'longitude': position.longitude},
      summary: l10n.centerLocationSummary(widget.center.name),
      subjectKey: 'center:${widget.center.id}:location',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.centerLocationQueued)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(centerLocationsProvider).value?[widget.center.id];
    final queued = (ref.watch(pendingActionsProvider).value ?? const []).any(
      (a) => a.subjectKey == 'center:${widget.center.id}:location',
    );
    final String line;
    if (queued) {
      line = l10n.centerLocationWaitingToSync;
    } else if (state?.isPending ?? false) {
      line = l10n.centerLocationWaitingForCswd;
    } else if (widget.center.hasCoordinates || (state?.hasLocation ?? false)) {
      line = state?.locationSource ?? l10n.centerLocationOnMap;
    } else {
      line = l10n.centerNoLocationSet;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.centerLocationTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(line, style: theme.textTheme.bodyMedium),
        if (_canSet) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _locating ? null : _setFromPhone,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(l10n.centerLocationSetFromPhone),
          ),
        ],
      ],
    );
  }
}
