/// Offline cache of the staff `GET /evacuation-centers?include_rejected=1`
/// list: `id, name, barangay_id, status, approval_status,
/// rejection_reason, has_pending_change` (backend step 7). A barangay
/// official only ever gets their own barangay's centers, including
/// pending ("Unverified") ones; CSWD gets every barangay's.
///
/// Since backend d17f6de the plain list also carries the center figures
/// for the event named by `evacuation_event_id`
/// (docs/backend/apps-api-2026-11-center-figures-per-event.md):
/// `capacity_persons`, `current_occupancy`, `occupancy_percent` (people
/// inside for that event only), `total_occupancy` (everyone inside) and
/// `occupancy_note` ("87 people here for Typhoon Drill"). [figuresEventId]
/// records which event those figures are for.
class LookupEvacuationCenterModel {
  LookupEvacuationCenterModel({
    required this.id,
    required this.name,
    required this.barangayId,
    required this.status,
    this.approvalStatus = 'approved',
    this.hasPendingChange = false,
    this.rejectionReason,
    this.capacityPersons,
    this.currentOccupancy,
    this.occupancyPercent,
    this.totalOccupancy,
    this.occupancyNote,
    this.figuresEventId,
  });

  final int id;
  final String name;
  final int barangayId;
  final String status;
  final String approvalStatus;
  final bool hasPendingChange;
  final String? rejectionReason;
  final int? capacityPersons;
  final int? currentOccupancy;
  final double? occupancyPercent;
  final int? totalOccupancy;
  final String? occupancyNote;
  final int? figuresEventId;

  factory LookupEvacuationCenterModel.fromJson(
    Map<String, dynamic> json, {
    int? eventId,
  }) {
    return LookupEvacuationCenterModel(
      id: json['id'] as int,
      name: json['name'] as String,
      barangayId: json['barangay_id'] as int,
      // The status shown (backend bd5b433): people inside make a center
      // active, or full near capacity; `status` is what officials set.
      status: json['effective_status'] as String? ?? json['status'] as String,
      approvalStatus: json['approval_status'] as String? ?? 'approved',
      hasPendingChange: json['has_pending_change'] as bool? ?? false,
      rejectionReason: json['rejection_reason'] as String?,
      capacityPersons: (json['capacity_persons'] as num?)?.toInt(),
      currentOccupancy: (json['current_occupancy'] as num?)?.toInt(),
      occupancyPercent: (json['occupancy_percent'] as num?)?.toDouble(),
      totalOccupancy: (json['total_occupancy'] as num?)?.toInt(),
      occupancyNote: json['occupancy_note'] as String?,
      figuresEventId: eventId,
    );
  }
}
