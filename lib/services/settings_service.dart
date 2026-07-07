import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyUseMockGPS = 'useMockGPS';
  static const _keyMarkerColor = 'markerColor';

  Future<void> saveUseMockGPS(bool useMockGPS) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseMockGPS, useMockGPS);
  }

  Future<bool> loadUseMockGPS() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseMockGPS) ?? false;
  }

  Future<void> saveMarkerColor(String colorName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMarkerColor, colorName);
  }

  Future<String> loadMarkerColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMarkerColor) ?? 'Red';
  }
}
