import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/api_endpoints.dart';
import '../debug/connectivity_debug_log.dart';
import '../env/env.dart';

part 'connectivity_service.g.dart';

/// The single authoritative online/offline signal for the whole app —
/// every repository's network-first logic, the Staff Center Management
/// online-only guard, Sync Now, and the Home/Settings connectivity
/// display all watch this same service (via [connectivityServiceProvider]
/// / [connectivityStatusProvider]), never a second, independent
/// connectivity check.
///
/// **Why this exists in this exact shape:** a real-device bug showed
/// the app reporting "Online" with Wi-Fi and mobile data both
/// disabled. The previous implementation only asked `connectivity_plus`
/// whether a network *interface* was present — which is real, useful
/// information, but not proof the E-LIKAS backend (or the internet at
/// all) is actually reachable; connectivity_plus's own documentation is
/// explicit that a Wi-Fi connection can report "connected" while
/// sitting behind a captive portal or a router with no upstream
/// internet. [hasConnection] and [onConnectivityChanged] now both
/// require BOTH: a real network interface AND a successful lightweight
/// probe against the actual E-LIKAS API — never a third-party host —
/// before reporting true.
class ConnectivityService {
  ConnectivityService() {
    _interfaceSubscription = Connectivity().onConnectivityChanged.listen(
      _onInterfaceChanged,
    );
    // Establishes a real value immediately rather than leaving the
    // first `onConnectivityChanged` listener with nothing until the
    // next interface-change event happens to fire.
    unawaited(_checkAndBroadcast(bypassCache: true));
  }

  static const _probeTimeout = Duration(seconds: 3);

  /// How long a successful-or-failed reachability probe's result is
  /// reused before the next [hasConnection] call triggers a fresh one
  /// — short enough to notice a real change quickly, long enough that
  /// several repositories asking within the same moment (e.g. Home
  /// loading alerts/centers/map together) share one probe instead of
  /// each firing their own.
  static const _resultCacheTtl = Duration(seconds: 5);

  /// Android can emit several rapid connectivity transitions for one
  /// real change (e.g. wifi→none→mobile while switching networks) —
  /// this waits for things to settle before probing, rather than firing
  /// one probe per intermediate blip.
  static const _interfaceChangeDebounce = Duration(milliseconds: 600);

  final Dio _probeDio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: _probeTimeout,
      receiveTimeout: _probeTimeout,
    ),
  );

  StreamSubscription<List<ConnectivityResult>>? _interfaceSubscription;
  Timer? _debounceTimer;

  bool? _cachedResult;
  DateTime? _cachedAt;
  Future<bool>? _inFlightProbe;

  /// Bumped on every [_checkAndBroadcast] call; a check only broadcasts
  /// its result if it's still the most recently *started* one by the
  /// time it finishes — protects against a slow, now-stale probe
  /// overwriting a newer, faster one's result (Online→Offline→Online
  /// flicker from out-of-order completion, not just out-of-order
  /// starts).
  int _generation = 0;

  final _stateController = StreamController<bool>.broadcast();

  /// Real backend reachability — not just "a network interface exists".
  /// Every repository's existing "try network, fall back to cache" logic
  /// calls this exactly as before; only what it actually verifies
  /// changed.
  Future<bool> get hasConnection async {
    final hasInterface = await _hasNetworkInterface();
    if (!hasInterface) return false;
    return _reachableCachedOrProbe();
  }

  /// The authoritative state as a stream, for UI/reactive consumers
  /// (Home's connectivity display, Settings' Online/Offline row, and
  /// `AppShell`'s offline→online refresh trigger) — unchanged shape
  /// from before this fix, so no consumer needed to change how it
  /// watches this.
  Stream<bool> get onConnectivityChanged => _stateController.stream;

  /// Forces a fresh, uncached reachability check and pushes the result
  /// to [onConnectivityChanged] — called on app resume, since the
  /// cached result may be several minutes stale by the time a resident
  /// returns to a backgrounded app, and a real interface-change event
  /// may never have fired while the app wasn't watching for it.
  Future<void> refreshNow() async {
    connectivityDebugLog('app resumed — forcing fresh reachability check');
    await _checkAndBroadcast(bypassCache: true);
  }

  Future<bool> _hasNetworkInterface() async {
    final results = await Connectivity().checkConnectivity();
    final hasAny = results.any((r) => r != ConnectivityResult.none);
    connectivityDebugLog('interfaces=$results hasInterface=$hasAny');
    return hasAny;
  }

  void _onInterfaceChanged(List<ConnectivityResult> results) {
    connectivityDebugLog('raw interface change event=$results');
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_interfaceChangeDebounce, () {
      unawaited(_checkAndBroadcast(bypassCache: true));
    });
  }

  Future<void> _checkAndBroadcast({required bool bypassCache}) async {
    final generation = ++_generation;
    final hasInterface = await _hasNetworkInterface();

    final bool result;
    if (!hasInterface) {
      result = false;
    } else if (bypassCache) {
      result = await _probeBackend();
    } else {
      result = await _reachableCachedOrProbe();
    }

    if (generation != _generation) {
      connectivityDebugLog(
        'discarding stale probe result (generation=$generation, '
        'current=$_generation)',
      );
      return;
    }

    final previous = _cachedResult;
    _updateCache(result);
    if (previous != result) {
      connectivityDebugLog(
        'state changed ${previous == null ? 'unknown' : (previous ? 'online' : 'offline')}'
        '→${result ? 'online' : 'offline'}',
      );
    }
    _stateController.add(result);
  }

  Future<bool> _reachableCachedOrProbe() async {
    final cachedAt = _cachedAt;
    final cached = _cachedResult;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _resultCacheTtl) {
      return cached;
    }

    final inFlight = _inFlightProbe;
    if (inFlight != null) return inFlight;

    final probe = _probeBackend();
    _inFlightProbe = probe;
    try {
      final result = await probe;
      _updateCache(result);
      return result;
    } finally {
      _inFlightProbe = null;
    }
  }

  void _updateCache(bool result) {
    _cachedResult = result;
    _cachedAt = DateTime.now();
  }

  /// A single lightweight, unauthenticated GET against the real
  /// E-LIKAS public API — deliberately never a third-party host
  /// (google.com, 1.1.1.1, etc.), and deliberately never carrying a
  /// Sanctum token or any staff/PII header even when a staff session
  /// exists, since this same probe is shared by every feature
  /// (resident and staff alike).
  Future<bool> _probeBackend() async {
    connectivityDebugLog('backend probe started');
    try {
      final response = await _probeDio.get(
        ApiEndpoints.alerts,
        queryParameters: const {'per_page': 1},
      );
      final statusCode = response.statusCode ?? 0;
      // A reachable backend answering with a client/server-side error
      // still proves the network path and the host itself are up —
      // only a transport-level failure (caught below) means "offline".
      final online = statusCode > 0;
      connectivityDebugLog(
        'backend probe result=${online ? 'online' : 'offline'} '
        'status=$statusCode',
      );
      return online;
    } catch (error) {
      connectivityDebugLog(
        'backend probe result=offline reason=${error.runtimeType}',
      );
      return false;
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    unawaited(_interfaceSubscription?.cancel());
    unawaited(_stateController.close());
  }
}

@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
}
