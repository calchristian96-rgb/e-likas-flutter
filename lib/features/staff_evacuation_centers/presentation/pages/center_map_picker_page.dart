import '../../../../app/theme/sheet_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/ligao_city_location.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/widgets/map_base_layer.dart';

/// Pick a center's location on the map: drag the map under the pin, then
/// "Use this point". Returns the point, or null when left without one.
class CenterMapPickerPage extends StatefulWidget {
  const CenterMapPickerPage({
    super.key,
    required this.centerName,
    this.initial,
  });

  final String centerName;
  final LatLng? initial;

  @override
  State<CenterMapPickerPage> createState() => _CenterMapPickerPageState();
}

class _CenterMapPickerPageState extends State<CenterMapPickerPage> {
  final _controller = MapController();
  late LatLng _point =
      widget.initial ??
      const LatLng(LigaoCityLocation.latitude, LigaoCityLocation.longitude);
  MapBaseLayer _base = MapBaseLayer.street;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.centerMapPickerTitle),
        actions: [
          IconButton(
            tooltip: l10n.centerMapPickerSatellite,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => setState(
              () => _base = _base == MapBaseLayer.street
                  ? MapBaseLayer.satellite
                  : MapBaseLayer.street,
            ),
            icon: Icon(
              _base == MapBaseLayer.street
                  ? Icons.satellite_alt_outlined
                  : Icons.map_outlined,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _point,
              initialZoom: widget.initial == null ? 14 : 17,
              backgroundColor: Sheet.paper2,
              onPositionChanged: (camera, _) =>
                  setState(() => _point = camera.center),
              onTap: (_, p) {
                _controller.move(p, _controller.camera.zoom);
                setState(() => _point = p);
              },
            ),
            children: [
              mapBaseTileLayer(_base),
              MapAttribution(baseLayer: _base),
            ],
          ),
          // The pin stays in the middle; the map moves under it.
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Icon(
                  Icons.location_pin,
                  size: 48,
                  color: theme.colorScheme.error,
                  semanticLabel: l10n.centerMapPickerPin,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.centerMapPickerHint(widget.centerName),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${_point.latitude.toStringAsFixed(6)}, '
                '${_point.longitude.toStringAsFixed(6)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(context).pop(_point),
                child: Text(l10n.centerMapPickerUse),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
