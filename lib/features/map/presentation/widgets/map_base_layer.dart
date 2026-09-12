import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../l10n/app_localizations.dart';

/// The two mutually-exclusive base maps — never hazard/overlay layers,
/// which stay independent of this (markers, hazard polygons, current
/// location, selection all render on top of whichever one is active).
///
/// Shared between the resident GIS Map page and the staff evacuation-
/// center location picker (Part 2) — one base-map implementation, not
/// two: both just build a [TileLayer] from the same enum/URLs and show
/// the same [MapAttribution].
enum MapBaseLayer { street, satellite }

/// Esri World Imagery — no API key required, confirmed against Esri's
/// own published REST endpoint. An online-only tile source: using it
/// does not imply offline satellite tiles are cached anywhere.
const satelliteTileUrlTemplate =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
const streetTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// The `TileLayer` for [baseLayer] — same URL templates/user agent
/// every base map on this map uses, so there's exactly one place that
/// could get either wrong.
TileLayer mapBaseTileLayer(MapBaseLayer baseLayer) {
  return TileLayer(
    urlTemplate: switch (baseLayer) {
      MapBaseLayer.street => streetTileUrlTemplate,
      MapBaseLayer.satellite => satelliteTileUrlTemplate,
    },
    userAgentPackageName: 'com.cswdo.elikas_mobile',
  );
}

/// Attribution for whichever [baseLayer] is currently active — never
/// mislabels Esri imagery as OpenStreetMap or vice versa.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key, required this.baseLayer});

  final MapBaseLayer baseLayer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      attributions: [
        if (baseLayer == MapBaseLayer.street)
          TextSourceAttribution(l10n.mapAttributionOpenStreetMap)
        else
          TextSourceAttribution(l10n.mapAttributionEsri),
      ],
    );
  }
}

/// The compact "Base Map: Street / Satellite" control — used in the
/// resident map's Layers sheet and the staff location picker alike.
class BaseLayerSegmentedButton extends StatelessWidget {
  const BaseLayerSegmentedButton({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final MapBaseLayer selected;
  final ValueChanged<MapBaseLayer> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<MapBaseLayer>(
      segments: [
        ButtonSegment(
          value: MapBaseLayer.street,
          label: Text(l10n.mapBaseLayerStreet),
          icon: const Icon(Icons.map_outlined, size: 18),
        ),
        ButtonSegment(
          value: MapBaseLayer.satellite,
          label: Text(l10n.mapBaseLayerSatellite),
          icon: const Icon(Icons.satellite_alt_outlined, size: 18),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
