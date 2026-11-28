import 'dart:convert';
import 'dart:io';

import 'package:elikas_mobile/features/alerts/domain/entities/alert.dart';
import 'package:elikas_mobile/features/barangay_status/domain/barangay_status.dart';
import 'package:elikas_mobile/features/barangay_status/presentation/resident_area.dart';
import 'package:elikas_mobile/features/evacuation_centers/domain/entities/evacuation_center.dart';
import 'package:elikas_mobile/features/preparedness/preparedness.dart';
import 'package:elikas_mobile/features/resident_safety/resident_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_staff_auth.dart';
import 'package:elikas_mobile/features/alerts/data/models/alert_model.dart';
import 'package:elikas_mobile/features/barangay_status/data/barangay_status_repository.dart';

EvacuationCenter _center(
  int id, {
  required double lat,
  required double lng,
  String status = 'active',
}) => EvacuationCenter(
  id: id,
  name: 'Center $id',
  type: 'school',
  latitude: lat,
  longitude: lng,
  capacityPersons: 100,
  status: status,
);

void main() {
  group('safe centers', () {
    // About 5 km and 6.5 km from the summit, and one far away in Ligao.
    final inPermanent = _center(1, lat: 13.2570, lng: 123.6856 - 0.046);
    final inExtended = _center(2, lat: 13.2570, lng: 123.6856 - 0.060);
    final far = _center(3, lat: 13.2400, lng: 123.5400);

    test('inside 6 km is never safe; 7 km only during a volcanic event', () {
      expect(isSafeCenter(inPermanent, volcanic: false), isFalse);
      expect(isSafeCenter(inExtended, volcanic: false), isTrue);
      expect(isSafeCenter(inExtended, volcanic: true), isFalse);
      expect(isSafeCenter(far, volcanic: true), isTrue);
    });

    test('full and closed centers are never offered', () {
      expect(
        isSafeCenter(
          _center(4, lat: 13.24, lng: 123.54, status: 'full'),
          volcanic: false,
        ),
        isFalse,
      );
      expect(
        isSafeCenter(
          _center(5, lat: 13.24, lng: 123.54, status: 'closed'),
          volcanic: false,
        ),
        isFalse,
      );
      expect(
        isSafeCenter(
          _center(6, lat: 13.24, lng: 123.54, status: 'nearly_full'),
          volcanic: false,
        ),
        isTrue,
      );
    });

    test('Mayon zones by the nearest distance', () {
      expect(mayonZoneOf(5.2), MayonZone.permanent);
      expect(mayonZoneOf(6.8), MayonZone.extended);
      // Offline fallback: "near" within 3 km beyond 7 km.
      expect(mayonZoneOf(8), MayonZone.near);
      expect(mayonZoneOf(12), MayonZone.outside);
    });
  });

  test('alerts for the city and the resident\'s barangay only', () {
    Alert a({int? barangay, String? kind}) => Alert(
      id: 1,
      title: 't',
      message: 'm',
      alertType: 'advisory',
      status: 'sent',
      dateSent: null,
      targetBarangayId: barangay,
      targetKind: kind,
    );
    expect(a(kind: 'city').isFor(13), isTrue);
    expect(a(barangay: 13).isFor(13), isTrue);
    expect(a(barangay: 49).isFor(13), isFalse);
    // Unknown barangay (no location): every alert.
    expect(a(barangay: 49).isFor(null), isTrue);
  });

  test('public alerts: target_barangay is parsed (city when null)', () {
    Map<String, dynamic> row(Object? target) => {
      'id': 1,
      'title': 'Typhoon signal no. 2',
      'message': 'Prepare.',
      'alert_type': 'typhoon',
      'severity': 'advisory',
      'status': 'sent',
      'date_sent': '2026-11-23T16:30:22.000000Z',
      'target_barangay': target,
    };
    final one = AlertModel.fromJson(row({'id': 52, 'name': 'Tuburan'}));
    expect(one.targetBarangayId, 52);
    expect(one.toEntity().isFor(52), isTrue);
    expect(one.toEntity().isFor(13), isFalse);
    final city = AlertModel.fromJson(row(null));
    expect(city.targetBarangayId, isNull);
    expect(city.toEntity().isFor(13), isTrue);
  });

  test(
    'the preparedness file: every list names its agency, all 3 languages',
    () {
      final data =
          jsonDecode(File('assets/data/preparedness.json').readAsStringSync())
              as Map<String, dynamic>;
      final p = Preparedness.fromJson(data);
      expect(p.checklists.map((c) => c.id), contains('go_bag'));
      for (final c in p.checklists) {
        expect(['NDRRMC', 'DSWD', 'PHIVOLCS'], contains(c.source));
        for (final i in c.items) {
          for (final lang in ['en', 'fil', 'bcl']) {
            expect(i.text.values[lang], isNotEmpty, reason: '${c.id}/${i.id}');
          }
        }
      }
      expect(p.whatToDo.map((w) => w.id), ['typhoon', 'flood', 'volcano']);
      expect(p.reviewStatus.of('en'), contains('team review'));
    },
  );

  test('the family plan stays on the phone (SharedPreferences only)', () async {
    SharedPreferences.setMockInitialValues({});
    await FamilyPlanStore.save(
      const FamilyPlan(
        meetingPoint: 'Chapel by the school',
        contacts: [(name: 'Tita Rosa', number: '0917 000 0000')],
        specialNeeds: [(name: 'Lolo Ben', need: 'Wheelchair')],
      ),
    );
    final back = await FamilyPlanStore.load();
    expect(back.meetingPoint, 'Chapel by the school');
    expect(back.contacts.single.number, '0917 000 0000');
    expect(back.specialNeeds.single.need, 'Wheelchair');
  });

  testWidgets('a forced evacuation order: the large banner', (tester) async {
    await tester.pumpWidget(
      testApp(
        const Scaffold(body: EvacuationOrderBanner()),
        overrides: [
          residentAreaProvider.overrideWith(
            (ref) async => const ResidentArea(
              name: 'Bay',
              psgcCode: '0505',
              status: BarangayStatus(
                id: 4,
                name: 'Bay',
                status: 'forced_evacuation',
                label: 'Forced evacuation',
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FORCED EVACUATION: BAY'), findsOneWidget);
    expect(find.text('NEAREST OPEN CENTERS'), findsOneWidget);
  });

  test('barangay-status: flood and Mayon per barangay are parsed', () {
    final board = BarangayStatusRepository.parse({
      'evacuation_event': {'name': 'Typhoon Ofel', 'status': 'monitoring'},
      'city_push_topic': 'elikas-city',
      'mayon_zones': {
        'permanent_km': 6,
        'extended_km': 7,
        'buffer_km': 3,
        'label': 'Approximate zone based on distance from the summit.',
      },
      'barangays': [
        {
          'id': 33,
          'name': 'Nabonton',
          'status': 'normal',
          'label': 'Normal',
          'flood': {
            'very_high_pct': 0,
            'high_pct': 13.99,
            'high_or_very_high_pct': 14,
          },
          'mayon': {
            'zone': 'near',
            'label': 'Near (within 3 km of the 7 km zone)',
            'nearest_km': 8,
            'to_extended_km': 1,
            'pct_permanent': 0,
            'pct_extended': 0,
          },
        },
        {
          'id': 60,
          'name': 'No figures',
          'status': 'normal',
          'label': 'Normal',
          'flood': null,
          'mayon': null,
        },
      ],
    });
    expect(board.mayonBufferKm, 3);
    final n = board.byId(33)!;
    expect(n.flood!.highOrVeryHighPct, 14);
    expect(n.mayon!.zone, 'near');
    expect(n.mayon!.nearestKm, 8);
    expect(board.byId(60)!.flood, isNull);
    expect(board.byId(60)!.mayon, isNull);
    expect(floodPercentText(11.7), '12');
    expect(floodPercentText(0.4), '<1');
  });

  testWidgets('hazards: the server\'s flood share and Mayon zone', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        const Scaffold(body: SingleChildScrollView(child: HazardsCard())),
        overrides: [
          residentAreaProvider.overrideWith(
            (ref) async => const ResidentArea(
              name: 'Tuburan',
              psgcCode: '050508053',
              status: BarangayStatus(
                id: 52,
                name: 'Tuburan',
                status: 'normal',
                label: 'Normal',
                flood: BarangayFlood(
                  veryHighPct: 6.16,
                  highPct: 5.57,
                  highOrVeryHighPct: 11.7,
                ),
                mayon: BarangayMayon(
                  zone: 'outside',
                  label: '13.4 km from the summit',
                  nearestKm: 13.4,
                  toExtendedKm: 6.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Flood: 12% of your barangay has high or very high flood '
        'susceptibility.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Mayon: your barangay is 13.4 km from the summit, outside the '
        'danger zones.',
      ),
      findsOneWidget,
    );
    // From the server: no "worked out on this phone" note.
    expect(find.textContaining('Worked out on this phone'), findsNothing);
  });

  testWidgets('no order: no banner', (tester) async {
    await tester.pumpWidget(
      testApp(
        const Scaffold(body: EvacuationOrderBanner()),
        overrides: [
          residentAreaProvider.overrideWith(
            (ref) async => const ResidentArea(
              name: 'Bay',
              psgcCode: '0505',
              status: BarangayStatus(
                id: 4,
                name: 'Bay',
                status: 'watch',
                label: 'Watch',
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Material), findsWidgets);
    expect(find.textContaining('evacuation:'), findsNothing);
  });
}
