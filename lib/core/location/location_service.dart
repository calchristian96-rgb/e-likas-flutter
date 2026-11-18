import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../error/failure.dart';
import '../error/result.dart';

part 'location_service.g.dart';

/// Wraps geolocator's permission flow so every feature that needs the
/// resident's position asks the same way, once, instead of each screen
/// reimplementing the enabled/denied/deniedForever branching.
class LocationService {
  /// A fix this recent is used at once (the resident has not moved far).
  static const _recentEnough = Duration(minutes: 5);

  /// How long to wait for a fresh fix before using the last known one.
  static const _fixTimeLimit = Duration(seconds: 12);

  static Future<Position?> _lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

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

    final last = await _lastKnown();
    if (last != null &&
        DateTime.now().difference(last.timestamp) < _recentEnough) {
      return Success(last);
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: _fixTimeLimit),
      );
      return Success(position);
    } catch (_) {
      if (last != null) return Success(last);
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
