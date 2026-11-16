import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/database/resident_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_timestamps.dart';
import '../domain/barangay_status.dart';

const _eventPrefsKey = 'elikas.barangayStatus.event';

/// `GET /public/gis/barangay-status`, network first, then the copy on
/// this device (resident database), so a resident offline still sees
/// the last known status of their barangay.
class BarangayStatusRepository {
  BarangayStatusRepository(
    this._api,
    this._db,
    this._connectivity,
    this._syncTimestamps,
  );

  final ApiClient _api;
  final ResidentDatabase _db;
  final ConnectivityService _connectivity;
  final SyncTimestampService _syncTimestamps;

  static const path = 'public/gis/barangay-status';

  /// Throws only when there is neither a response nor a saved copy.
  Future<BarangayStatusBoard> getBoard() async {
    if (await _connectivity.hasConnection) {
      try {
        final response = await _api.get(path);
        final data =
            (response.data as Map<String, dynamic>)['data']
                as Map<String, dynamic>;
        final board = parse(data);
        await _save(board);
        await _syncTimestamps.markSynced(SyncDomain.barangayStatus);
        return board;
      } catch (_) {
        // Fall back to the saved copy below.
      }
    }
    return _load();
  }

  static BarangayStatusBoard parse(Map<String, dynamic> data) {
    final event = data['evacuation_event'] as Map<String, dynamic>?;
    return BarangayStatusBoard(
      eventName: event?['name'] as String?,
      eventStatus: event?['status'] as String?,
      isDrill: event?['is_drill'] as bool? ?? false,
      barangays: [
        for (final b in data['barangays'] as List? ?? const [])
          BarangayStatus.fromJson(b as Map<String, dynamic>),
      ],
    );
  }

  Future<void> _save(BarangayStatusBoard board) async {
    await _db.transaction(() async {
      await _db.delete(_db.barangayStatuses).go();
      await _db.batch((batch) {
        batch.insertAll(_db.barangayStatuses, [
          for (final b in board.barangays)
            BarangayStatusesCompanion.insert(
              id: Value(b.id),
              name: b.name,
              psgcCode: Value(b.psgcCode),
              status: b.status,
              label: b.label,
            ),
        ]);
      });
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _eventPrefsKey,
      jsonEncode({
        'name': board.eventName,
        'status': board.eventStatus,
        'is_drill': board.isDrill,
      }),
    );
  }

  Future<BarangayStatusBoard> _load() async {
    final rows = await (_db.select(
      _db.barangayStatuses,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
    if (rows.isEmpty) {
      throw StateError('No barangay status saved on this device yet.');
    }
    Map<String, dynamic> event = const {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_eventPrefsKey);
      if (raw != null) event = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // No event saved: show the statuses without one.
    }
    return BarangayStatusBoard(
      eventName: event['name'] as String?,
      eventStatus: event['status'] as String?,
      isDrill: event['is_drill'] as bool? ?? false,
      isFromCache: true,
      lastSyncedAt: await _syncTimestamps.getSynced(SyncDomain.barangayStatus),
      barangays: [
        for (final r in rows)
          BarangayStatus(
            id: r.id,
            name: r.name,
            psgcCode: r.psgcCode,
            status: r.status,
            label: r.label,
          ),
      ],
    );
  }
}
