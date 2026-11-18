import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/error/result.dart';
import '../../../core/location/location_service.dart';
import '../../../core/utils/data_freshness_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../data/barangay_outlines.dart';
import '../domain/barangay_status.dart';
import 'barangay_status_card.dart' show barangayStatusColor, whatToDo;
import 'barangay_status_providers.dart';

/// The phone's position, asked once and shared by Home's cards (the
/// area and the nearest center). Invalidate it to ask again.
final residentPositionProvider = FutureProvider<Result<LatLng>>((ref) async {
  final result = await ref.watch(locationServiceProvider).getCurrentPosition();
  return switch (result) {
    Success(:final value) => Success(LatLng(value.latitude, value.longitude)),
    Failed(:final failure) => Failed(failure),
  };
});

/// Whether [point] is inside [ring] (ray casting; the ring's own order).
bool _inRing(LatLng point, List<LatLng> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i];
    final b = ring[j];
    if ((a.latitude > point.latitude) != (b.latitude > point.latitude) &&
        point.longitude <
            (b.longitude - a.longitude) *
                    (point.latitude - a.latitude) /
                    (b.latitude - a.latitude) +
                a.longitude) {
      inside = !inside;
    }
  }
  return inside;
}

/// The barangay whose outline holds [point] (inside the outer ring, not
/// in a hole), or null outside Ligao.
BarangayOutline? barangayAt(List<BarangayOutline> outlines, LatLng point) {
  for (final o in outlines) {
    if (o.rings.isEmpty || !_inRing(point, o.rings.first)) continue;
    if (o.rings.skip(1).any((hole) => _inRing(point, hole))) continue;
    return o;
  }
  return null;
}

/// Where the resident is now: the barangay from the phone's location and
/// the bundled boundaries (no account, nothing to choose), with its
/// status in the open event.
class ResidentArea {
  const ResidentArea({
    required this.name,
    required this.psgcCode,
    this.status,
    this.board,
  });

  final String name;
  final String psgcCode;

  /// Null until the status board has been read once.
  final BarangayStatus? status;
  final BarangayStatusBoard? board;

  /// The barangay's id on the server, when the board matched it.
  int? get id => status?.id;
}

/// "Binatagan (Pob.)" in the boundaries file is "Binatagan" on the
/// server: compared without the bracketed part, case-insensitively.
bool _sameName(String a, String b) {
  String plain(String s) =>
      s.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim().toLowerCase();
  return plain(a) == plain(b);
}

/// Null without a location, or outside Ligao.
final residentAreaProvider = FutureProvider<ResidentArea?>((ref) async {
  final position = await ref.watch(residentPositionProvider.future);
  if (position is! Success<LatLng>) return null;
  final outlines = await ref.watch(barangayOutlinesProvider.future);
  final outline = barangayAt(outlines, position.value);
  if (outline == null) return null;
  BarangayStatusBoard? board;
  try {
    board = await ref.watch(barangayStatusBoardProvider.future);
  } catch (_) {
    // Offline with nothing saved yet: the area is still known.
  }
  BarangayStatus? status;
  for (final b in board?.barangays ?? const <BarangayStatus>[]) {
    if (b.psgcCode == outline.psgcCode ||
        (b.psgcCode == null && _sameName(b.name, outline.name))) {
      status = b;
      break;
    }
  }
  return ResidentArea(
    // The server's name ("Binatagan"), not the file's "Binatagan (Pob.)".
    name: status?.name ?? outline.name,
    psgcCode: outline.psgcCode,
    status: status,
    board: board,
  );
});

/// Home's "Your area" card: the barangay the phone is in, its status in
/// words with its colour, and what to do now. Hidden without a location
/// (the nearest center card says how to turn it on). Opens the map,
/// where every barangay's status is shown.
class YourAreaCard extends ConsumerWidget {
  const YourAreaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(residentAreaProvider).value;
    if (area == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = area.status;
    final board = area.board;
    final key = status?.status ?? BarangayStatusKey.normal;
    final color = barangayStatusColor(context, key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/map'),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l10n.yourAreaTitle(area.name),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (status == null)
                          Text(
                            l10n.yourAreaStatusUnavailable,
                            style: theme.textTheme.bodyLarge,
                          )
                        else ...[
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  status.label,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // What to do now, in plain words.
                          Text(
                            whatToDo(l10n, status.status),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                        if (board != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            board.hasOpenEvent
                                ? board.eventName!
                                : l10n.residentNoOpenEvent,
                            style: theme.textTheme.bodySmall,
                          ),
                          if (board.isFromCache)
                            Text(
                              l10n.residentStatusSavedCopy(
                                board.lastSyncedAt == null
                                    ? ''
                                    : formatElapsedSince(board.lastSyncedAt!),
                              ),
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
