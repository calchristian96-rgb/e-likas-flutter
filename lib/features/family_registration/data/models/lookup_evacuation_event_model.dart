/// Offline cache of `GET /evacuation-events` — only the fields the
/// registration form actually needs to let staff pick the right
/// event and see whether it's still open (name/status/dates), not the
/// full `EvacuationEventResource` (which also carries typhoon-specific
/// numbers and live displacement counts that have no offline-form
/// use). The backend returns every event regardless of status; this
/// mirrors that, and the form itself filters to non-closed ones.
class LookupEvacuationEventModel {
  LookupEvacuationEventModel({
    required this.id,
    required this.name,
    required this.status,
    this.startDate,
    this.endDate,
  });

  final int id;
  final String name;

  /// One of the backend's evacuation_events.status values, e.g.
  /// "active"/"closed" — used to filter the picker to open events.
  final String status;

  final String? startDate;
  final String? endDate;

  factory LookupEvacuationEventModel.fromJson(Map<String, dynamic> json) {
    return LookupEvacuationEventModel(
      id: json['id'] as int,
      name: json['name'] as String,
      status: json['status'] as String,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );
  }
}
