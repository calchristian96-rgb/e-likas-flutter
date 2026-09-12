import 'registered_family.dart';

/// The result of a "load the registered-families cache" call —
/// carries not just the list but *how* it was produced, so the
/// presentation layer can show an honest freshness message instead of
/// a plain list ("Showing data as of ..." vs "Showing saved data" vs
/// nothing fabricated).
class RegisteredFamiliesSnapshot {
  const RegisteredFamiliesSnapshot({
    required this.families,
    required this.isFromCache,
    this.lastSyncedAtEpochMs,
  });

  final List<RegisteredFamily> families;

  /// True when this came from the local cache (either because the
  /// device was offline, or the online fetch failed and cache was used
  /// as a fallback) rather than a just-completed network fetch.
  final bool isFromCache;

  /// Epoch ms of the last time a `GET /families` fetch actually
  /// succeeded for this staff account, or null if that has never
  /// happened on this device. Never fabricated — see
  /// [RegisteredFamiliesRepository] doc comment.
  final int? lastSyncedAtEpochMs;
}
