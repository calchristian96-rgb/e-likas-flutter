import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../error/failure.dart';
import '../error/result.dart';

part 'location_service.g.dart';

/// Wraps geolocator's permission flow so every feature that needs the
/// resident's position asks the same way, once, instead of each screen
/// reimplementing the enabled/denied/deniedForever branching.
class LocationService {
  Future<Result<Position>> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const Failed(
        LocationFailure(
          'Location services are turned off.',
          false,
          LocationFailureReason.servicesDisabled,
        ),
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const Failed(
          LocationFailure(
            'Location permission was denied.',
            false,
            LocationFailureReason.permissionDenied,
          ),
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const Failed(
        LocationFailure(
          'Location permission is permanently denied — enable it in system settings.',
          true,
          LocationFailureReason.permanentlyDenied,
        ),
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      return Success(position);
    } catch (_) {
      return const Failed(
        LocationFailure(
          'Could not determine current location.',
          false,
          LocationFailureReason.positionUnavailable,
        ),
      );
    }
  }
}

@riverpod
LocationService locationService(Ref ref) => LocationService();
