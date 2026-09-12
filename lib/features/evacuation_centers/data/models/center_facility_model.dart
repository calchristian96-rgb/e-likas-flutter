import '../../domain/entities/center_facility.dart';

/// Data-layer shape of one facility-checklist row from
/// `PublicController::evacuationCenter()`'s `facilities` array.
///
/// Deliberately plain Dart, not an Isar `@collection` like
/// `EvacuationCenterModel`/`AlertModel` — this data isn't cached
/// offline (see the details page's facilities section, which is a
/// live, independently-loading/erroring request, not part of the
/// existing Drift/Isar offline architecture).
class CenterFacilityModel {
  const CenterFacilityModel({
    required this.facilityType,
    required this.quantity,
    required this.isAvailable,
    this.concernsAndNeeds,
  });

  final String facilityType;
  final int quantity;
  final bool isAvailable;
  final String? concernsAndNeeds;

  factory CenterFacilityModel.fromJson(Map<String, dynamic> json) {
    return CenterFacilityModel(
      facilityType: json['facility_type'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] as bool? ?? false,
      concernsAndNeeds: json['concerns_and_needs'] as String?,
    );
  }

  CenterFacility toEntity() {
    return CenterFacility(
      facilityType: facilityType,
      quantity: quantity,
      isAvailable: isAvailable,
      concernsAndNeeds: concernsAndNeeds,
    );
  }
}
