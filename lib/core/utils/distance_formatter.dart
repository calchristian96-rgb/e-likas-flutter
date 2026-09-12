/// "850 m away" / "1.2 km away" — the single shared formatter for a
/// distance in meters, replacing the two near-identical private copies
/// that previously lived in [EvacuationCenterCard] and
/// [NearestCenterPreview]. Rounds to whole meters under 1km (no
/// decimal places clutter a short distance) and one decimal place in
/// km beyond that — never more precision than a resident glancing at
/// the screen actually needs.
String formatDistanceAway(double meters) {
  if (meters < 1000) return '${meters.round()} m away';
  return '${(meters / 1000).toStringAsFixed(1)} km away';
}
