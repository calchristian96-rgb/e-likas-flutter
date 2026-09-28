import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';

/// A [ConnectivityService] whose network interface and backend probe are
/// switchable flags, with no result caching — so every [hasConnection]
/// call runs a fresh (fake) probe, like one made after the 5s cache.
class _Harness {
  _Harness({this.reachable = false}) {
    service = ConnectivityService.forTesting(
      hasInterface: () async => interface,
      probe: () async {
        probes++;
        return reachable;
      },
      resultCacheTtl: Duration.zero,
    );
  }

  bool interface = true;
  bool reachable;
  int probes = 0;
  late final ConnectivityService service;

  /// Everything the stream delivers to one listener, from subscribing on.
  Future<List<bool>> listen() async {
    final seen = <bool>[];
    final sub = service.onConnectivityChanged.listen(seen.add);
    addTearDown(sub.cancel);
    await _settle();
    return seen;
  }
}

/// Lets the service's startup check and any stream deliveries finish.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  test('a probe result that differs from the last emitted value is pushed: '
      'offline → online', () async {
    final h = _Harness(reachable: false);
    addTearDown(h.service.dispose);
    final seen = await h.listen();
    expect(seen, [false], reason: 'startup check found the server down');

    // The server comes back while the network interface never changed —
    // the case that used to leave every display stuck on "offline".
    h.reachable = true;
    expect(await h.service.hasConnection, isTrue);
    await _settle();
    expect(seen, [false, true]);
  });

  test('online → offline is pushed after two failed probes in a row, not '
      'one (no flicker from a single dropped request)', () async {
    final h = _Harness(reachable: true);
    addTearDown(h.service.dispose);
    final seen = await h.listen();
    expect(seen, [true]);

    h.reachable = false;
    expect(await h.service.hasConnection, isFalse);
    await _settle();
    expect(seen, [true], reason: 'one failure alone is not reported');

    expect(await h.service.hasConnection, isFalse);
    await _settle();
    expect(seen, [true, false]);
  });

  test('a success between failures resets the count', () async {
    final h = _Harness(reachable: true);
    addTearDown(h.service.dispose);
    final seen = await h.listen();

    h.reachable = false;
    await h.service.hasConnection;
    h.reachable = true;
    await h.service.hasConnection;
    h.reachable = false;
    await h.service.hasConnection;
    await _settle();
    expect(seen, [true], reason: 'never two failures in a row');
  });

  test('losing the network interface is pushed as offline at once', () async {
    final h = _Harness(reachable: true);
    addTearDown(h.service.dispose);
    final seen = await h.listen();

    h.interface = false;
    expect(await h.service.hasConnection, isFalse);
    await _settle();
    expect(seen, [true, false]);
  });

  test('nothing is emitted when the result is unchanged', () async {
    final h = _Harness(reachable: true);
    addTearDown(h.service.dispose);
    final seen = await h.listen();

    for (var i = 0; i < 5; i++) {
      expect(await h.service.hasConnection, isTrue);
    }
    // A forced full check (as on app resume) with the same result too.
    await h.service.refreshNow();
    await _settle();

    expect(h.probes, greaterThan(5), reason: 'the checks really ran');
    expect(seen, [true]);
  });

  test(
    'an older probe finishing late never overwrites a newer result',
    () async {
      // Seen on a real device: on app resume, a full check's probe timed
      // out 3s later — after a background check that started just after it
      // had already found the server up — and flipped the display back to
      // "offline" for a minute. Each probe here is answered by hand.
      final pending = <Completer<bool>>[];
      final service = ConnectivityService.forTesting(
        hasInterface: () async => true,
        probe: () {
          final c = Completer<bool>();
          pending.add(c);
          return c.future;
        },
        resultCacheTtl: Duration.zero,
      );
      addTearDown(service.dispose);
      await _settle();
      pending.removeAt(0).complete(false); // startup check: server down
      await _settle();
      final seen = <bool>[];
      final sub = service.onConnectivityChanged.listen(seen.add);
      addTearDown(sub.cancel);
      await _settle();
      expect(seen, [false]);

      final resume = service.refreshNow(); // full check, probe A (slow)
      await _settle();
      final background = service.hasConnection; // probe B, started after A
      await _settle();
      expect(pending, hasLength(2));

      pending[1].complete(true); // B answers first: the server is back
      expect(await background, isTrue);
      await _settle();
      expect(seen, [false, true]);

      pending[0].complete(false); // A finally times out
      await resume;
      await _settle();
      expect(seen, [false, true], reason: 'A is out of date — ignored');
    },
  );

  test('a new listener gets the current value immediately', () async {
    final h = _Harness(reachable: false);
    addTearDown(h.service.dispose);
    await _settle();
    h.reachable = true;
    await h.service.hasConnection;
    await _settle();

    // Subscribing long after the last change still delivers it straight
    // away, instead of nothing until the next change.
    final late = Completer<bool>();
    final sub = h.service.onConnectivityChanged.listen((v) {
      if (!late.isCompleted) late.complete(v);
    });
    addTearDown(sub.cancel);
    expect(await late.future.timeout(const Duration(seconds: 1)), isTrue);
  });
}
