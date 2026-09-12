import 'package:drift/drift.dart';

import '../../../../core/database/resident_database.dart';
import '../models/alert_model.dart';

/// Drift-backed cache for alerts — the offline-first half of the
/// Alerts feature.
class AlertsLocalDatasource {
  const AlertsLocalDatasource(this._db);

  final ResidentDatabase _db;

  /// Cached alerts, newest first — same in-Dart sort (rather than a
  /// SQL `ORDER BY`) this datasource always used: the cache holds tens
  /// of rows, not thousands, so the cost is irrelevant, and alerts
  /// with no date sort last rather than being dropped.
  Future<List<AlertModel>> getCachedAlerts() async {
    final rows = await _db.select(_db.alerts).get();
    return _newestFirst(rows.map(_fromRow).toList());
  }

  Future<AlertModel?> getCachedAlertById(int id) async {
    final row = await (_db.select(
      _db.alerts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Writes [alerts]. Deliberately accumulative — old alerts already
  /// cached are never cleared when a newer page arrives, so a resident
  /// who goes offline never loses an alert older than the last page
  /// they happened to load.
  Future<void> cacheAlerts(List<AlertModel> alerts) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.alerts, [
        for (final alert in alerts) _toCompanion(alert),
      ]);
    });
  }

  List<AlertModel> _newestFirst(List<AlertModel> alerts) {
    final sorted = [...alerts]
      ..sort((a, b) {
        final aMs = a.dateSentUtcMs;
        final bMs = b.dateSentUtcMs;
        if (aMs == null && bMs == null) return 0;
        if (aMs == null) return 1;
        if (bMs == null) return -1;
        return bMs.compareTo(aMs);
      });
    return sorted;
  }

  static AlertsCompanion _toCompanion(AlertModel m) {
    return AlertsCompanion.insert(
      id: Value(m.id),
      title: m.title,
      message: m.message,
      alertType: m.alertType,
      status: m.status,
      severity: Value(m.severity),
      dateSentUtcMs: Value(m.dateSentUtcMs),
      evacuationEventName: Value(m.evacuationEventName),
      senderName: Value(m.senderName),
      recipientSummary: Value(m.recipientSummary),
    );
  }

  static AlertModel _fromRow(AlertRow row) {
    return AlertModel(
      id: row.id,
      title: row.title,
      message: row.message,
      alertType: row.alertType,
      status: row.status,
      dateSentUtcMs: row.dateSentUtcMs,
      evacuationEventName: row.evacuationEventName,
      senderName: row.senderName,
      recipientSummary: row.recipientSummary,
      severity: row.severity,
    );
  }
}
