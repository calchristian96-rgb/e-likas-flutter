import 'dart:math' as math;

import 'package:elikas_mobile/features/map/presentation/widgets/hazard_overlay_layer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _root = 'https://ulap-hazards.georisk.gov.ph/arcgis/services';

void main() {
  group('overlay config', () {
    final cases = <(HazardOverlay, String, List<(String, int)>)>[
      (
        hazardOverlayFlood,
        '$_root/MGBPublic/Flood/MapServer/WMSServer?',
        [
          ('Very High Susceptibility', 0xFF002673),
          ('High Susceptibility', 0xFF5900FF),
          ('Moderate Susceptibility', 0xFFB045FF),
          ('Low Susceptibility', 0xFFE3D1FF),
        ],
      ),
      (
        hazardOverlayLandslide,
        '$_root/MGBPublic/RainInducedLandslide/MapServer/WMSServer?',
        [
          ('Very High Susceptibility', 0xFF902400),
          ('High Susceptibility', 0xFFFF0000),
          ('Moderate Susceptibility', 0xFF008000),
          ('Low Susceptibility', 0xFFFFFF00),
          ('Debris Flow/Possible Accumulation Zone', 0xFF000000),
        ],
      ),
    ];

    for (final (overlay, url, classes) in cases) {
      test('${overlay.id} matches the web module', () {
        expect(overlay.wmsBaseUrl, url);
        expect(overlay.layers, ['0']);
        expect([
          for (final c in overlay.classes) (c.label, c.color.toARGB32()),
        ], classes);
      });
    }

    test('opacity, attribution and order', () {
      expect(hazardOverlayOpacity, 0.7);
      expect(hazardOverlayAttributionUrl, 'https://georisk.gov.ph/');
      expect(hazardOverlays.map((o) => o.id), ['flood', 'landslide']);
    });
  });

  group('WMS GetMap url', () {
    for (final overlay in hazardOverlays) {
      final options = WMSTileLayerOptions(
        baseUrl: overlay.wmsBaseUrl,
        layers: overlay.layers,
        version: '1.3.0',
      );

      void expectParams(String url) {
        expect(url, startsWith(overlay.wmsBaseUrl));
        expect(url, contains('version=1.3.0'));
        expect(url, contains('crs=EPSG%3A3857'));
        expect(url, contains('layers=0'));
        expect(url, contains('format=image%2Fpng'));
        expect(url, contains('transparent=true'));
      }

      List<double> bbox(String url) => Uri.parse(
        url,
      ).queryParameters['bbox']!.split(',').map(double.parse).toList();

      test('${overlay.id} z0 covers the whole world', () {
        final url = options.getUrl(const TileCoordinates(0, 0, 0), 256, false);
        expectParams(url);
        const edge = 20037508.34;
        final b = bbox(url);
        expect(b[0], closeTo(-edge, 1));
        expect(b[1], closeTo(-edge, 1));
        expect(b[2], closeTo(edge, 1));
        expect(b[3], closeTo(edge, 1));
      });

      test('${overlay.id} z13 tile over Ligao contains the point', () {
        const lat = 13.24, lon = 123.52, z = 13;
        final n = math.pow(2, z);
        final x = ((lon + 180) / 360 * n).floor();
        final latRad = lat * math.pi / 180;
        final y =
            ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
                    2 *
                    n)
                .floor();
        final url = options.getUrl(TileCoordinates(x, y, z), 256, false);
        expectParams(url);
        final b = bbox(url);
        final Offset p = const Epsg3857().projection.project(
          const LatLng(lat, lon),
        );
        expect(p.dx, inInclusiveRange(b[0], b[2]));
        expect(p.dy, inInclusiveRange(b[1], b[3]));
      });
    }
  });
}
