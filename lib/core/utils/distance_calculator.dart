import 'dart:math' as math;

/// Straight-line (haversine) distance between two coordinates, in
/// meters. Used to rank cached evacuation centers by distance when the
/// device is offline and the server's `/nearest` endpoint — with its
/// own server-computed `distance_meters` — isn't reachable. Same UX,
/// computed client-side against data already cached from
/// `/public/evacuation-centers`, with no new endpoint involved.
class DistanceCalculator {
  DistanceCalculator._();

  static const double _earthRadiusMeters = 6371000;

  static double metersBetween({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _radians(lat2 - lat1);
    final dLon = _radians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  static double _radians(double degrees) => degrees * (math.pi / 180);
}
