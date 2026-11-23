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
import 'package:latlong2/latlong.dart';
import '../pages/center_map_picker_page.dart';

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

/// `GET /gis/centers/{id}`: `can.set_location` and the location's origin
/// ("Set by CSWD", "Set by barangay official", "Original data"). Null
/// when it cannot be read (the permission decides then).
final centerGisProvider = FutureProvider.autoDispose
    .family<({bool? canSetLocation, String? originLabel}), int>((
      ref,
      id,
    ) async {
      try {
        final response = await ref
            .watch(staffApiClientProvider)
            .get('/gis/centers/$id');
        final data =
            (response.data as Map<String, dynamic>)['data']
                as Map<String, dynamic>;
        final center = data['center'] is Map<String, dynamic>
            ? data['center'] as Map<String, dynamic>
            : data;
        final can = (data['can'] ?? center['can']) as Map<String, dynamic>?;
        return (
          canSetLocation: can == null ? null : can['set_location'] == true,
          originLabel: center['location_origin_label'] as String?,
        );
      } catch (_) {
        return (canSetLocation: null, originLabel: null);
      }
    });

/// A center's map location (0.4.0 Part 5): "Use my current location"
/// (the phone's GPS, with permission) or "Pick on the map". An official's
/// point for an approved center goes to CSWD for approval; CSWD's is
/// saved at once. Sent through the offline queue.
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

  /// `can.set_location` from the server when known; otherwise
  /// `centers.set_location`: CSWD any center, an official their own.
  bool get _canSet {
    final can = ref
        .watch(centerGisProvider(widget.center.id))
        .value
        ?.canSetLocation;
    if (can != null) return can;
    final s = widget.session;
    final permitted =
        s.can(StaffPermission.centersSetLocation) ||
        s.can(StaffPermission.centersEdit);
    if (!permitted) return false;
    if (s.isCityMonitor) return true;
    return s.barangayId != null && widget.center.barangayId == s.barangayId;
  }

  Future<void> _pickOnMap() async {
    final c = widget.center;
    final point = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => CenterMapPickerPage(
          centerName: c.name,
          initial: c.hasCoordinates ? LatLng(c.latitude!, c.longitude!) : null,
        ),
      ),
    );
    if (point == null || !mounted) return;
    await _confirmAndSend(point.latitude, point.longitude, null);
  }

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
    await _confirmAndSend(
      position.latitude,
      position.longitude,
      position.accuracy,
    );
  }

  Future<void> _confirmAndSend(
    double latitude,
    double longitude,
    double? accuracy,
  ) async {
    final l10n = AppLocalizations.of(context);
    final cswd = widget.session.isCityMonitor;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.centerLocationConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${latitude.toStringAsFixed(6)}, '
              '${longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (accuracy != null)
              Text(l10n.centerLocationAccuracy(accuracy.round())),
            if (accuracy != null && accuracy > 50) ...[
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
            Text(
              cswd
                  ? l10n.centerLocationCswdSaves
                  : l10n.centerLocationGoesToCswd,
            ),
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
      body: {'latitude': latitude, 'longitude': longitude},
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
      line =
          ref.watch(centerGisProvider(widget.center.id)).value?.originLabel ??
          state?.locationSource ??
          l10n.centerLocationOnMap;
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
            label: Text(l10n.centerLocationUseMine),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _locating ? null : _pickOnMap,
            icon: const Icon(Icons.map_outlined),
            label: Text(l10n.centerLocationPickOnMap),
          ),
        ],
      ],
    );
  }
}
