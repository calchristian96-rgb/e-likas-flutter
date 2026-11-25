import 'pending_action.dart';

/// What a Sent list row is.
enum SentRecordKind {
  /// A family registered with its members (`POST /families/register`).
  registration,

  /// One person added on the EC Board
  /// (`POST /evacuation-centers/{id}/evacuees`).
  ecBoardEntry,

  /// A queued field action (check-out, box handout, ...).
  action,
}

/// One record this phone sent and the server accepted (the `SentRecords`
/// table): kept after its queue row is gone.
class SentRecord {
  const SentRecord({
    required this.localId,
    required this.kind,
    required this.summary,
    required this.sentAt,
    this.actionKind,
    this.memberCount,
    this.place,
    this.eventId,
    this.serverFamilyId,
    this.serverEvacueeId,
    this.serverId,
  });

  final String localId;
  final SentRecordKind kind;

  /// For [SentRecordKind.action]; null when the stored name is unknown.
  final PendingActionKind? actionKind;

  /// The head's name ([SentRecordKind.registration]), the household's
  /// label ([SentRecordKind.ecBoardEntry]) or the action's own summary.
  final String summary;
  final int? memberCount;
  final String? place;
  final int? eventId;
  final int? serverFamilyId;
  final int? serverEvacueeId;
  final int? serverId;
  final DateTime sentAt;

  /// A registration or an EC Board person can be corrected on the server
  /// (`PATCH /evacuees/{id}`, `PATCH /families/{id}/household`); the
  /// queued actions have no edit there and stay read-only.
  bool get canEdit =>
      serverFamilyId != null &&
      (kind == SentRecordKind.registration ||
          kind == SentRecordKind.ecBoardEntry);

  /// The stored kind: `registration`, `ecBoardEntry` or `action:<name>`.
  String get wireKind => switch (kind) {
    SentRecordKind.registration => 'registration',
    SentRecordKind.ecBoardEntry => 'ecBoardEntry',
    SentRecordKind.action => 'action:${actionKind?.name ?? ''}',
  };

  static (SentRecordKind, PendingActionKind?) parseKind(String wire) {
    if (wire == 'registration') return (SentRecordKind.registration, null);
    if (wire == 'ecBoardEntry') return (SentRecordKind.ecBoardEntry, null);
    final name = wire.startsWith('action:') ? wire.substring(7) : wire;
    return (SentRecordKind.action, PendingActionKind.fromName(name));
  }
}
