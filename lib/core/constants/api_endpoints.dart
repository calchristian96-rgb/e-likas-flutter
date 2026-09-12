/// Path segments for the E-LIKAS public API, relative to [Env.apiBaseUrl].
///
/// Verified against the real Laravel `routes/api.php`: the resident app's
/// unauthenticated read-only endpoints all live under `public/` —
/// `evacuation-centers`, `alerts`, and `gis/map-data` without that prefix
/// are the *staff* endpoints, gated behind `auth:sanctum` + a role check,
/// which this app must never call since it never authenticates.
class ApiEndpoints {
  ApiEndpoints._();

  static const String evacuationCenters = 'public/evacuation-centers';
  static const String nearestEvacuationCenters =
      'public/evacuation-centers/nearest';
  static const String alerts = 'public/alerts';
  static const String mapData = 'public/gis/map-data';

  /// Single-center detail, including its facilities checklist — added
  /// to `elikas-backend-main (7)`'s `PublicController::evacuationCenter()`.
  /// Verified public (no Sanctum), route-model-bound on the numeric id.
  static String evacuationCenterDetail(int id) =>
      'public/evacuation-centers/$id';
}
