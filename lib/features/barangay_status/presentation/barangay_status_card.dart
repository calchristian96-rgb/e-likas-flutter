import 'package:flutter/material.dart';

import '../../../app/theme/sheet_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/barangay_status.dart';

/// The fill colours of the web map (backend map-api.md). Normal has no
/// fill on the map; on a card it is the success green.
/// The advice that goes with a status.
String whatToDo(AppLocalizations l10n, String status) => switch (status) {
  BarangayStatusKey.watch => l10n.adviceWatch,
  BarangayStatusKey.floodingReported => l10n.adviceFlooding,
  BarangayStatusKey.preemptiveEvacuation => l10n.advicePreemptive,
  BarangayStatusKey.forcedEvacuation => l10n.adviceForced,
  _ => l10n.adviceNormal,
};

Color barangayStatusColor(BuildContext context, String status) {
  return switch (status) {
    BarangayStatusKey.watch => Sheet.barangayWatch,
    BarangayStatusKey.floodingReported => Sheet.barangayFlooding,
    BarangayStatusKey.preemptiveEvacuation => Sheet.barangayPreemptive,
    BarangayStatusKey.forcedEvacuation => Sheet.barangayForced,
    _ => Sheet.centerActive,
  };
}
