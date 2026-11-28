import '../../../app/theme/sheet_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../data/barangay_outlines.dart';
import '../domain/barangay_status.dart';
import 'barangay_status_card.dart';

/// Barangay outlines filled by status, at 50% like the web map; a
/// normal barangay is a plain outline. The resident's own barangay has
/// a thicker ink border. Each polygon's [Polygon.hitValue] is
/// its status row, for tap-to-read.
List<Polygon<BarangayStatus>> buildBarangayStatusPolygons({
  required BuildContext context,
  required List<BarangayOutline> outlines,
  required BarangayStatusBoard? board,
  int? ownBarangayId,
}) {
  final byPsgc = {
    for (final b in board?.barangays ?? const <BarangayStatus>[])
      if (b.psgcCode != null) b.psgcCode!: b,
  };
  final outlineColor = Theme.of(context).colorScheme.onSurfaceVariant;
  // The resident's own barangay, ruled in ink (the map is light in both
  // themes; sienna is kept for actions).
  const brand = Sheet.ink;
  return [
    for (final o in outlines)
      () {
        final status = byPsgc[o.psgcCode];
        final own = status != null && status.id == ownBarangayId;
        final fill = status == null || status.isNormal
            ? null
            : barangayStatusColor(
                context,
                status.status,
              ).withValues(alpha: 0.5);
        return Polygon<BarangayStatus>(
          points: o.rings.first,
          holePointsList: o.rings.length > 1 ? o.rings.sublist(1) : null,
          color: fill,
          borderColor: own ? brand : outlineColor.withValues(alpha: 0.6),
          borderStrokeWidth: own ? 3 : 1,
          hitValue:
              status ??
              BarangayStatus(
                id: -1,
                name: o.name,
                psgcCode: o.psgcCode,
                status: BarangayStatusKey.normal,
                label: 'Normal',
              ),
        );
      }(),
  ];
}
