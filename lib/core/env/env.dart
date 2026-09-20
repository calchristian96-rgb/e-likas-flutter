import 'backend_override_service.dart';

/// Build-time environment configuration.
///
/// Defaults to the production Hostinger API. Override at build/run time
/// with --dart-define for a one-off local backend session, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1/
/// (10.0.2.2 is the Android emulator's alias for the host machine's
/// localhost, for a `php artisan serve` backend on the same machine;
/// physical devices need the machine's real LAN IP instead.)
///
/// For a persistent override that survives the app running standalone,
/// disconnected from that `flutter run` session entirely (e.g. a real
/// device left with testers), see [BackendOverrideService] instead —
/// [apiBaseUrl] below checks that first.
class Env {
  Env._();

  // The trailing slash is load-bearing: ApiClient/Dio's baseUrl and
  // ApiEndpoints' relative paths (e.g. 'evacuation-centers') are joined
  // by plain string concatenation, not URL-path joining. Without it,
  // "https://e-likasligao.online/api/v1" + "evacuation-centers" becomes
  // the malformed "https://e-likasligao.online/api/v1evacuation-centers"
  // — missing exactly the '/' between "v1" and the path, which is
  // exactly the bug this fixes.
  static const String compiledDefaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://e-likasligao.online/api/v1/',
  );

  /// The base URL every request actually uses: the persistent runtime
  /// override when one is set (debug/profile builds only — see
  /// [BackendOverrideService]), otherwise [compiledDefaultApiBaseUrl].
  static String get apiBaseUrl =>
      BackendOverrideService.overrideUrl ?? compiledDefaultApiBaseUrl;
}
