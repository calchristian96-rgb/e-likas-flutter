/// Relief by the box (backend step 11): figures per round and barangay.
class BoxFigures {
  const BoxFigures({
    this.need = 0,
    this.dispatched = 0,
    this.inTransit = 0,
    this.received = 0,
    this.given = 0,
    this.leftToGive = 0,
    this.short = 0,
    this.canRequest = 0,
    this.requested = 0,
  });

  final int need;
  final int dispatched;
  final int inTransit;

  /// Confirmed by the barangay.
  final int received;
  final int given;
  final int leftToGive;
  final int short;
  final int canRequest;
  final int requested;

  static int _i(Map<String, dynamic> j, String k) =>
      (j[k] as num?)?.toInt() ?? 0;

  factory BoxFigures.fromJson(Map<String, dynamic> j) => BoxFigures(
    need: _i(j, 'need'),
    dispatched: _i(j, 'dispatched'),
    inTransit: _i(j, 'in_transit'),
    received: _i(j, 'received'),
    given: _i(j, 'given'),
    leftToGive: _i(j, 'left_to_give'),
    short: _i(j, 'short'),
    canRequest: _i(j, 'can_request'),
    requested: _i(j, 'requested'),
  );
}

class BoxDispatch {
  const BoxDispatch({
    required this.id,
    required this.quantity,
    required this.voided,
    this.confirmedQuantity,
    this.dispatchedAt,
    this.confirmationNote,
  });

  final int id;
  final int quantity;
  final int? confirmedQuantity;
  final bool voided;
  final DateTime? dispatchedAt;
  final String? confirmationNote;

  /// Sent and not yet confirmed: the barangay counts what arrived.
  bool get waitingForConfirmation => confirmedQuantity == null && !voided;

  factory BoxDispatch.fromJson(Map<String, dynamic> j) => BoxDispatch(
    id: j['id'] as int,
    quantity: (j['quantity'] as num?)?.toInt() ?? 0,
    confirmedQuantity: (j['confirmed_quantity'] as num?)?.toInt(),
    voided: j['voided'] == true,
    dispatchedAt: DateTime.tryParse(
      j['dispatched_at'] as String? ?? '',
    )?.toLocal(),
    confirmationNote: j['confirmation_note'] as String?,
  );
}

class ShortfallRequest {
  const ShortfallRequest({
    required this.id,
    required this.quantity,
    required this.status,
    this.reviewNote,
  });

  final int id;
  final int quantity;

  /// pending | approved | rejected | fulfilled
  final String status;
  final String? reviewNote;

  factory ShortfallRequest.fromJson(Map<String, dynamic> j) => ShortfallRequest(
    id: j['id'] as int,
    quantity: (j['quantity'] as num?)?.toInt() ?? 0,
    status: j['status'] as String? ?? 'pending',
    reviewNote: j['review_note'] as String?,
  );
}

class BoxRound {
  const BoxRound({
    required this.id,
    required this.roundNumber,
    required this.figures,
    required this.dispatches,
    required this.shortfallRequests,
  });

  final int id;
  final int roundNumber;
  final BoxFigures figures;
  final List<BoxDispatch> dispatches;
  final List<ShortfallRequest> shortfallRequests;

  factory BoxRound.fromJson(Map<String, dynamic> j) => BoxRound(
    id: j['id'] as int,
    roundNumber: (j['round_number'] as num?)?.toInt() ?? 0,
    figures: BoxFigures.fromJson(j),
    dispatches: [
      for (final d in j['dispatches'] as List? ?? const [])
        BoxDispatch.fromJson(d as Map<String, dynamic>),
    ],
    shortfallRequests: [
      for (final s in j['shortfall_requests'] as List? ?? const [])
        ShortfallRequest.fromJson(s as Map<String, dynamic>),
    ],
  );
}

/// `GET /box-relief/barangay?evacuation_event_id=`.
class BarangayBoxes {
  const BarangayBoxes({
    required this.need,
    required this.countValidated,
    required this.canAct,
    required this.canRequestShortfall,
    required this.rounds,
    this.barangayName,
    this.needBasis = 'validated',
    this.registeredNow,
    this.validated,
    this.plan,
  });

  final int need;

  /// `validated` or `registered`: until a count is validated the need is
  /// the registered count, and boxes can already go out
  /// (apps-api-2026-11-22.md section 6).
  final String needBasis;
  final int? registeredNow;
  final int? validated;

  /// While the event is monitored: `{forecast, list, round_1_boxes,
  /// round_1_basis}`. Round 1 is one box per family.
  final Map<String, dynamic>? plan;

  bool get needFromRegistered => needBasis == 'registered';
  final bool countValidated;
  final bool canAct;
  final bool canRequestShortfall;
  final String? barangayName;

  /// Oldest first, as the backend sends them.
  final List<BoxRound> rounds;

  BoxRound? get latestRound => rounds.isEmpty ? null : rounds.last;

  factory BarangayBoxes.fromJson(Map<String, dynamic> j) => BarangayBoxes(
    need: (j['need'] as num?)?.toInt() ?? 0,
    countValidated: j['count_validated'] == true,
    needBasis:
        j['need_basis'] as String? ??
        (j['count_validated'] == true ? 'validated' : 'registered'),
    registeredNow: _count(j['registered_now']),
    validated: _count(j['validated']),
    plan: j['plan'] as Map<String, dynamic>?,
    canAct: j['can_act'] == true,
    canRequestShortfall: j['can_request_shortfall'] == true,
    barangayName: (j['barangay'] as Map<String, dynamic>?)?['name'] as String?,
    rounds: [
      for (final r in j['rounds'] as List? ?? const [])
        BoxRound.fromJson(r as Map<String, dynamic>),
    ]..sort((a, b) => a.roundNumber.compareTo(b.roundNumber)),
  );
}

/// A count that may come as a number or as `{families, persons}`: the
/// families.
int? _count(Object? v) => v is num
    ? v.toInt()
    : v is Map
    ? (v['families'] as num?)?.toInt()
    : null;
