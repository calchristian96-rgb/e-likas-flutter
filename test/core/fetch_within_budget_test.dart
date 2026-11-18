import 'dart:async';

import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/error/friendly_error.dart';
import 'package:elikas_mobile/core/network/fetch_within_budget.dart';
import 'package:elikas_mobile/features/evacuation_centers/data/repositories/evacuation_centers_repository_impl.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EvacuationCenter _c(int id, double lat, String status) => EvacuationCenter(
  id: id,
  name: 'C$id',
  type: 'school',
  latitude: lat,
  longitude: 123.5,
  capacityPersons: 100,
  status: status,
);

void main() {
  const budget = Duration(milliseconds: 50);

  test(
    'a slow server: the saved copy at once, the fetch keeps saving',
    () async {
      var saved = false;
      final slow = Completer<String>();
      final result = await fetchWithinBudget(
        () => slow.future.then((v) {
          saved = true;
          return v;
        }),
        hasSaved: true,
        budget: budget,
      );
      // Gave up waiting: the caller shows the saved copy.
      expect(result, isNull);
      slow.complete('fresh');
      await Future<void>.delayed(Duration.zero);
      // ...and the fetch still finished and saved for next time.
      expect(saved, isTrue);
    },
  );

  test('a fast server, or nothing saved yet: the fresh answer', () async {
    expect(
      await fetchWithinBudget(() async => 'fresh', hasSaved: true),
      'fresh',
    );
    // Nothing saved: it waits past the budget for the server.
    final slow = Future<String>.delayed(
      const Duration(milliseconds: 120),
      () => 'fresh',
    );
    expect(
      await fetchWithinBudget(() => slow, hasSaved: false, budget: budget),
      'fresh',
    );
  });

  test('nearest centers: open or standby, with a location, nearest first', () {
    final ranked = rankNearestCenters(
      [
        _c(1, 13.30, 'active'),
        _c(2, 13.21, 'on_standby'),
        _c(3, 13.20, 'full'),
        _c(4, 13.20, 'closed'),
      ],
      latitude: 13.2,
      longitude: 123.5,
    );
    expect(ranked.map((c) => c.id), [2, 1]);
    expect(ranked.first.distanceMeters, greaterThan(0));
  });

  test('a resident never reads the technical error', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(
      friendlyLoadError(l10n, l10n.couldNotLoadAlerts, Exception('x')),
      'Could not load alerts',
    );
    expect(
      friendlyLoadError(
        l10n,
        l10n.couldNotLoadAlerts,
        const NetworkFailure('No alerts available offline yet.'),
      ),
      'Could not load alerts. Nothing is saved on this phone yet: '
      'connect once to save it for offline use.',
    );
  });
}
