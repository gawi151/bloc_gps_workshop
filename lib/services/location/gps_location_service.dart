import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../models/location_model.dart';
import 'location_service.dart';

class GpsLocationService implements LocationService {
  StreamController<LocationModel>? _locationController;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;

  @override
  Stream<LocationModel> getLocationStream() {
    _locationController ??= StreamController<LocationModel>.broadcast();
    return _locationController!.stream;
  }

  @override
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return true;
  }

  @override
  Future<void> startTracking() async {
    if (_isTracking) return;

    await checkAndRequestPermissions();

    try {
      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // minimum change (in meters) before update
        ),
      ).listen(
        (Position position) {
          if (_locationController?.isClosed ?? true) return;

          _locationController?.add(LocationModel(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
          ));
        },
        onError: (error) {
          _locationController?.addError(error);
        },
      );

      _isTracking = true;
    } catch (e) {
      _isTracking = false;
      rethrow;
    }
  }

  @override
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }
}
