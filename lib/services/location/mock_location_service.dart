import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/location_model.dart';
import 'location_service.dart';

class MockLocationService implements LocationService {
  StreamController<LocationModel>? _locationController;
  Timer? _timer;
  List<LocationModel> _mockRoute = [];
  int _currentIndex = 0;

  Future<void> loadMockRoute(String filePath) async {
    final jsonString = await rootBundle.loadString(filePath);
    final List<dynamic> jsonList = json.decode(jsonString);

    _mockRoute = jsonList.map((json) => LocationModel.fromJson(json)).toList();
    _currentIndex = 0;
  }

  @override
  Stream<LocationModel> getLocationStream() {
    _locationController ??= StreamController<LocationModel>.broadcast();
    return _locationController!.stream;
  }

  @override
  Future<void> startTracking() async {
    if (_mockRoute.isEmpty) {
      await loadMockRoute('assets/mock_routes/sample_route.json');
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_locationController?.isClosed ?? true) {
        timer.cancel();
        return;
      }

      if (_currentIndex >= _mockRoute.length) {
        _currentIndex = 0; // Loop the route
      }

      _locationController?.add(_mockRoute[_currentIndex]);
      _currentIndex++;
    });
  }

  @override
  Future<void> stopTracking() async {
    _timer?.cancel();
    _currentIndex = 0;
  }

  @override
  Future<bool> checkAndRequestPermissions() async {
    // Mock implementation always returns true as it doesn't need real permissions
    return true;
  }
}
