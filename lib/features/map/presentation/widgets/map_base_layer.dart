import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // The street map is printed onto the sheet like the web's: the
    // tiles desaturated and warmed towards map paper. Satellite imagery
    // stays true to life.
    tileBuilder: baseLayer == MapBaseLayer.street ? _printedTile : null,
  );
}

/// The web's `saturate(.5) sepia(.18) hue-rotate(35deg) contrast(1.06)
/// brightness(1.04)` as one colour matrix.
const _printedMapMatrix = <double>[
  0.487, 0.3449, 0.3035, 0, -7.956, //
  0.2137, 0.9489, -0.0085, 0, -7.956, //
  -0.045, 0.683, 0.4464, 0, -7.956, //
  0, 0, 0, 1, 0, //
];

Widget _printedTile(BuildContext context, Widget tileWidget, TileImage tile) =>
    ColorFiltered(
      colorFilter: const ColorFilter.matrix(_printedMapMatrix),
      child: tileWidget,
    );

/// An extra attribution line for an overlay layer; tapping it opens [url].
class MapOverlayAttribution {
  const MapOverlayAttribution({required this.text, required this.url});

  final String text;
  final String url;
}

/// Attribution for whichever [baseLayer] is currently active — never
/// mislabels Esri imagery as OpenStreetMap or vice versa. Overlay
/// attributions are optional; the staff picker passes none.
class MapAttribution extends StatelessWidget {
  const MapAttribution({
    super.key,
    required this.baseLayer,
    this.overlayAttributions = const [],
  });

  final MapBaseLayer baseLayer;
  final List<MapOverlayAttribution> overlayAttributions;

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
        for (final overlay in overlayAttributions)
          TextSourceAttribution(
            overlay.text,
            onTap: () => _openUrl(overlay.url),
          ),
      ],
    );
  }
}

/// Never throws — an attribution link that can't open is just ignored.
Future<void> _openUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
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
