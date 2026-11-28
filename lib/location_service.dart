import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

const defaultBatangasCenter = LatLng(13.8600, 121.0800);

enum LocationOutcome {
  ok,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationResult {
  final LatLng? point;
  final LocationOutcome outcome;
  const LocationResult(this.outcome, [this.point]);
}

Future<LocationResult> detectCurrentLocation() async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return const LocationResult(LocationOutcome.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult(LocationOutcome.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(LocationOutcome.permissionDeniedForever);
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return LocationResult(
      LocationOutcome.ok,
      LatLng(position.latitude, position.longitude),
    );
  } catch (_) {
    return const LocationResult(LocationOutcome.unavailable);
  }
}

double distanceKm(LatLng from, LatLng to) =>
    const Distance().as(LengthUnit.Kilometer, from, to);

Uri googleMapsDirectionsUri(double lat, double lng) => Uri.https(
  'www.google.com',
  '/maps/dir/',
  {'api': '1', 'destination': '$lat,$lng'},
);
