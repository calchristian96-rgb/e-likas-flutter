import 'package:url_launcher/url_launcher.dart';

/// Hands the trip to Google Maps (the app when installed, else the
/// browser): directions to [latitude]/[longitude] when the center has a
/// location, otherwise a search for [placeQuery] (its name, barangay and
/// city), since most centers have no map location yet.
///
/// Uses the documented Google Maps URLs (`/maps/dir/?api=1` and
/// `/maps/search/?api=1`), which Android hands to the Google Maps app.
/// Returns false, never throws, when nothing could open it.
Future<bool> openDirections({
  double? latitude,
  double? longitude,
  String? placeQuery,
}) async {
  final Uri uri;
  if (latitude != null && longitude != null) {
    uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
    });
  } else if (placeQuery != null && placeQuery.trim().isNotEmpty) {
    uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': placeQuery,
    });
  } else {
    return false;
  }
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// The search text for a center with no location.
String centerPlaceQuery(String name, String? barangay) => [
  name,
  if (barangay != null && barangay.isNotEmpty) barangay,
  'Ligao City, Albay',
].join(', ');
