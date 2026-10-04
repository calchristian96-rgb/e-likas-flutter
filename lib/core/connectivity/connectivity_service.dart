import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
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
  ConnectivityService()
    : this._(
        interfaceChanges: Connectivity().onConnectivityChanged,
        resultCacheTtl: _defaultResultCacheTtl,
      );

  /// Swaps the two real checks — "is there a network interface?" and
  /// the backend probe — for fakes, so the state logic can be tested
  /// without the connectivity plugin or a network.
  @visibleForTesting
  ConnectivityService.forTesting({
    required Future<bool> Function() hasInterface,
    required Future<bool> Function() probe,
    Stream<List<ConnectivityResult>> interfaceChanges = const Stream.empty(),
    Duration resultCacheTtl = _defaultResultCacheTtl,
  }) : this._(
         interfaceChanges: interfaceChanges,
         resultCacheTtl: resultCacheTtl,
         interfaceOverride: hasInterface,
         probeOverride: probe,
       );

  ConnectivityService._({
    required Stream<List<ConnectivityResult>> interfaceChanges,
    required Duration resultCacheTtl,
    Future<bool> Function()? interfaceOverride,
    Future<bool> Function()? probeOverride,
  }) : _resultCacheTtl = resultCacheTtl,
       _interfaceOverride = interfaceOverride,
       _probeOverride = probeOverride {
    _interfaceSubscription = interfaceChanges.listen(_onInterfaceChanged);
    // Establishes a real value immediately rather than leaving the
    // first `onConnectivityChanged` listener with nothing until the
    // next interface-change event happens to fire.
    unawaited(_checkAndBroadcast(bypassCache: true));
  }

  final Future<bool> Function()? _interfaceOverride;
  final Future<bool> Function()? _probeOverride;

  static const _probeTimeout = Duration(seconds: 3);

  /// How long a successful-or-failed reachability probe's result is
  /// reused before the next [hasConnection] call triggers a fresh one
  /// — short enough to notice a real change quickly, long enough that
  /// several repositories asking within the same moment (e.g. Home
  /// loading alerts/centers/map together) share one probe instead of
  /// each firing their own.
  static const _defaultResultCacheTtl = Duration(seconds: 5);
  final Duration _resultCacheTtl;

  /// Android can emit several rapid connectivity transitions for one
  /// real change (e.g. wifi→none→mobile while switching networks) —
  /// this waits for things to settle before probing, rather than firing
  /// one probe per intermediate blip.
  static const _interfaceChangeDebounce = Duration(milliseconds: 600);

  // Late: built on the first real probe, never for a test's fake one.
  late final Dio _probeDio = Dio(
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

  /// The last value sent to [onConnectivityChanged] — replayed to every
  /// new listener, and what a passive [hasConnection] check compares
  /// against before correcting the displayed state.
  bool? _lastEmitted;

  /// Consecutive failed probes from [hasConnection] while a network
  /// interface was present — see [_reportPassiveResult].
  int _passiveFailureStreak = 0;

  /// Two failed probes in a row before a passive check turns the
  /// displayed state offline — so one dropped request during normal use
  /// doesn't flicker every status display. Losing the network interface
  /// itself (airplane mode) is definitive and still flips at once.
  static const _passiveOfflineThreshold = 2;

  /// Real backend reachability — not just "a network interface exists".
  /// Every repository's existing "try network, fall back to cache" logic
  /// calls this exactly as before. Its result also corrects
  /// [onConnectivityChanged] when they disagree — otherwise an early
  /// failed probe left every status display (Settings, Home, Sync Now)
  /// stuck on "offline" while data kept
  /// loading live, until the network interface happened to change.
  Future<bool> get hasConnection async {
    final hasInterface = await _hasNetworkInterface();
    if (!hasInterface) {
      _settleNow();
      _reportPassiveResult(false, definitive: true);
      return false;
    }
    final result = await _reachableCachedOrProbe();
    _reportPassiveResult(result, definitive: false);
    return result;
  }

  /// The authoritative state as a stream, for UI/reactive consumers
  /// (Home's connectivity display, Settings' Online/Offline row, and
  /// `AppShell`'s offline→online refresh trigger). A new listener gets
  /// the current state straight away rather than nothing until the next
  /// change — a late subscriber would otherwise read "offline".
  Stream<bool> get onConnectivityChanged => Stream<bool>.multi((listener) {
    final current = _lastEmitted;
    if (current != null) listener.add(current);
    final sub = _stateController.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = sub.cancel;
  });

  void _emit(bool value) {
    _lastEmitted = value;
    _stateController.add(value);
  }

  /// Brings the displayed state in line with a [hasConnection] check.
  /// Online is reported on the first success; offline needs
  /// [_passiveOfflineThreshold] failures in a row unless [definitive]
  /// (no network interface at all).
  void _reportPassiveResult(bool online, {required bool definitive}) {
    if (online) {
      _passiveFailureStreak = 0;
    } else if (!definitive &&
        ++_passiveFailureStreak < _passiveOfflineThreshold) {
      return;
    }
    if (_lastEmitted == online) return;
    connectivityDebugLog(
      'passive check corrected state → ${online ? 'online' : 'offline'}',
    );
    _emit(online);
  }

  /// Forces a fresh, uncached reachability check and pushes the result
  /// to [onConnectivityChanged] if it changed — called on app resume, since the
  /// cached result may be several minutes stale by the time a resident
  /// returns to a backgrounded app, and a real interface-change event
  /// may never have fired while the app wasn't watching for it.
  Future<void> refreshNow() async {
    connectivityDebugLog('app resumed — forcing fresh reachability check');
    await _checkAndBroadcast(bypassCache: true);
  }

  Future<bool> _hasNetworkInterface() async {
    final override = _interfaceOverride;
    if (override != null) return override();
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
      _settleNow();
      result = false;
    } else if (bypassCache) {
      final probed = await _orderedProbe();
      if (probed == null) return;
      result = probed;
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

    final previous = _lastEmitted;
    _updateCache(result);
    if (result) _passiveFailureStreak = 0;
    // Only a real change is pushed — an unchanged result would just
    // rebuild every status display for nothing. New listeners still get
    // the current value (see [onConnectivityChanged]).
    if (previous == result) return;
    connectivityDebugLog(
      'state changed ${previous == null ? 'unknown' : (previous ? 'online' : 'offline')}'
      '→${result ? 'online' : 'offline'}',
    );
    _emit(result);
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

    final probe = () async {
      final result = await _orderedProbe();
      // Stale: a newer check already answered — that answer is current.
      if (result == null) return _cachedResult ?? false;
      _updateCache(result);
      return result;
    }();
    _inFlightProbe = probe;
    try {
      return await probe;
    } finally {
      _inFlightProbe = null;
    }
  }

  /// Order of probes by when they STARTED. [_orderedProbe] numbers each
  /// probe on the way in and drops a result that arrives after a
  /// newer-started one has already settled — otherwise a slow probe
  /// (e.g. a 3s timeout from a full check on app resume) could land
  /// after a newer, faster background check and overwrite its answer
  /// with an out-of-date one. [_generation] only ordered full checks
  /// against each other; this orders every check.
  int _probesStarted = 0;
  int _newestSettled = 0;

  /// One backend probe, or null when a newer check settled first.
  Future<bool?> _orderedProbe() async {
    final ticket = ++_probesStarted;
    final result = await _probeBackend();
    if (ticket < _newestSettled) {
      connectivityDebugLog(
        'discarding out-of-date probe result=${result ? 'online' : 'offline'} '
        '(probe $ticket, newer probe $_newestSettled already answered)',
      );
      return null;
    }
    _newestSettled = ticket;
    return result;
  }

  /// A definitive answer that needed no probe (no network interface at
  /// all) — any probe still in flight is now out of date.
  void _settleNow() => _newestSettled = ++_probesStarted;

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
    final override = _probeOverride;
    if (override != null) return override();
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
