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
@DriftDatabase(tables: [EvacuationCenters, Alerts, HazardAreas])
class ResidentDatabase extends _$ResidentDatabase {
  ResidentDatabase() : super(openSqlCipherDatabase('elikas_resident.sqlite'));

  @override
  int get schemaVersion => 1;
}

@Riverpod(keepAlive: true)
ResidentDatabase residentDatabase(Ref ref) {
  final db = ResidentDatabase();
  ref.onDispose(db.close);
  return db;
}
