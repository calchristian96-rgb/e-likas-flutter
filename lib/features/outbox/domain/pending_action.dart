/// What a queued field action is. The name is stored, so never rename
/// a value; add new ones at the end.
enum PendingActionKind {
  checkOut,
  boxHandout,
  boxHandoutVoid,
  dispatchConfirm,
  shortfallRequest,
  barangayStatus,
  centerLocation,
  facilityRequest,
  countSubmission,
  // A listed family checked in (families to evacuate): the server
  // replays the first answer for the same client_ref.
  familyCheckIn,
  // Mark a facility request received (the center's barangay).
  facilityReceive;

  static PendingActionKind? fromName(String name) {
    for (final k in values) {
      if (k.name == name) return k;
    }
    return null;
  }

  /// The one refusal that means "this already happened" for this kind:
  /// the HTTP status, the error key it is reported under (null = the
  /// top-level message), and a phrase of the backend's own message.
  /// Taken from the backend code (BoxReliefService, EvacueeController,
  /// GisSituationController, BarangayCountSubmissionController). Null:
  /// no refusal of this kind means it already happened.
  AlreadyHappened? get alreadyHappened => switch (this) {
    // "This family already got its box for Round N."
    boxHandout => const AlreadyHappened(
      422,
      'family_id',
      'already got its box',
    ),
    // "This record was already voided."
    boxHandoutVoid => const AlreadyHappened(422, 'reason', 'already voided'),
    // "This delivery was already confirmed."
    dispatchConfirm => const AlreadyHappened(
      422,
      'confirmed_quantity',
      'already confirmed',
    ),
    // "{Barangay} is already marked "{status}". Add a note ..."
    barangayStatus => const AlreadyHappened(422, 'status', 'is already marked'),
    // "This count is already waiting for CSWD, and nothing has changed ..."
    countSubmission => const AlreadyHappened(
      422,
      null,
      'already waiting for CSWD',
    ),
    // Checked out already: the server answers 404 "This evacuee has no
    // active evacuation record to close out."
    checkOut => const AlreadyHappened(404, null, 'no active evacuation record'),
    shortfallRequest || centerLocation || facilityRequest => null,
    familyCheckIn => null,
    facilityReceive => null,
  };
}

/// A refusal that means the action already happened (see
/// [PendingActionKind.alreadyHappened]).
class AlreadyHappened {
  const AlreadyHappened(this.status, this.errorKey, this.phrase);

  final int status;

  /// The `errors` key the message is under; null for `message` itself.
  final String? errorKey;

  /// Matched case-insensitively inside the backend's message.
  final String phrase;

  bool matches(int? status, Object? body) {
    if (status != this.status || body is! Map) return false;
    final List<Object?> messages;
    if (errorKey == null) {
      messages = [body['message']];
    } else {
      final errors = body['errors'];
      final list = errors is Map ? errors[errorKey] : null;
      messages = list is List ? list : [list];
    }
    final p = phrase.toLowerCase();
    return messages.any((m) => m is String && m.toLowerCase().contains(p));
  }
}

enum PendingActionStatus {
  pending('pending'),
  needsAttention('needs_attention');

  const PendingActionStatus(this.wire);

  final String wire;

  static PendingActionStatus fromWire(String wire) =>
      wire == needsAttention.wire ? needsAttention : pending;
}

/// One queued request (see the `PendingActions` table).
class PendingAction {
  const PendingAction({
    required this.localId,
    required this.kind,
    required this.method,
    required this.path,
    required this.body,
    required this.summary,
    required this.status,
    required this.createdAt,
    this.subjectKey,
    this.attemptCount = 0,
    this.lastErrorMessage,
  });

  final String localId;
  final PendingActionKind kind;

  /// POST | PATCH | PUT
  final String method;

  /// Relative to the API base, e.g. `/box-relief/rounds/3/handouts`.
  final String path;
  final Map<String, dynamic> body;
  final String summary;
  final String? subjectKey;
  final PendingActionStatus status;
  final int attemptCount;
  final String? lastErrorMessage;
  final DateTime createdAt;

  bool get needsAttention => status == PendingActionStatus.needsAttention;
}

/// The result of one sync pass over the queue.
class OutboxRunResult {
  const OutboxRunResult({
    this.sent = 0,
    this.needAttention = 0,
    this.stoppedForAuth = false,
    this.wasOffline = false,
  });

  final int sent;
  final int needAttention;
  final bool stoppedForAuth;
  final bool wasOffline;
}
