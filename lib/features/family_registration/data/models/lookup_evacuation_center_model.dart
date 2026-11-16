/// Offline cache of the staff `GET /evacuation-centers?include_rejected=1`
/// list: `id, name, barangay_id, status, approval_status,
/// rejection_reason, has_pending_change` (backend step 7). A barangay
/// official only ever gets their own barangay's centers, including
/// pending ("Unverified") ones; CSWD gets every barangay's.
class LookupEvacuationCenterModel {
  LookupEvacuationCenterModel({
    required this.id,
    required this.name,
    required this.barangayId,
    required this.status,
    this.approvalStatus = 'approved',
    this.hasPendingChange = false,
    this.rejectionReason,
  });

  final int id;
  final String name;
  final int barangayId;
  final String status;
  final String approvalStatus;
  final bool hasPendingChange;
  final String? rejectionReason;

  factory LookupEvacuationCenterModel.fromJson(Map<String, dynamic> json) {
    return LookupEvacuationCenterModel(
      id: json['id'] as int,
      name: json['name'] as String,
      barangayId: json['barangay_id'] as int,
      status: json['status'] as String,
      approvalStatus: json['approval_status'] as String? ?? 'approved',
      hasPendingChange: json['has_pending_change'] as bool? ?? false,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}
