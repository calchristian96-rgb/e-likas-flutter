/// The two outcomes `POST /evacuation-centers/{id}/quick-departure`
/// accepts for `status` — confirmed directly against
/// `EvacuationCenterController::quickDeparture()`'s validation rules.
enum DepartureStatus {
  returnedHome,
  transferred;

  String get wireValue => switch (this) {
    DepartureStatus.returnedHome => 'returned_home',
    DepartureStatus.transferred => 'transferred',
  };
}

const departureStatusValues = DepartureStatus.values;
