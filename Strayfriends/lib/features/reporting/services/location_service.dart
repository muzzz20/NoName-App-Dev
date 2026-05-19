import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Device location wrapper.
///
/// Public surface:
/// - [getCurrentLocation]: one-shot fix, returns Firestore [GeoPoint].
/// - [ensurePermission]: idempotent permission flow (call before any
///   capture; throws [LocationFailure] if user denies).
///
/// AC: location accurate to within 50 m. We request [LocationAccuracy.high]
/// which is typically <20 m outdoors on modern phones.
class LocationService {
  /// Targeted desired accuracy (meters). Used as a soft filter — geolocator
  /// returns whatever the device provides.
  static const double targetAccuracyMeters = 50;

  /// Returns a [GeoPoint] for the device's current location.
  ///
  /// Flow:
  /// 1. Ensure location service is enabled (device-wide GPS toggle).
  /// 2. Ensure foreground permission is granted (request if denied).
  /// 3. Read one position with high accuracy + short timeout.
  Future<GeoPoint> getCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    await ensurePermission();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeout,
      ),
    );

    return GeoPoint(position.latitude, position.longitude);
  }

  /// Validate that location services are enabled and we have foreground
  /// permission. Throws [LocationFailure] with a friendly message otherwise.
  Future<void> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        'Location services are off. Turn on Location in your device settings.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Location permission denied. Pick a location manually on the map.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Location permission permanently denied. Enable it in app settings.',
      );
    }
  }

  /// Static helper to compute distance between two [GeoPoint]s in meters.
  /// Useful for the Feed's "near me" sort (Sprint 3).
  static double distanceMeters(GeoPoint a, GeoPoint b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }
}

class LocationFailure implements Exception {
  final String message;
  const LocationFailure(this.message);

  @override
  String toString() => message;
}
