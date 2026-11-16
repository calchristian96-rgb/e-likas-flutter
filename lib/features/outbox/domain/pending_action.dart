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
  countSubmission;

  static PendingActionKind? fromName(String name) {
    for (final k in values) {
      if (k.name == name) return k;
    }
    return null;
  }

  /// A retry of these can be refused only because the first attempt
  /// already got through (the box was already given, the person already
  /// checked out, the status already set, the same count already sent):
  /// such a refusal means the job is done, not that it needs attention.
  bool get alreadyDoneOnRepeat => switch (this) {
    checkOut ||
    boxHandout ||
    boxHandoutVoid ||
    dispatchConfirm ||
    barangayStatus ||
    countSubmission => true,
    shortfallRequest || centerLocation || facilityRequest => false,
  };
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
