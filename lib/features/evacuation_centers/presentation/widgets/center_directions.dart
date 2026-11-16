import 'package:flutter/material.dart';

import '../../../../core/utils/map_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/evacuation_center.dart';

/// Get Directions for one center, in Google Maps; a short message when
/// no app or browser could open it.
Future<void> openCenterDirections(
  BuildContext context,
  EvacuationCenter center,
) async {
  final opened = await openDirections(
    latitude: center.latitude,
    longitude: center.longitude,
    placeQuery: centerPlaceQuery(center.name, center.barangay),
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).unableToOpenMaps)),
    );
  }
}
