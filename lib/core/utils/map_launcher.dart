import 'package:url_launcher/url_launcher.dart';

/// Opens the device's own maps/navigation app pre-filled with
/// [latitude]/[longitude] as the destination — always the evacuation
/// center's real coordinates, never a guessed address.
///
/// Tries the `geo:` URI first: on Android this is the platform's
/// generic "show this location" intent, which the OS resolves to
/// whichever maps apps the resident actually has installed (letting
/// them choose, rather than this app forcing one specific app). If
/// nothing on the device can handle that (most likely iOS, where
/// `geo:` isn't a registered scheme, or an Android device with no maps
/// app at all), falls back to the universal Google Maps web URL, which
/// opens the corresponding native app if one is registered as its
/// handler and otherwise degrades gracefully to a browser — still
/// works, just not a hardcoded requirement.
///
/// Returns false (rather than throwing) when neither path could be
/// opened, so the caller can show a friendly message instead of
/// crashing.
Future<bool> openDirections({
  required double latitude,
  required double longitude,
}) async {
  final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
  if (await canLaunchUrl(geoUri)) {
    return launchUrl(geoUri);
  }

  final webUri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
  );
  if (await canLaunchUrl(webUri)) {
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  return false;
}
