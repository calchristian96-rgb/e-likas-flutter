import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/ligao_city_location.dart';
import '../../../../core/error/result.dart';
import '../../../../core/location/location_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/widgets/map_base_layer.dart';
import '../widgets/coordinate_parser.dart';

/// What the picker returned — a real three-way result (`Navigator.pop`
/// with plain `null` means "back/cancel, no change") rather than just
/// a nullable `LatLng`, so the form can tell "clear the location" and
/// "I didn't touch anything" apart.
class CenterLocationPickerResult {
  const CenterLocationPickerResult.selected(this.latitude, this.longitude)
    : cleared = false;

  const CenterLocationPickerResult.cleared()
    : latitude = null,
      longitude = null,
      cleared = true;

  final double? latitude;
  final double? longitude;
  final bool cleared;
}

/// Reusable Street/Satellite map location picker for the staff
/// Add/Edit Evacuation Center form — tap the map, use current
/// location, or paste coordinates; all three set the same single
/// selected-location state, so whichever was used last wins. Reuses
/// the exact base-map architecture the resident GIS Map page uses
/// (`map_base_layer.dart`) rather than a second implementation.
class CenterLocationPickerPage extends ConsumerStatefulWidget {
  const CenterLocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  ConsumerState<CenterLocationPickerPage> createState() =>
      _CenterLocationPickerPageState();
}

class _CenterLocationPickerPageState
    extends ConsumerState<CenterLocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _coordsController = TextEditingController();

  double? _latitude;
  double? _longitude;
  MapBaseLayer _baseLayer = MapBaseLayer.street;
  String? _coordsError;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    if (_latitude != null && _longitude != null) {
      _coordsController.text = '$_latitude, $_longitude';
    }
  }

  @override
  void dispose() {
    _coordsController.dispose();
    super.dispose();
  }

  LatLng get _initialCenter => _latitude != null && _longitude != null
      ? LatLng(_latitude!, _longitude!)
      : const LatLng(LigaoCityLocation.latitude, LigaoCityLocation.longitude);

  void _setLocation(double lat, double lng, {bool recenter = true}) {
    setState(() {
      _latitude = lat;
      _longitude = lng;
      _coordsError = null;
      _coordsController.text = '$lat, $lng';
    });
    if (recenter) _mapController.move(LatLng(lat, lng), 16);
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    // Fine-tuning: a second tap simply moves the same marker — there
    // is only ever one selected-location state, never a second one
    // added alongside it.
    _setLocation(point.latitude, point.longitude, recenter: false);
  }

  void _handleSetPasted() {
    final result = parseCoordinates(_coordsController.text);
    if (result == null) {
      setState(() {
        _coordsError = AppLocalizations.of(context).centerInvalidCoordinates;
      });
      return;
    }
    _setLocation(result.latitude, result.longitude);
  }

  void _handleClear() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _coordsError = null;
      _coordsController.clear();
    });
  }

  Future<void> _handleUseCurrentLocation() async {
    setState(() => _locating = true);
    final result = await ref.read(locationServiceProvider).getCurrentPosition();
    if (!mounted) return;
    setState(() => _locating = false);

    switch (result) {
      case Success(:final value):
        _setLocation(value.latitude, value.longitude);
      case Failed(:final failure):
        // Friendly handling, same as the resident map's "Locate Me" —
        // and never blocks manual map/paste selection either way.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  void _confirm() {
    final lat = _latitude;
    final lng = _longitude;
    Navigator.of(context).pop(
      lat != null && lng != null
          ? CenterLocationPickerResult.selected(lat, lng)
          : const CenterLocationPickerResult.cleared(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasLocation = _latitude != null && _longitude != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.centerChooseLocation)),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: hasLocation ? 16 : 13,
                    onTap: _handleMapTap,
                  ),
                  children: [
                    mapBaseTileLayer(_baseLayer),
                    MapAttribution(baseLayer: _baseLayer),
                    MarkerLayer(
                      markers: [
                        if (hasLocation)
                          Marker(
                            point: LatLng(_latitude!, _longitude!),
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_on,
                              color: theme.colorScheme.primary,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'center-picker-base-layer',
                          tooltip: l10n.mapBaseLayerLabel,
                          onPressed: () => setState(
                            () => _baseLayer = _baseLayer == MapBaseLayer.street
                                ? MapBaseLayer.satellite
                                : MapBaseLayer.street,
                          ),
                          child: Icon(
                            _baseLayer == MapBaseLayer.street
                                ? Icons.satellite_alt_outlined
                                : Icons.map_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton.small(
                          heroTag: 'center-picker-locate-me',
                          tooltip: l10n.showMyLocation,
                          onPressed: _locating
                              ? null
                              : _handleUseCurrentLocation,
                          child: _locating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.centerPasteCoordinatesLabel,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _coordsController,
                          decoration: InputDecoration(
                            hintText: '13.139123, 123.532145',
                            border: const OutlineInputBorder(),
                            errorText: _coordsError,
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          onChanged: (_) {
                            if (_coordsError != null) {
                              setState(() => _coordsError = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _handleSetPasted,
                        child: Text(l10n.centerSetCoordinates),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (hasLocation) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleClear,
                            icon: const Icon(Icons.location_off_outlined),
                            label: Text(l10n.centerClearLocation),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _confirm,
                          icon: const Icon(Icons.check),
                          label: Text(
                            hasLocation
                                ? l10n.centerUseThisLocation
                                : l10n.centerSaveWithoutLocation,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
