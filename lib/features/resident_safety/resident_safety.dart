import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../core/error/result.dart';
import '../../core/utils/distance_calculator.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../barangay_status/data/barangay_outlines.dart';
import '../barangay_status/domain/barangay_status.dart';
import '../barangay_status/presentation/barangay_status_providers.dart';
import '../barangay_status/presentation/resident_area.dart';
import '../evacuation_centers/domain/entities/evacuation_center.dart';
import '../evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import '../evacuation_centers/presentation/widgets/capacity_text.dart';
import '../evacuation_centers/presentation/widgets/center_directions.dart';
import '../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../home/presentation/widgets/nearest_center_preview.dart'
    show NearestCenterPreview, formatDistance;
import '../../app/theme/app_theme.dart';

/// Mayon's summit and its danger zones (apps-api-2026-11-22.md section 1,
/// Volcanic events): the permanent danger zone is 6 km, the extended one
/// 7 km. Approximate zones based on distance from the summit.
abstract final class Mayon {
  static const summit = LatLng(13.2570, 123.6856);
  static const permanentKm = 6.0;
  static const extendedKm = 7.0;

  /// "Near": within this much beyond 7 km (the server's default; the
  /// server's own `mayon_zones.buffer_km` wins when known).
  static const bufferKm = 3.0;

  static double kmFrom(double lat, double lng) =>
      DistanceCalculator.metersBetween(
        lat1: summit.latitude,
        lon1: summit.longitude,
        lat2: lat,
        lon2: lng,
      ) /
      1000;

  /// A center inside a danger zone: within 6 km always; during a
  /// volcanic event also within 7 km. A center without a location is
  /// never called safe or unsafe here.
  static bool centerInside(EvacuationCenter c, {required bool volcanic}) {
    if (!c.hasCoordinates) return false;
    final km = kmFrom(c.latitude!, c.longitude!);
    return km <= permanentKm || (volcanic && km <= extendedKm);
  }

  /// The barangay outline's nearest point to the summit, in km (0 when
  /// the summit is inside it).
  static double nearestKm(BarangayOutline o) {
    var best = double.infinity;
    for (final p in o.rings.first) {
      final km = kmFrom(p.latitude, p.longitude);
      if (km < best) best = km;
    }
    return best;
  }
}

/// Whether the open event is volcanic (the public board's event).
final volcanicEventProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(barangayStatusBoardProvider).value?.isVolcanic ?? false,
);

/// A center a resident may be sent to: open (not Full or Closed), and
/// not inside Mayon's danger zone.
bool isSafeCenter(EvacuationCenter c, {required bool volcanic}) {
  final status = c.status.toLowerCase();
  if (status == 'full' || status == 'closed') return false;
  return !Mayon.centerInside(c, volcanic: volcanic);
}

/// The three nearest safe centers from [position], nearest first, from
/// the full list (saved for offline), so filtering never leaves fewer
/// than three when more exist.
final safeNearestCentersProvider = FutureProvider.autoDispose
    .family<List<EvacuationCenter>, LatLng>((ref, position) async {
      final volcanic = ref.watch(volcanicEventProvider);
      final all = await ref.watch(allEvacuationCentersProvider.future);
      final ranked = [
        for (final c in all)
          if (c.hasCoordinates && isSafeCenter(c, volcanic: volcanic))
            c.copyWithDistance(
              DistanceCalculator.metersBetween(
                lat1: position.latitude,
                lon1: position.longitude,
                lat2: c.latitude!,
                lon2: c.longitude!,
              ),
            ),
      ]..sort((a, b) => a.distanceMeters!.compareTo(b.distanceMeters!));
      return ranked.take(3).toList();
    });

/// The large banner when the resident's barangay is under a Preemptive
/// or Forced evacuation order.
class EvacuationOrderBanner extends ConsumerWidget {
  const EvacuationOrderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(residentAreaProvider).value;
    final status = area?.status?.status;
    if (status != BarangayStatusKey.preemptiveEvacuation &&
        status != BarangayStatusKey.forcedEvacuation) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final forced = status == BarangayStatusKey.forcedEvacuation;
    final color = forced ? const Color(0xFFB91C1C) : const Color(0xFFC2410C);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        liveRegion: true,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.campaign, color: Colors.white, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        forced
                            ? l10n.orderForcedTitle(area!.name)
                            : l10n.orderPreemptiveTitle(area!.name),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  forced ? l10n.orderForcedBody : l10n.orderPreemptiveBody,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => context.push('/nearest-center'),
                  icon: const Icon(Icons.directions_walk),
                  label: Text(l10n.orderGoToCenter),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Home: the three nearest safe centers, with "est." and Directions.
class SafeCentersCard extends ConsumerWidget {
  const SafeCentersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final position = ref.watch(residentPositionProvider).value;
    // No location yet (or refused): the nearest-center card says how to
    // turn it on.
    if (position is! Success<LatLng>) return const NearestCenterPreview();
    final centers = ref.watch(safeNearestCentersProvider(position.value));
    final volcanic = ref.watch(volcanicEventProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.safeCentersTitle, style: theme.textTheme.titleMedium),
              Text(
                volcanic ? l10n.safeCentersHintVolcanic : l10n.safeCentersHint,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ...centers.when(
                loading: () => [const LinearProgressIndicator()],
                error: (_, _) => [Text(l10n.couldNotLoadNearbyCenters)],
                data: (list) => list.isEmpty
                    ? [Text(l10n.noNearbyEvacuationCenters)]
                    : [
                        for (final c in list)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            minTileHeight: 64,
                            onTap: () => context.push('/centers/${c.id}'),
                            title: Text(c.name),
                            subtitle: Text(
                              [
                                formatDistance(context, c.distanceMeters!),
                                localizedCenterStatus(context, c.status),
                                centerCapacityFigure(
                                  l10n,
                                  c,
                                  resident: true,
                                  withOccupancy: c.currentOccupancy != null,
                                ),
                              ].join(' · '),
                            ),
                            trailing: IconButton.filledTonal(
                              tooltip: l10n.getDirections,
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              onPressed: () => openCenterDirections(context, c),
                              icon: const Icon(Icons.directions_outlined),
                            ),
                          ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where the resident's barangay stands against Mayon's zones.
enum MayonZone { permanent, extended, near, outside }

/// The zone worked out on the phone (offline fallback only).
MayonZone mayonZoneOf(double nearestKm) => nearestKm <= Mayon.permanentKm
    ? MayonZone.permanent
    : nearestKm <= Mayon.extendedKm
    ? MayonZone.extended
    : nearestKm <= Mayon.extendedKm + Mayon.bufferKm
    ? MayonZone.near
    : MayonZone.outside;

/// "12" for 11.7, "less than 1" style "<1" for 0.4 (never "0" for some).
String floodPercentText(double pct) =>
    pct > 0 && pct < 1 ? '<1' : pct.round().toString();

/// "3" for 3.0, "2.5" for 2.5.
String formatKm(double km) =>
    km == km.roundToDouble() ? km.toInt().toString() : km.toStringAsFixed(1);

final _ownOutlineProvider = FutureProvider.autoDispose<BarangayOutline?>((
  ref,
) async {
  final area = await ref.watch(residentAreaProvider.future);
  if (area == null) return null;
  final outlines = await ref.watch(barangayOutlinesProvider.future);
  return outlines.where((o) => o.psgcCode == area.psgcCode).firstOrNull;
});

/// Hazards for the resident's barangay: Mayon (inside the permanent or
/// extended zone, or its distance from the summit, from the bundled
/// boundaries and the documented zones), and short "what to do" for a
/// typhoon, a flood and the volcano. Flood figures per barangay are not
/// in the public API yet.
class HazardsCard extends ConsumerWidget {
  const HazardsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final area = ref.watch(residentAreaProvider).value;
    final flood = area?.status?.flood;
    // The server's zone (apps-api-2026-11-24.md 6); worked out on the
    // phone only when there is none (offline before the first answer).
    final server = area?.status?.mayon;
    final outline = server != null
        ? null
        : ref.watch(_ownOutlineProvider).value;
    final localKm = outline == null ? null : Mayon.nearestKm(outline);
    final MayonZone? zone;
    final double? km;
    if (server != null) {
      km = server.nearestKm;
      zone = switch (server.zone) {
        'inside_6km' => MayonZone.permanent,
        'inside_7km' => MayonZone.extended,
        'near' => MayonZone.near,
        _ => MayonZone.outside,
      };
    } else {
      km = localKm;
      zone = localKm == null ? null : mayonZoneOf(localKm);
    }
    final buffer = area?.board?.mayonBufferKm ?? Mayon.bufferKm;
    final semantic = theme.extension<AppSemanticColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        onTap: () => context.push('/prepare'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              area == null
                  ? l10n.hazardsTitle
                  : l10n.hazardsTitleFor(area.name),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (flood != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.water_outlined,
                    color: flood.veryHighPct > 0
                        ? theme.colorScheme.error
                        : flood.highPct > 0
                        ? semantic.warning
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      flood.highOrVeryHighPct <= 0
                          ? l10n.floodNone
                          : l10n.floodShare(
                              floodPercentText(flood.highOrVeryHighPct),
                            ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              Text(l10n.floodSourceNote, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
            ],
            if (zone != null)
              Row(
                children: [
                  Icon(
                    Icons.volcano_outlined,
                    color: switch (zone) {
                      MayonZone.outside => theme.colorScheme.primary,
                      MayonZone.near => semantic.warning,
                      _ => theme.colorScheme.error,
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(switch (zone) {
                      MayonZone.permanent => l10n.mayonInsidePermanent,
                      MayonZone.extended => l10n.mayonInsideExtended,
                      MayonZone.near => l10n.mayonNear(formatKm(buffer)),
                      MayonZone.outside =>
                        km == null
                            ? (server?.label ?? '')
                            : l10n.mayonDistance(km.toStringAsFixed(1)),
                    }, style: theme.textTheme.bodyLarge),
                  ),
                ],
              ),
            if (zone != null)
              Text(l10n.mayonZoneLabel, style: theme.textTheme.bodySmall),
            if (zone != null && server == null)
              Text(l10n.hazardsOnPhone, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(l10n.hazardsWhatToDo, style: theme.textTheme.labelLarge),
            Text(l10n.hazardsWhatToDoHint, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
