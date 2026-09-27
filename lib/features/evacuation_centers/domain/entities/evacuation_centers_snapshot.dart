import 'evacuation_center.dart';

/// The full centers list plus where it came from — so a screen can say
/// when it's showing the copy saved on this device instead of a live
/// server response, rather than silently presenting it as current.
class EvacuationCentersSnapshot {
  const EvacuationCentersSnapshot({
    required this.centers,
    required this.isFromCache,
    this.lastSyncedAt,
  });

  final List<EvacuationCenter> centers;

  /// True when the live fetch wasn't possible (offline, or the request
  /// failed) and [centers] is the saved copy.
  final bool isFromCache;

  /// When the saved copy was last refreshed from the server — null if
  /// that was never recorded. Only meaningful with [isFromCache].
  final DateTime? lastSyncedAt;
}
