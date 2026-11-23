import 'package:elikas_mobile/core/cache/staff_read_cache.dart';
import 'package:elikas_mobile/features/count_submissions/final_count_card.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/lookup_entities.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/lookup_providers.dart';
import 'package:elikas_mobile/features/outbox/presentation/outbox_providers.dart';
import 'package:elikas_mobile/features/staff_auth/domain/entities/staff_session.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'fake_staff_auth.dart';
import 'transfer_fixtures.dart';

/// Staff reads answered from [answers] by path (query ignored); any
/// other path fails as if offline with nothing saved.
class FakeReadCache implements StaffReadCache {
  FakeReadCache(this.answers);

  final Map<String, Map<String, dynamic>> answers;

  @override
  Future<CachedRead<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final data = answers[path];
    if (data == null) throw StateError('No answer for $path');
    return CachedRead(
      data: data,
      fetchedAt: DateTime(2026, 11, 17, 9),
      isFromCache: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> roundFamily(
  int id,
  String name, {
  int order = 1,
  String? priority,
  bool given = false,
  bool nextInLine = false,
  int higherPriorityWaiting = 0,
}) => {
  'id': id,
  'name': name,
  'member_count': 3,
  'priority_tier': priority == null ? 9 : 1,
  'priority_label': priority,
  'priority_order': order,
  'given': given,
  'handout_id': given ? id + 100 : null,
  'next_in_line': nextInLine,
  'can_give': !given,
  'higher_priority_waiting': higherPriorityWaiting,
};

/// GET /box-relief/rounds/1/families: 6 received, 1 given, 5 left.
Map<String, dynamic> roundFamilies({int received = 6, int given = 1}) => {
  'round': {'id': 1, 'round_number': 1},
  'barangay': {'id': 13, 'name': 'Binatagan'},
  'figures': {
    'need': 4,
    'received': received,
    'given': given,
    'left_to_give': received - given,
    'short': 0,
  },
  'order': 'priority',
  'puroks': [
    {
      'purok': {'id': 7, 'name': 'Purok 1'},
      'given': 1,
      'families': [
        roundFamily(1, 'Reyes', order: 1, priority: 'Infant', nextInLine: true),
        roundFamily(2, 'Santos', order: 2, priority: 'Senior citizen'),
        roundFamily(3, 'Cruz', order: 3, higherPriorityWaiting: 2),
        roundFamily(4, 'Lopez', order: 4, given: true),
      ],
    },
  ],
};

const _event = {
  'id': 24,
  'name': 'Typhoon Pepito',
  'status': 'active',
  'is_demo': false,
};

Map<String, dynamic> _section(Map<String, dynamic> data) => {
  'evacuation_event': _event,
  'data': data,
};

/// What the barangay official's and CSWDO's homes read, shaped like the
/// backend (main b0ff476).
final homeAnswers = <String, Map<String, dynamic>>{
  '/private-house-families': {
    'evacuation_event': _event,
    'barangays': [
      {
        'barangay': {'id': 13, 'name': 'Binatagan'},
        'families': 2,
        'persons': 7,
      },
    ],
    'families': [
      {
        'id': 3601,
        'label': 'Rosa Santos',
        'member_count': 3,
        'host_name': 'Carmen Reyes',
        'host_address': 'Zone 3, near the chapel',
        'host_purok': {'id': 8, 'name': 'Purok 2'},
        'incomplete': true,
      },
      {
        'id': 3602,
        'label': 'Lito Cruz',
        'member_count': 4,
        'host_name': 'Nena Cruz',
        'host_address': null,
        'host_purok': {'id': 7, 'name': 'Purok 1'},
        'incomplete': false,
      },
    ],
  },
  '/transfer-requests': transferRequestsAnswer,
  // GET /dashboard/barangay (apps-api-2026-11-22.md section 7).
  '/dashboard/barangay': barangayDashboardAnswer,
  '/dashboard/city': {
    'actions': {'transfer_requests_pending': 2, 'count_submissions_pending': 3},
  },
  '/selected-event': {
    'selected': _event,
    'chosen': false,
    'open_count': 1,
    'open_events': [_event],
    'closed_events': [],
  },
  '/monitoring/overview': _section({
    'figures': {
      'persons': 412,
      'families': 118,
      'inside': 380,
      'outside': 32,
      'centers_in_use': 6,
    },
  }),
  '/monitoring/barangays': _section({
    'statuses': [
      {'key': 'normal', 'label': 'Normal'},
      {'key': 'watch', 'label': 'Watch'},
      {'key': 'flooding_reported', 'label': 'Flooding reported'},
      {'key': 'preemptive_evacuation', 'label': 'Preemptive evacuation'},
      {'key': 'forced_evacuation', 'label': 'Forced evacuation'},
    ],
    'counts': {
      'normal': 40,
      'watch': 9,
      'flooding_reported': 3,
      'preemptive_evacuation': 2,
      'forced_evacuation': 1,
    },
  }),
  '/monitoring/centers': _section({
    'centers': [
      {'name': 'Ligao West Central School', 'percent': 95},
      {'name': 'Binatagan Covered Court', 'percent': 40},
    ],
  }),
  '/monitoring/relief': _section({
    'rounds': [
      {
        'barangays': [
          {
            'barangay': {'name': 'Tuburan'},
            'short': 12,
          },
        ],
      },
    ],
  }),
  '/count-submissions/barangays': {
    'barangays': [
      {
        'barangay': {'name': 'Paulba'},
        'current_submission': null,
        'computed': {'families': 14},
      },
      {
        'barangay': {'name': 'Bobonsuran'},
        'current_submission': {'id': 3},
        'computed': {'families': 9},
      },
    ],
  },
  '/notifications': {
    'unread': 2,
    'notifications': [
      {
        'id': 'a1',
        'title': 'Typhoon Pepito is now active',
        'message': 'The first family checked in at Binatagan.',
        'read': false,
        'created_at': '2026-11-17T00:30:00Z',
      },
    ],
  },
  '/gis/situation': {
    'evacuation_event': _event,
    'open': true,
    'statuses': [
      for (final (key, label, rank, order) in const [
        ('normal', 'Normal', 0, false),
        ('watch', 'Watch', 1, false),
        ('flooding_reported', 'Flooding reported', 2, false),
        ('preemptive_evacuation', 'Preemptive evacuation', 3, true),
        ('forced_evacuation', 'Forced evacuation', 4, true),
      ])
        {
          'key': key,
          'label': label,
          'rank': rank,
          'evacuation_order': order,
          'may_set': true,
        },
    ],
    'barangays': [
      {
        'barangay': {'id': 13, 'name': 'Binatagan'},
        'status': 'flooding_reported',
        'label': 'Flooding reported',
        'rank': 2,
        'may_update': true,
      },
      {
        'barangay': {'id': 20, 'name': 'Tuburan'},
        'status': 'watch',
        'label': 'Watch',
        'rank': 1,
        'may_update': true,
      },
    ],
  },
  '/box-relief/barangay': {
    'evacuation_event': _event,
    'barangay': {'id': 13, 'name': 'Binatagan'},
    'can_act': true,
    'need': 4,
    'rounds': [
      {
        'id': 1,
        'round_number': 1,
        'need': 4,
        'dispatched': 6,
        'in_transit': 0,
        'received': 6,
        'given': 1,
        'left_to_give': 5,
        'short': 0,
        'dispatches': [],
        'shortfall_requests': [],
      },
    ],
  },
  '/box-relief/rounds/1/families': roundFamilies(),
  // Binatagan has no official account here: CSWD submits for it.
  '/count-submissions/computed': {
    'evacuation_event': _event,
    'barangay': {'id': 13, 'name': 'Binatagan'},
    'computed': {
      'families': 42,
      'families_inside_ec': 37,
      'families_outside_ec': 5,
      'persons': 150,
      'persons_inside_ec': 132,
      'persons_outside_ec': 18,
    },
    'late_entries': null,
    'checks': {'incomplete_families': 0, 'possible_duplicates': 1},
    'current_submission': null,
    'validated_need': null,
    'has_official_account': false,
  },
  '/gis/barangays/13': {
    'barangay': {'id': 13, 'name': 'Binatagan'},
    'status': {
      'status': 'flooding_reported',
      'label': 'Flooding reported',
      'note': 'Knee-deep at Purok 3.',
    },
    'registered': {'families': 42, 'persons': 150},
    'relief_boxes': {'round_number': 1, 'given': 30, 'short': 4},
    'centers': [
      {
        'name': 'Binatagan Elementary School',
        'status': 'active',
        'capacity_persons': 120,
        'current_occupancy': 48,
      },
      {
        'name': 'Binatagan Covered Court',
        'status': 'full',
        'capacity_persons': 80,
        'current_occupancy': 80,
      },
    ],
  },
};

/// Signed in as [session], one active event, the answers above, and
/// [waiting] actions still to send.
List<Override> homeOverrides(
  StaffSession session, {
  int waiting = 3,
  Map<String, Map<String, dynamic>>? answers,
  List<EvacuationEventLookup>? events,
}) => [
  ...signedInAs(session),
  staffReadCacheProvider.overrideWithValue(
    FakeReadCache(answers ?? homeAnswers),
  ),
  evacuationEventsLookupProvider.overrideWith(
    (ref) async =>
        events ??
        const [
          EvacuationEventLookup(
            id: 24,
            name: 'Typhoon Pepito',
            status: 'active',
          ),
        ],
  ),
  pendingActionsProvider.overrideWith((ref) async => const []),
  syncSummaryProvider.overrideWith(
    (ref) async => SyncSummary(waiting: waiting, needAttention: 0),
  ),
  computedCountProvider.overrideWith((ref) async => null),
];

/// The official's dashboard: plan, list, To do, status.
final barangayDashboardAnswer = <String, dynamic>{
  'evacuation_event': _event,
  'status': {'status': 'watch', 'may_say_arriving': false},
  'plan': {
    // apps-api-2026-11-24.md 7.1.
    'forecast': {
      'families': 1250,
      'persons': 4300,
      'families_low': 40,
      'families_high': 1250,
    },
    'space': {
      'capacity_persons': 3800,
      'estimated': false,
      'centers_without_capacity': 0,
      'forecast_persons': 4300,
      'short': 500,
    },
    'centers_ready': {
      'total': 4,
      'ready': 2,
      'below': 1,
      'no_checklist': 1,
      'no_capacity': 0,
    },
  },
  'list': {'families': 12, 'persons': 47, 'checked_in': 5},
  'todo': [
    {
      'kind': 'center_capacity',
      'text': '3 of your 4 centers have no capacity or only an estimate',
      'detail':
          '1 unknown, 2 estimated. Enter each center\'s capacity on its page.',
      'href': '/evacuation-centers?needs=estimated',
      'action': 'Enter capacity',
      'counts': {'total': 4, 'official': 1, 'estimated': 2, 'unknown': 1},
    },
    {
      'kind': 'supplies_short',
      'center_id': 71,
      'text': 'Binatagan Hall: short of the planning standard',
      'detail': '2 toilets, 2 bathing cubicles for a full center (60 persons).',
      'href': '/facility-requests?request=71',
      'action': 'Request supplies',
    },
  ],
};
