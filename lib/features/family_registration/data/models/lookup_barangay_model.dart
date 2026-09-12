/// Offline cache of `GET /barangays` — mirrors that endpoint's actual
/// (minimal) response exactly: `Barangay::orderBy('name')->get(['id',
/// 'name'])`. No other `barangays` columns (psgc_code, centroid
/// lat/lng) are returned by that endpoint, so none are cached here.
class LookupBarangayModel {
  LookupBarangayModel({required this.id, required this.name});

  final int id;
  final String name;

  factory LookupBarangayModel.fromJson(Map<String, dynamic> json) {
    return LookupBarangayModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
