import 'package:drift/drift.dart';

import '../../../core/database/staff_database.dart';
import '../domain/pending_action.dart';
import '../domain/sent_record.dart';

/// The Sent list: what this phone sent and the server accepted, scoped
/// to the signed-in account. Rows are written by the sync after a 2xx
/// (never before), carry the server's ids from the answer, and are kept
/// for [keepFor], at most [maxRows] per account.
class SentHistoryRepository {
  SentHistoryRepository(
    this._db,
    this._ownerStaffId, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final StaffDatabase _db;
  final int? _ownerStaffId;
  final DateTime Function() _now;

  static const keepFor = Duration(days: 14);
  static const maxRows = 200;

  /// A family registration the server accepted with [familyId].
  Future<void> recordRegistration({
    required String localId,
    required String headName,
    required int memberCount,
    required int familyId,
    int? eventId,
    int? centerId,
    String? barangayName,
  }) async {
    final center = await _centerName(centerId);
    await _record(
      SentRecord(
        localId: localId,
        kind: SentRecordKind.registration,
        summary: headName,
        memberCount: memberCount,
        place: center ?? _blankToNull(barangayName),
        eventId: eventId,
        serverFamilyId: familyId,
        serverId: familyId,
        sentAt: _now(),
      ),
    );
  }

  /// One person added on the EC Board.
  Future<void> recordEcBoardEntry({
    required String localId,
    required String householdLabel,
    required int centerId,
    required int evacueeId,
    required int familyId,
    int? eventId,
  }) async {
    await _record(
      SentRecord(
        localId: localId,
        kind: SentRecordKind.ecBoardEntry,
        summary: householdLabel,
        memberCount: 1,
        place: await _centerName(centerId),
        eventId: eventId,
        serverFamilyId: familyId,
        serverEvacueeId: evacueeId,
        serverId: evacueeId,
        sentAt: _now(),
      ),
    );
  }

  /// A queued action the server accepted; [answer] is its response body
  /// (`{data: {id: ...}}` for most), null when it was found already done.
  Future<void> recordAction(PendingAction action, {Object? answer}) async {
    final data = answer is Map ? answer['data'] : null;
    final id = data is Map ? data['id'] : null;
    await _record(
      SentRecord(
        localId: action.localId,
        kind: SentRecordKind.action,
        actionKind: action.kind,
        summary: action.summary,
        place: await _placeOf(action),
        eventId: action.eventId,
        serverId: id is int ? id : null,
        sentAt: _now(),
      ),
    );
  }

  /// Newest first: the rows of [eventId] and those of no event (a
  /// center's location, for example).
  Future<List<SentRecord>> list({int? eventId}) async {
    final owner = _ownerStaffId;
    if (owner == null) return const [];
    final since = _now().subtract(keepFor).millisecondsSinceEpoch;
    final query = _db.select(_db.sentRecords)
      ..where(
        (t) =>
            t.ownerStaffId.equals(owner) &
            t.sentAtEpochMs.isBiggerOrEqualValue(since) &
            (eventId == null
                ? const Constant(true)
                : t.eventId.equals(eventId) | t.eventId.isNull()),
      )
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.sentAtEpochMs, mode: OrderingMode.desc),
      ])
      ..limit(maxRows);
    return [for (final r in await query.get()) _fromRow(r)];
  }

  Future<void> _record(SentRecord record) async {
    final owner = _ownerStaffId;
    if (owner == null) return;
    await _db
        .into(_db.sentRecords)
        .insertOnConflictUpdate(
          SentRecordsCompanion.insert(
            localId: record.localId,
            kind: record.wireKind,
            summary: record.summary,
            memberCount: Value(record.memberCount),
            place: Value(record.place),
            eventId: Value(record.eventId),
            serverFamilyId: Value(record.serverFamilyId),
            serverEvacueeId: Value(record.serverEvacueeId),
            serverId: Value(record.serverId),
            sentAtEpochMs: record.sentAt.millisecondsSinceEpoch,
            ownerStaffId: owner,
          ),
        );
    await _prune(owner);
  }

  /// Older than [keepFor], or past the newest [maxRows] of the account.
  Future<void> _prune(int owner) async {
    final cutoff = _now().subtract(keepFor).millisecondsSinceEpoch;
    await (_db.delete(
      _db.sentRecords,
    )..where((t) => t.sentAtEpochMs.isSmallerThanValue(cutoff))).go();
    final kept =
        await (_db.selectOnly(_db.sentRecords)
              ..addColumns([_db.sentRecords.localId])
              ..where(_db.sentRecords.ownerStaffId.equals(owner))
              ..orderBy([
                OrderingTerm(
                  expression: _db.sentRecords.sentAtEpochMs,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(maxRows))
            .map((r) => r.read(_db.sentRecords.localId)!)
            .get();
    await (_db.delete(
          _db.sentRecords,
        )..where((t) => t.ownerStaffId.equals(owner) & t.localId.isNotIn(kept)))
        .go();
  }

  SentRecord _fromRow(SentRecordRow r) {
    final (kind, actionKind) = SentRecord.parseKind(r.kind);
    return SentRecord(
      localId: r.localId,
      kind: kind,
      actionKind: actionKind,
      summary: r.summary,
      memberCount: r.memberCount,
      place: r.place,
      eventId: r.eventId,
      serverFamilyId: r.serverFamilyId,
      serverEvacueeId: r.serverEvacueeId,
      serverId: r.serverId,
      sentAt: DateTime.fromMillisecondsSinceEpoch(r.sentAtEpochMs),
    );
  }

  /// The center or barangay an action is about, from its path or body.
  Future<String?> _placeOf(PendingAction action) async {
    final centerInPath = RegExp(
      r'/(?:evacuation-centers|gis/centers)/(\d+)',
    ).firstMatch(action.path);
    final centerId =
        _intOf(action.body['evacuation_center_id']) ??
        _intOf(action.body['to_evacuation_center_id']) ??
        int.tryParse(centerInPath?.group(1) ?? '');
    final center = await _centerName(centerId);
    if (center != null) return center;
    final barangayInPath = RegExp(r'/barangays/(\d+)').firstMatch(action.path);
    return _barangayName(
      _intOf(action.body['barangay_id']) ??
          int.tryParse(barangayInPath?.group(1) ?? ''),
    );
  }

  Future<String?> _centerName(int? id) async {
    if (id == null) return null;
    final row = await (_db.select(
      _db.lookupEvacuationCenters,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.name;
  }

  Future<String?> _barangayName(int? id) async {
    if (id == null) return null;
    final row = await (_db.select(
      _db.lookupBarangays,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.name;
  }

  static int? _intOf(Object? v) => v is int ? v : null;

  static String? _blankToNull(String? s) =>
      s == null || s.trim().isEmpty ? null : s;
}
