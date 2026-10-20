import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../l10n/app_localizations.dart';
import 'map_base_layer.dart';

/// One class (legend entry) of a susceptibility overlay. [label] is the
/// WMS service's own wording, deliberately not localized — it must read
/// the same as on the service and on the web map.
class HazardOverlayClass {
  const HazardOverlayClass(this.label, this.color);

  final String label;
  final Color color;
}

/// An ONLINE-ONLY hazard susceptibility layer served as WMS by GeoRiskPH.
/// Display only: nothing here is stored, cached or read back by the app.
/// Same values as the web module `hazard-overlays.js`.
class HazardOverlay {
  const HazardOverlay({
    required this.id,
    required this.wmsBaseUrl,
    required this.layers,
    required this.classes,
  });

  final String id;

  /// Ends with `?`, as `WMSTileLayerOptions.baseUrl` requires.
  final String wmsBaseUrl;
  final List<String> layers;
  final List<HazardOverlayClass> classes;
}

const hazardOverlayWmsRoot =
    'https://ulap-hazards.georisk.gov.ph/arcgis/services';
const hazardOverlayAttributionUrl = 'https://georisk.gov.ph/';

/// Tuned on the web: 0.6 hides the Low class, 0.8 hides street labels.
const hazardOverlayOpacity = 0.7;

const hazardOverlayFlood = HazardOverlay(
  id: 'flood',
  wmsBaseUrl: '$hazardOverlayWmsRoot/MGBPublic/Flood/MapServer/WMSServer?',
  layers: ['0'],
  classes: [
    HazardOverlayClass('Very High Susceptibility', Color(0xFF002673)),
    HazardOverlayClass('High Susceptibility', Color(0xFF5900FF)),
    HazardOverlayClass('Moderate Susceptibility', Color(0xFFB045FF)),
    HazardOverlayClass('Low Susceptibility', Color(0xFFE3D1FF)),
  ],
);

const hazardOverlayLandslide = HazardOverlay(
  id: 'landslide',
  wmsBaseUrl:
      '$hazardOverlayWmsRoot/MGBPublic/RainInducedLandslide/MapServer/WMSServer?',
  layers: ['0'],
  classes: [
    HazardOverlayClass('Very High Susceptibility', Color(0xFF902400)),
    HazardOverlayClass('High Susceptibility', Color(0xFFFF0000)),
    HazardOverlayClass('Moderate Susceptibility', Color(0xFF008000)),
    HazardOverlayClass('Low Susceptibility', Color(0xFFFFFF00)),
    HazardOverlayClass(
      'Debris Flow/Possible Accumulation Zone',
      Color(0xFF000000),
    ),
  ],
);

/// In display order.
const hazardOverlays = [hazardOverlayFlood, hazardOverlayLandslide];

String hazardOverlayName(AppLocalizations l10n, HazardOverlay overlay) =>
    switch (overlay.id) {
      'flood' => l10n.hazardOverlayFloodName,
      _ => l10n.hazardOverlayLandslideName,
    };

String hazardOverlayNote(AppLocalizations l10n, HazardOverlay overlay) =>
    switch (overlay.id) {
      'flood' => l10n.hazardOverlayFloodNote,
      _ => l10n.hazardOverlayLandslideNote,
    };

/// Attribution for the overlays in [activeIds] — both share one source,
/// so it's listed once.
List<MapOverlayAttribution> hazardOverlayAttributions(
  AppLocalizations l10n,
  Set<String> activeIds,
) {
  if (!hazardOverlays.any((o) => activeIds.contains(o.id))) return const [];
  return [
    MapOverlayAttribution(
      text: l10n.hazardOverlayAttribution,
      url: hazardOverlayAttributionUrl,
    ),
  ];
}

/// The overlay's `TileLayer`, wrapped in an [Opacity] — the package's
/// documented way to get constant transparency (per-tile opacity would
/// double-darken while zooming). It sits in the `FlutterMap` children
/// below the polygons/markers and has no tap handling of its own.
///
/// Give it a new [key] to re-create the layer (a retry). [onTileError]
/// is called for every tile that fails to load; it must not throw.
Widget buildHazardOverlayLayer(
  HazardOverlay overlay, {
  Key? key,
  VoidCallback? onTileError,
}) {
  return Opacity(
    key: key,
    opacity: hazardOverlayOpacity,
    child: TileLayer(
      wmsOptions: WMSTileLayerOptions(
        baseUrl: overlay.wmsBaseUrl,
        layers: overlay.layers,
        version: '1.3.0',
      ),
      userAgentPackageName: 'com.cswdo.elikas_mobile',
      evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
      errorTileCallback: (tile, error, stackTrace) => onTileError?.call(),
    ),
  );
}

/// Counts tile load errors for one overlay: [threshold] errors within any
/// [window] mark it failed. Stays failed until [reset] — flutter_map
/// reports no per-tile success, so there is nothing to clear it with.
class TileFailureTracker {
  TileFailureTracker({
    this.threshold = 4,
    this.window = const Duration(seconds: 10),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int threshold;
  final Duration window;
  final DateTime Function() _clock;
  final List<DateTime> _errors = [];
  bool _failed = false;

  bool get failed => _failed;

  /// Records one error; returns true only on the transition to failed.
  bool recordError() {
    if (_failed) return false;
    final now = _clock();
    _errors.add(now);
    _errors.removeWhere((t) => now.difference(t) > window);
    if (_errors.length >= threshold) {
      _failed = true;
      _errors.clear();
      return true;
    }
    return false;
  }

  void reset() {
    _errors.clear();
    _failed = false;
  }
}

/// The "could not be loaded" line — one calm line, no popup.
class _FailedLine extends StatelessWidget {
  const _FailedLine({required this.overlay});

  final HazardOverlay overlay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        l10n.hazardOverlayLoadFailed(hazardOverlayName(l10n, overlay)),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// The Layers-sheet section: one independent switch per overlay, each
/// showing its note while on (plus the failure line if it failed), and
/// one static online-only notice. The caller does the `setState` /
/// `setSheetState` pair in [onChanged].
class HazardOverlaySection extends StatelessWidget {
  const HazardOverlaySection({
    super.key,
    required this.activeIds,
    required this.failedIds,
    required this.onChanged,
  });

  final Set<String> activeIds;
  final ValueListenable<Set<String>> failedIds;
  final void Function(HazardOverlay overlay, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.hazardOverlaysSectionTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        for (final overlay in hazardOverlays) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(hazardOverlayName(l10n, overlay)),
            value: activeIds.contains(overlay.id),
            onChanged: (value) => onChanged(overlay, value),
          ),
          if (activeIds.contains(overlay.id)) ...[
            Text(hazardOverlayNote(l10n, overlay), style: muted),
            ValueListenableBuilder<Set<String>>(
              valueListenable: failedIds,
              builder: (context, failed, _) => failed.contains(overlay.id)
                  ? _FailedLine(overlay: overlay)
                  : const SizedBox.shrink(),
            ),
          ],
        ],
        const SizedBox(height: 6),
        Text(l10n.hazardOverlaysOnlineNotice, style: muted),
      ],
    );
  }
}

/// Legend sections for the overlays in [activeIds]: class swatches at the
/// same opacity as on the map, the note, and the failure line if any.
/// Renders nothing when no overlay is active.
class HazardOverlayLegendSections extends StatelessWidget {
  const HazardOverlayLegendSections({
    super.key,
    required this.activeIds,
    required this.failedIds,
  });

  final Set<String> activeIds;
  final ValueListenable<Set<String>> failedIds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final overlay in hazardOverlays)
          if (activeIds.contains(overlay.id)) ...[
            Text(
              hazardOverlayName(l10n, overlay),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (final c in overlay.classes)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: c.color.withValues(
                            alpha: hazardOverlayOpacity,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(c.label, style: theme.textTheme.bodySmall),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hazardOverlayNote(l10n, overlay),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            ValueListenableBuilder<Set<String>>(
              valueListenable: failedIds,
              builder: (context, failed, _) => failed.contains(overlay.id)
                  ? _FailedLine(overlay: overlay)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 18),
          ],
      ],
    );
  }
}
