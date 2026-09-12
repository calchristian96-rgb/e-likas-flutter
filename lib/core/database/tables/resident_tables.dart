import 'package:drift/drift.dart';

/// Cached evacuation centers — mirrors `EvacuationCenterModel` (the
/// Isar collection it replaces) field-for-field, including which
/// fields are genuinely nullable per the backend contract (see that
/// model's own doc comment for the endpoint-by-endpoint reasoning).
///
/// Explicit `@DataClassName`: Drift's default row-class name would be
/// `EvacuationCenter`, colliding with the existing domain entity class
/// of that same name (`evacuation_centers/domain/entities
/// /evacuation_center.dart`) — the `Row` suffix keeps the two
/// unambiguous everywhere both are in scope.
@DataClassName('EvacuationCenterRow')
class EvacuationCenters extends Table {
  /// The backend's own numeric id, used directly as the primary key —
  /// same reasoning `EvacuationCenterModel.id` already documented:
  /// it's already guaranteed unique, and using it directly makes
  /// upserts a plain `insertOnConflictUpdate` keyed on a real id.
  IntColumn get id => integer()();

  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get address => text().nullable()();
  TextColumn get barangay => text().nullable()();
  IntColumn get barangayId => integer().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get capacityPersons => integer()();
  IntColumn get capacityFamilies => integer().nullable()();
  IntColumn get currentOccupancy => integer().nullable()();
  RealColumn get occupancyPercent => real().nullable()();
  TextColumn get status => text()();
  RealColumn get distanceMeters => real().nullable()();
  TextColumn get photoUrl => text().nullable()();
  IntColumn get createdBy => integer().nullable()();
  TextColumn get campManagerName => text().nullable()();
  TextColumn get campManagerContact => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached alerts — mirrors `AlertModel`. `dateSentUtcMs` keeps the same
/// epoch-milliseconds-in-UTC representation the Isar model deliberately
/// chose over a native `DateTime` column, for the same reason: a
/// display timestamp should never silently shift on a read round-trip.
@DataClassName('AlertRow')
class Alerts extends Table {
  IntColumn get id => integer()();

  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get alertType => text()();
  TextColumn get status => text()();
  TextColumn get severity => text().nullable()();
  IntColumn get dateSentUtcMs => integer().nullable()();
  TextColumn get evacuationEventName => text().nullable()();
  TextColumn get senderName => text().nullable()();
  TextColumn get recipientSummary => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached hazard-area polygons — mirrors `HazardAreaModel`.
/// `boundaryLatLngFlat` (a flat `[lat1, lng1, lat2, lng2, ...]` list on
/// the Isar side) is stored as a comma-joined string, the same flat
/// representation, since Drift has no native list-of-double column
/// type.
@DataClassName('HazardAreaRow')
class HazardAreas extends Table {
  IntColumn get id => integer()();

  TextColumn get name => text()();
  TextColumn get hazardType => text()();
  TextColumn get severityLevel => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get boundaryLatLngFlatCsv => text()();

  @override
  Set<Column> get primaryKey => {id};
}
