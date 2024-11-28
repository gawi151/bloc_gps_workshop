import 'dart:async';
import '../models/location_model.dart';

abstract interface class LocationService {
  Stream<LocationModel> getLocationStream();
  Future<void> startTracking();
  Future<void> stopTracking();
  Future<bool> checkAndRequestPermissions();
}