/// Offline cache of the staff `GET /evacuation-centers` list — mirrors
/// that endpoint's own deliberately minimal shape (confirmed:
/// `EvacuationCenter::query()->get(['id','name','barangay_id','status'])`,
/// no lat/lng/occupancy). Only used to populate the "inside a center"
/// picker on the registration form, which needs exactly these fields.
class LookupEvacuationCenterModel {
  LookupEvacuationCenterModel({
    required this.id,
    required this.name,
    required this.barangayId,
    required this.status,
  });

  final int id;
  final String name;
  final int barangayId;
  final String status;

  factory LookupEvacuationCenterModel.fromJson(Map<String, dynamic> json) {
    return LookupEvacuationCenterModel(
      id: json['id'] as int,
      name: json['name'] as String,
      barangayId: json['barangay_id'] as int,
      status: json['status'] as String,
    );
  }
}
