import 'package:elikas_mobile/core/cache/staff_read_cache.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/staff_shell/current_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';
import '../../helpers/home_fixtures.dart';

Map<String, dynamic> _row(
  int id,
  String name,
  String status, {
  bool demo = false,
}) => {'id': id, 'name': name, 'status': status, 'is_demo': demo};

/// GET /selected-event (backend 008da71): two open events, one closed.
final _state = {
  'selected': _row(79, 'DEMO - Typhoon Drill', 'active', demo: true),
  'chosen': false,
  'open_count': 2,
  'open_events': [
    _row(79, 'DEMO - Typhoon Drill', 'active', demo: true),
    _row(80, 'Typhoon Rolly', 'monitoring'),
  ],
  'closed_events': [_row(60, 'Typhoon Kristine', 'closed')],
};

void main() {
  test('the selected event, the open ones and the closed ones', () {
    final s = SelectedEventState.fromJson(_state);
    expect(s.selected?.id, 79);
    expect(s.selected?.isDemo, isTrue);
    expect(s.chosen, isFalse);
    expect(s.open.map((e) => e.id), [79, 80]);
    expect(s.closed.single.isOpen, isFalse);
  });

  test(
    'never read yet: the same pick as the server, real before demo',
    () async {
      final container = ProviderContainer(
        overrides: [
          staffReadCacheProvider.overrideWithValue(FakeReadCache({})),
          evacuationEventsLookupProvider.overrideWith(
            (ref) async => const [
              EvacuationEventLookup(
                id: 79,
                name: 'DEMO',
                status: 'active',
                isDemo: true,
              ),
              EvacuationEventLookup(
                id: 80,
                name: 'Rolly',
                status: 'monitoring',
              ),
              EvacuationEventLookup(id: 60, name: 'Kristine', status: 'closed'),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);
      final event = await container.read(currentStaffEventProvider.future);
      expect(event?.id, 80);
    },
  );

  testWidgets('Change lists open and closed events and saves the choice', (
    tester,
  ) async {
    final api = FakeStaffApi();
    await tester.pumpWidget(
      testApp(
        const Scaffold(body: StaffEventBar()),
        overrides: [
          ...signedInAs(official),
          staffReadCacheProvider.overrideWithValue(
            FakeReadCache({'/selected-event': _state}),
          ),
          staffApiClientProvider.overrideWithValue(api),
          connectivityServiceProvider.overrideWithValue(
            ConnectivityService.forTesting(
              hasInterface: () async => true,
              probe: () async => true,
            ),
          ),
          evacuationEventsLookupProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Event: DEMO - Typhoon Drill'), findsOneWidget);

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.text('Open events'), findsOneWidget);
    expect(find.text('Closed events (read-only)'), findsOneWidget);
    expect(find.text('Typhoon Kristine'), findsOneWidget);

    await tester.tap(find.text('Typhoon Rolly'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('PUT /selected-event'));
    expect(api.bodies.last, {'evacuation_event_id': 80});
    expect(find.text('Now working on "Typhoon Rolly".'), findsOneWidget);
  });
}
