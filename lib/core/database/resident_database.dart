import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'db_connection.dart';
import 'tables/resident_tables.dart';

part 'resident_database.g.dart';

/// The Drift replacement for the resident (unencrypted) Isar instance
/// — see `core/cache/isar_service.dart`'s doc comment for the
/// collections this takes over. Opened with no encryption key: this
/// data has nothing sensitive in it (public evacuation-center/alert/
/// hazard data, fully regenerable from the API), same as the Isar
/// instance it replaces.
@DriftDatabase(
  tables: [EvacuationCenters, Alerts, HazardAreas, BarangayStatuses],
)
class ResidentDatabase extends _$ResidentDatabase {
  ResidentDatabase() : super(openSqlCipherDatabase('elikas_resident.sqlite'));

  /// Tests: an in-memory executor.
  ResidentDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => 5;

  /// Schema 2 adds [BarangayStatuses]; schema 3 adds `alerts.is_drill`;
  /// schema 4 adds `evacuation_centers.capacity_source`; schema 5 adds
  /// the alert's target (city or one barangay).
  /// Everything here is regenerable from the public API, but an upgrade
  /// still keeps the cached rows.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(barangayStatuses);
      if (from < 3) await m.addColumn(alerts, alerts.isDrill);
      if (from < 4) {
        await m.addColumn(evacuationCenters, evacuationCenters.capacitySource);
      }
      if (from < 5) {
        await m.addColumn(alerts, alerts.targetKind);
        await m.addColumn(alerts, alerts.targetLabel);
        await m.addColumn(alerts, alerts.targetBarangayId);
      }
    },
  );
}

@Riverpod(keepAlive: true)
ResidentDatabase residentDatabase(Ref ref) {
  final db = ResidentDatabase();
  ref.onDispose(db.close);
  return db;
}
