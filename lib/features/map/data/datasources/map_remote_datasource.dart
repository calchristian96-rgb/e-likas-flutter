import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../evacuation_centers/data/models/evacuation_center_model.dart';
import '../models/hazard_area_model.dart';

/// Both parsed lists from one GeoJSON FeatureCollection response.
typedef MapFeatures = ({
  List<EvacuationCenterModel> centers,
  List<HazardAreaModel> hazardAreas,
});

class MapRemoteDatasource {
  const MapRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<MapFeatures> getMapData() async {
    final response = await _apiClient.get(ApiEndpoints.mapData);
    final envelope = response.data as Map<String, dynamic>;
    // The public API wraps every response as {success, message, data}
    // (see core/network/api_response.dart). `data` here is NOT a single
    // FeatureCollection: GisController::mapData() returns two separate
    // ones, `evacuation_centers` and `hazard_areas`, each with its own
    // `features` list — confirmed directly against
    // app/Http/Controllers/Api/GisController.php.
    final data = envelope['data'] as Map<String, dynamic>;
    final centerFeatures = _featuresOf(data, 'evacuation_centers');
    final hazardFeatures = _featuresOf(data, 'hazard_areas');

    final centers = <EvacuationCenterModel>[
      for (final feature in centerFeatures)
        EvacuationCenterModel.fromGeoJsonFeature(
          feature['properties'] as Map<String, dynamic>,
          feature['geometry'] as Map<String, dynamic>,
        ),
    ];
    final hazardAreas = <HazardAreaModel>[
      for (final feature in hazardFeatures)
        HazardAreaModel.fromGeoJsonFeature(
          feature['properties'] as Map<String, dynamic>,
          feature['geometry'] as Map<String, dynamic>,
        ),
    ];

    return (centers: centers, hazardAreas: hazardAreas);
  }

  static List<Map<String, dynamic>> _featuresOf(
    Map<String, dynamic> data,
    String collectionKey,
  ) {
    final collection = data[collectionKey] as Map<String, dynamic>?;
    final features = collection?['features'] as List?;
    return features?.cast<Map<String, dynamic>>() ?? const [];
  }
}
