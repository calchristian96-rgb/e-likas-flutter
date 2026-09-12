import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/ligao_city_location.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/distance_formatter.dart';
import '../../../../core/utils/map_launcher.dart';
import '../../../../core/widgets/center_summary_row.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/occupancy_progress.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../../../evacuation_centers/presentation/providers/center_photo_provider.dart';
import '../../../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../domain/entities/hazard_area.dart';
import '../providers/map_provider.dart';
import '../widgets/hazard_polygon_layer.dart';
import '../widgets/map_base_layer.dart';

/// Used only as a fallback map center when there's no data at all yet
/// (first launch, fully offline, empty cache). Once real center data
/// loads, the map centers on that instead.
const _ligaoCityFallbackCenter = LatLng(
  LigaoCityLocation.latitude,
  LigaoCityLocation.longitude,
);

/// Statuses/hazard types are listed in this fixed, sensible order
/// whenever more than one is present — never alphabetical (which would
/// read oddly, e.g. "Active, Closed, Full, On standby") and never in
/// whatever order the cache happens to return rows in.
const _statusDisplayOrder = ['active', 'on_standby', 'full', 'closed'];
const _hazardTypeDisplayOrder = [
  'flood',
  'landslide',
  'lahar',
  'storm_surge',
  'volcanic_danger_zone',
];

class EvacuationMapPage extends ConsumerWidget {
  const EvacuationMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mapDataAsync = ref.watch(mapDataProvider);
    final isConnected = ref.watch(connectivityStatusProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.hazardMapTitle)),
      body: Column(
        children: [
          OfflineBanner(isOffline: !isConnected, lastUpdated: null),
          Expanded(
            child: mapDataAsync.when(
              data: (mapData) {
                if (mapData.centers.isEmpty && mapData.hazardAreas.isEmpty) {
                  return Center(
                    child: EmptyState(
                      message: l10n.noMapData,
                      icon: Icons.map_outlined,
                    ),
                  );
                }
                return _MapView(
                  centers: mapData.centers,
                  hazardAreas: mapData.hazardAreas,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: ErrorState(
                  message: '${l10n.couldNotLoadMapData} — $error',
                  icon: Icons.map_outlined,
                  onRetry: () => ref.invalidate(mapDataProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapView extends ConsumerStatefulWidget {
  const _MapView({required this.centers, required this.hazardAreas});

  final List<EvacuationCenter> centers;
  final List<HazardArea> hazardAreas;

  @override
  ConsumerState<_MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<_MapView> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  LatLng? _myPosition;
  bool _locating = false;

  bool _showCenters = true;
  bool _showHazards = true;
  bool _showMyLocation = true;
  MapBaseLayer _baseLayer = MapBaseLayer.street;

  /// Opt-*out* sets, not opt-in: empty means "show everything currently
  /// known" by default, so newly-appeared statuses/hazard types (e.g.
  /// after reconnecting and fetching fresher data than what was cached)
  /// are visible automatically rather than silently hidden because they
  /// weren't in some snapshot taken when the map first opened.
  final Set<String> _excludedStatuses = {};
  final Set<String> _excludedHazardTypes = {};

  int? _selectedCenterId;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<String> get _availableStatuses {
    final present = {for (final c in widget.centers) c.status.toLowerCase()};
    return [
      for (final s in _statusDisplayOrder)
        if (present.contains(s)) s,
    ];
  }

  List<String> get _availableHazardTypes {
    final present = {
      for (final h in widget.hazardAreas) h.hazardType.toLowerCase(),
    };
    return [
      for (final t in _hazardTypeDisplayOrder)
        if (present.contains(t)) t,
    ];
  }

  List<EvacuationCenter> get _visibleCenters {
    if (!_showCenters) return const [];
    return widget.centers
        .where((c) => !_excludedStatuses.contains(c.status.toLowerCase()))
        .toList();
  }

  List<HazardArea> get _visibleHazardAreas {
    if (!_showHazards) return const [];
    return widget.hazardAreas
        .where(
          (h) => !_excludedHazardTypes.contains(h.hazardType.toLowerCase()),
        )
        .toList();
  }

  /// Search only ever considers currently-visible centers — a resident
  /// who filtered to "Active" and then searches shouldn't be shown (or
  /// able to select) a closed center the filter just hid.
  List<EvacuationCenter> get _searchResults {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _visibleCenters.where((c) {
      return c.name.toLowerCase().contains(query) ||
          (c.address?.toLowerCase().contains(query) ?? false) ||
          (c.barangay?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Reuses the same [LocationService] the Nearest Center feature
  /// already uses — no new GPS/permission logic, just centering the
  /// existing map on whatever position it already knows how to get.
  /// Also turns the "My Location" layer back on, since asking to be
  /// located and then not seeing yourself on the map would be
  /// confusing.
  Future<void> _locateMe() async {
    setState(() => _locating = true);
    final result = await ref.read(locationServiceProvider).getCurrentPosition();
    if (!mounted) return;
    setState(() => _locating = false);

    switch (result) {
      case Success(:final value):
        final point = LatLng(value.latitude, value.longitude);
        setState(() {
          _myPosition = point;
          _showMyLocation = true;
        });
        _mapController.move(point, 15);
      case Failed(:final failure):
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        final reason = switch (failure) {
          LocationFailure(:final reason) => reason,
          _ => null,
        };
        final message = switch (reason) {
          LocationFailureReason.servicesDisabled => l10n.locationServicesOff,
          LocationFailureReason.permissionDenied =>
            l10n.locationPermissionDenied,
          LocationFailureReason.permanentlyDenied =>
            l10n.locationPermanentlyDenied,
          LocationFailureReason.positionUnavailable =>
            l10n.couldNotDetermineLocation,
          null => failure.message,
        };
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// A center without coordinates can still be selected (from search or
  /// a marker never applies here, since one was never created for it)
  /// — it just can't be panned/zoomed to. The bottom sheet still opens
  /// so its info remains reachable; see [_CenterSheetContent] for how
  /// it handles the missing location itself.
  void _selectCenter(EvacuationCenter center) {
    _searchFocusNode.unfocus();
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCenterId = center.id;
    });
    if (center.hasCoordinates) {
      _mapController.move(LatLng(center.latitude!, center.longitude!), 16);
    }
    _showCenterSheet(center);
  }

  void _handleSearchSubmitted(String value) {
    final results = _searchResults;
    if (results.isNotEmpty) _selectCenter(results.first);
  }

  void _resetFilters() {
    setState(() {
      _excludedStatuses.clear();
      _excludedHazardTypes.clear();
      _showCenters = true;
      _showHazards = true;
      _showMyLocation = true;
    });
  }

  /// Bounds are computed only from what's actually visible right now —
  /// respecting layer toggles and status/hazard filters — never from
  /// hidden data. A single visible point gets a sensible fixed zoom
  /// instead of `CameraFit`'s bounds math, which isn't meaningful for a
  /// zero-size bounding box. Does nothing (not a crash) when nothing is
  /// visible at all.
  void _fitToVisible() {
    final points = <LatLng>[
      for (final c in _visibleCenters)
        if (c.hasCoordinates) LatLng(c.latitude!, c.longitude!),
      if (_showMyLocation && _myPosition != null) _myPosition!,
      for (final h in _visibleHazardAreas) ...h.boundary,
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 16);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(32, 110, 32, 150),
        maxZoom: 17,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    EvacuationCenter? firstPlottableCenter;
    for (final c in widget.centers) {
      if (c.hasCoordinates) {
        firstPlottableCenter = c;
        break;
      }
    }
    final initialCenter = firstPlottableCenter != null
        ? LatLng(
            firstPlottableCenter.latitude!,
            firstPlottableCenter.longitude!,
          )
        : _ligaoCityFallbackCenter;
    final visibleCenters = _visibleCenters;
    final visibleHazards = _visibleHazardAreas;
    final searchResults = _searchResults;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: initialCenter, initialZoom: 13),
          children: [
            // Street/Satellite are mutually-exclusive BASE maps, kept
            // entirely independent of every overlay below (markers,
            // hazard polygons, current location, selection) — switching
            // this never touches map center/zoom/selection/filter state,
            // since it's just which `TileLayer` renders underneath them.
            // Shared with the staff center location picker (Part 2) —
            // see `map_base_layer.dart`.
            mapBaseTileLayer(_baseLayer),
            MapAttribution(baseLayer: _baseLayer),
            PolygonLayer(polygons: buildHazardPolygons(visibleHazards)),
            MarkerLayer(
              markers: [
                for (final center in visibleCenters)
                  if (center.hasCoordinates)
                    Marker(
                      point: LatLng(center.latitude!, center.longitude!),
                      width: center.id == _selectedCenterId ? 48 : 40,
                      height: center.id == _selectedCenterId ? 48 : 40,
                      child: GestureDetector(
                        onTap: () => _selectCenter(center),
                        child: _CenterMarkerIcon(
                          color: centerStatusColor(context, center),
                          selected: center.id == _selectedCenterId,
                        ),
                      ),
                    ),
                if (_showMyLocation && _myPosition != null)
                  Marker(
                    point: _myPosition!,
                    width: 22,
                    height: 22,
                    child: const _CurrentLocationDot(),
                  ),
              ],
            ),
          ],
        ),
        // Search bar + results overlay, top of the map.
        Positioned(
          top: 0,
          left: 12,
          right: 12,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(12),
                    child: SearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      hintText: l10n.searchCentersHint,
                      clearTooltip: l10n.clearSearch,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onSubmitted: _handleSearchSubmitted,
                    ),
                  ),
                  if (_searchQuery.trim().isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: searchResults.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                l10n.noCentersMatchFilter,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              itemCount: searchResults.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: theme.colorScheme.outlineVariant,
                              ),
                              itemBuilder: (context, index) {
                                final center = searchResults[index];
                                return CenterSummaryRow(
                                  center: center,
                                  onTap: () => _selectCenter(center),
                                );
                              },
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Layers control — upper/mid right, clear of the search overlay
        // above and the locate/fit controls below.
        Positioned(
          right: 12,
          top: 140,
          child: SafeArea(
            bottom: false,
            child: FloatingActionButton.small(
              heroTag: 'map-layers',
              tooltip: l10n.layersTooltip,
              onPressed: () => _showLayersSheet(context),
              child: const Icon(Icons.layers_outlined),
            ),
          ),
        ),
        // Legend — a small button rather than an always-visible card,
        // so a legend covering every real status/hazard type present
        // doesn't permanently take up map space.
        Positioned(
          left: 12,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: FloatingActionButton.small(
              heroTag: 'map-legend',
              tooltip: l10n.mapLegendTitle,
              onPressed: () => _showLegendSheet(context),
              child: const Icon(Icons.info_outline),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'map-locate-me',
                  tooltip: l10n.showMyLocation,
                  onPressed: _locating ? null : _locateMe,
                  child: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'map-fit-bounds',
                  tooltip: l10n.fitMapTooltip,
                  onPressed: _fitToVisible,
                  child: const Icon(Icons.fit_screen_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCenterSheet(EvacuationCenter center) {
    final accentColor = centerStatusColor(context, center);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Rounded top corners + safe-area padding, matching the rest of
      // the app's sheet/card language rather than the plain default.
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          // A modal bottom sheet's default max height (~9/16 of the
          // screen) doesn't scroll its content automatically — on a
          // short/landscape screen, a long address, or a larger Android
          // font-scale setting, this content could exceed that and
          // overflow. Scrolling instead costs nothing when everything
          // already fits (the common case), and avoids that risk when
          // it doesn't.
          child: SingleChildScrollView(
            child: _CenterSheetContent(
              center: center,
              accentColor: accentColor,
              myPosition: _myPosition,
            ),
          ),
        );
      },
      // Selection is purely a "what's the bottom sheet about" visual
      // cue — once it's dismissed there's nothing left for the ring to
      // refer to, so the marker returns to its normal look.
    ).whenComplete(() {
      if (mounted) setState(() => _selectedCenterId = null);
    });
  }

  void _showLegendSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.mapLegendTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 14),
                  if (_availableStatuses.isNotEmpty) ...[
                    Text(
                      l10n.evacuationCentersTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        for (final status in _availableStatuses)
                          _LegendEntry(
                            color: _colorForStatus(sheetContext, status),
                            label: localizedCenterStatus(sheetContext, status),
                            shape: BoxShape.circle,
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_availableHazardTypes.isNotEmpty) ...[
                    Text(
                      l10n.hazardAreasLabel,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        for (final type in _availableHazardTypes)
                          _LegendEntry(
                            color: hazardTypeColor(type),
                            label: hazardTypeLabel(sheetContext, type),
                            shape: BoxShape.rectangle,
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  _LegendEntry(
                    color: theme.colorScheme.primary,
                    label: l10n.yourLocationLegend,
                    shape: BoxShape.circle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Color _colorForStatus(BuildContext context, String status) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    return switch (status) {
      'active' => semantic.success,
      'on_standby' => semantic.warning,
      'full' => theme.colorScheme.error,
      'closed' => theme.colorScheme.onSurfaceVariant,
      _ => theme.colorScheme.onSurfaceVariant,
    };
  }

  void _showLayersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final theme = Theme.of(sheetContext);
            final l10n = AppLocalizations.of(sheetContext);
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mapLayersTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.mapBaseLayerLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BaseLayerSegmentedButton(
                        selected: _baseLayer,
                        onChanged: (layer) {
                          // Purely a `setState` on this same State — no
                          // provider invalidation, no new MapController,
                          // no rebuild of the FlutterMap widget itself —
                          // so camera position/zoom/selection/filters
                          // are all untouched by switching this.
                          setState(() => _baseLayer = layer);
                          setSheetState(() {});
                        },
                      ),
                      // Esri World Imagery is online-only — no offline
                      // satellite tile cache exists, so this is honest
                      // about what switching to it does and doesn't do
                      // offline (previously-viewed tiles may or may not
                      // still be available; nothing here promises they
                      // will be).
                      if (_baseLayer == MapBaseLayer.satellite) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.mapSatelliteOfflineNotice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const Divider(height: 28),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.showEvacuationCenters),
                        value: _showCenters,
                        onChanged: (value) {
                          setState(() => _showCenters = value);
                          setSheetState(() {});
                        },
                      ),
                      if (_showCenters && _availableStatuses.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Text(
                            l10n.centerStatusLayerLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        for (final status in _availableStatuses)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              localizedCenterStatus(sheetContext, status),
                            ),
                            value: !_excludedStatuses.contains(status),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _excludedStatuses.remove(status);
                                } else {
                                  _excludedStatuses.add(status);
                                }
                              });
                              setSheetState(() {});
                            },
                          ),
                      ],
                      const Divider(height: 28),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.showHazardAreas),
                        value: _showHazards,
                        onChanged: (value) {
                          setState(() => _showHazards = value);
                          setSheetState(() {});
                        },
                      ),
                      if (_showHazards && _availableHazardTypes.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Text(
                            l10n.hazardAreasLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        for (final type in _availableHazardTypes)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(hazardTypeLabel(sheetContext, type)),
                            value: !_excludedHazardTypes.contains(type),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _excludedHazardTypes.remove(type);
                                } else {
                                  _excludedHazardTypes.add(type);
                                }
                              });
                              setSheetState(() {});
                            },
                          ),
                      ],
                      const Divider(height: 28),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.showMyLocation),
                        value: _showMyLocation,
                        onChanged: (value) {
                          setState(() => _showMyLocation = value);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _resetFilters();
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: Text(l10n.resetFilters),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// The evacuation-center marker icon — a plain home icon normally, and
/// a ringed, slightly larger version when this is the currently
/// selected center (tapped, or reached via search). No animation: a
/// resident scanning the map benefits from an immediately-obvious state
/// change, not a transition to watch.
class _CenterMarkerIcon extends StatelessWidget {
  const _CenterMarkerIcon({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
        border: selected ? Border.all(color: color, width: 2.5) : null,
      ),
      child: Icon(Icons.home_work, color: color, size: selected ? 28 : 32),
    );
  }
}

/// Content of the evacuation-center bottom sheet — icon chip, name,
/// status badge, address, distance from the resident (when a current
/// position is known), occupancy (with the shared progress-bar
/// treatment [EvacuationCenterCard] also uses), available slots, and
/// Get Directions / Center Details actions.
class _CenterSheetContent extends ConsumerWidget {
  const _CenterSheetContent({
    required this.center,
    required this.accentColor,
    this.myPosition,
  });

  final EvacuationCenter center;
  final Color accentColor;
  final LatLng? myPosition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasOccupancy = center.hasOccupancyData;
    final position = myPosition;
    final distanceMeters = position != null && center.hasCoordinates
        ? DistanceCalculator.metersBetween(
            lat1: position.latitude,
            lon1: position.longitude,
            lat2: center.latitude!,
            lon2: center.longitude!,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompactCenterPhoto(centerId: center.id, photoUrl: center.photoUrl),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_work, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  center.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: localizedCenterStatus(context, center.status),
                color: accentColor,
                maxWidth: 110,
              ),
            ],
          ),
          if (center.displayLocation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              center.displayLocation,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (distanceMeters != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_walk,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  formatDistanceAway(distanceMeters),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (hasOccupancy) ...[
            const SizedBox(height: 14),
            OccupancyProgress(
              current: center.currentOccupancy!,
              capacity: center.capacityPersons,
              percent: center.occupancyPercent!,
              color: accentColor,
            ),
          ],
          if (center.availableSlots != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.overviewAvailableSlots}: ${center.availableSlots}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 18),
          // Hidden rather than disabled when there's no location to
          // navigate to, same reasoning as EvacuationCenterCard — the
          // neutral message below explains why, instead of an inert
          // button implying a temporary problem.
          if (center.hasCoordinates) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _handleGetDirections(context, center),
                icon: const Icon(Icons.directions_outlined),
                label: Text(l10n.getDirections),
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.centerMapLocationUnavailable,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/centers/${center.id}');
              },
              icon: const Icon(Icons.info_outline),
              label: Text(l10n.centerDetailsTitle),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _handleGetDirections(
    BuildContext context,
    EvacuationCenter center,
  ) async {
    if (!center.hasCoordinates) return;
    final opened = await openDirections(
      latitude: center.latitude!,
      longitude: center.longitude!,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).unableToOpenMaps)),
      );
    }
  }
}

/// A compact photo thumbnail for the selected-center bottom sheet —
/// same shared resolution pipeline `CenterPhotoCard` uses on Center
/// Details (`centerPhotoFileProvider`: network-first, cache-fallback,
/// offline-aware), just a smaller footprint suited to a sheet that
/// already has a lot else in it. Never a second downloader: this reads
/// from the exact same on-disk cache a prior Center Details visit (or
/// GIS fetch) already populated, and a fresh download here populates
/// that same cache for Center Details to reuse right back.
class _CompactCenterPhoto extends ConsumerWidget {
  const _CompactCenterPhoto({required this.centerId, required this.photoUrl});

  final int centerId;
  final String? photoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final url = photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: 96,
        child: url == null || url.isEmpty
            ? _CompactPhotoPlaceholder(theme: theme)
            : _CompactNetworkOrCachedPhoto(
                centerId: centerId,
                photoUrl: url,
                theme: theme,
              ),
      ),
    );
  }
}

class _CompactNetworkOrCachedPhoto extends ConsumerWidget {
  const _CompactNetworkOrCachedPhoto({
    required this.centerId,
    required this.photoUrl,
    required this.theme,
  });

  final int centerId;
  final String photoUrl;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileAsync = ref.watch(centerPhotoFileProvider(centerId, photoUrl));
    return fileAsync.when(
      data: (file) => file == null
          ? _CompactPhotoPlaceholder(theme: theme)
          : Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  _CompactPhotoPlaceholder(theme: theme),
            ),
      loading: () => Container(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stackTrace) => _CompactPhotoPlaceholder(theme: theme),
    );
  }
}

class _CompactPhotoPlaceholder extends StatelessWidget {
  const _CompactPhotoPlaceholder({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Icon(
        Icons.home_work_outlined,
        size: 26,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    required this.shape,
  });

  final Color color;
  final String label;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: shape == BoxShape.circle
              ? BoxDecoration(shape: BoxShape.circle, color: color)
              : BoxDecoration(
                  color: color.withValues(alpha: 0.35),
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(3),
                ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// A small blue dot with a white ring — the conventional "you are
/// here" marker, visually distinct from the home-icon evacuation
/// center markers so the two are never confused at a glance.
class _CurrentLocationDot extends StatelessWidget {
  const _CurrentLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4),
        ],
      ),
    );
  }
}
