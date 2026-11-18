import 'package:flutter/material.dart';

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
    BarangayStatusKey.watch => const Color(0xFFFACC15),
    BarangayStatusKey.floodingReported => const Color(0xFFF97316),
    BarangayStatusKey.preemptiveEvacuation => const Color(0xFFDC2626),
    BarangayStatusKey.forcedEvacuation => const Color(0xFF7F1D1D),
    _ => const Color(0xFF15803D),
  };
}
