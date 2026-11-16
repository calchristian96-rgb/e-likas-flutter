import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// One barangay outline from the static PSA-NAMRIA boundaries file
/// (bundled; the backend serves the same file at
/// `/data/ligao-barangay-boundaries.geojson`). Matched to a status by
/// [psgcCode], never by name (backend map-api.md).
class BarangayOutline {
  const BarangayOutline({
    required this.psgcCode,
    required this.name,
    required this.rings,
  });

  final String psgcCode;
  final String name;

  /// Outer ring first, then any holes.
  final List<List<LatLng>> rings;
}

const barangayOutlinesAsset = 'assets/data/ligao-barangay-boundaries.geojson';

/// Parses a GeoJSON FeatureCollection of Polygons (and MultiPolygons,
/// for safety). GeoJSON coordinates are `[longitude, latitude]`.
List<BarangayOutline> parseBarangayOutlines(String geojson) {
  final data = jsonDecode(geojson) as Map<String, dynamic>;
  List<LatLng> ring(List<dynamic> coords) => [
    for (final c in coords)
      LatLng(((c as List)[1] as num).toDouble(), (c[0] as num).toDouble()),
  ];
  final outlines = <BarangayOutline>[];
  for (final f in data['features'] as List) {
    final feature = f as Map<String, dynamic>;
    final props = feature['properties'] as Map<String, dynamic>? ?? const {};
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final psgc = props['psgc_code'] as String?;
    if (geometry == null || psgc == null) continue;
    final polygons = switch (geometry['type']) {
      'Polygon' => [geometry['coordinates'] as List],
      'MultiPolygon' => [
        for (final p in geometry['coordinates'] as List) p as List,
      ],
      _ => const <List>[],
    };
    for (final polygon in polygons) {
      outlines.add(
        BarangayOutline(
          psgcCode: psgc,
          name: props['name'] as String? ?? '',
          rings: [for (final r in polygon) ring(r as List)],
        ),
      );
    }
  }
  return outlines;
}

final barangayOutlinesProvider = FutureProvider<List<BarangayOutline>>((
  ref,
) async {
  final raw = await rootBundle.loadString(barangayOutlinesAsset);
  return parseBarangayOutlines(raw);
});
