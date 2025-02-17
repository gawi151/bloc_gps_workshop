import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../blocs/location_bloc.dart';
import '../models/location_model.dart';
import '../services/gps_location_service.dart';
import '../services/location_service.dart';
import '../services/mock_location_service.dart';

class LocationTrackerPage extends StatefulWidget {
  const LocationTrackerPage({super.key});

  @override
  State<LocationTrackerPage> createState() => _LocationTrackerPageState();
}

class _LocationTrackerPageState extends State<LocationTrackerPage> {
  late final GpsLocationService _gpsService;
  late final MockLocationService _mockService;
  late LocationService _currentService;
  LocationBloc? _bloc;

  @override
  void initState() {
    super.initState();
    _gpsService = GpsLocationService();
    _mockService = MockLocationService();
    _currentService = _mockService;
    _createBloc();
  }

  void _createBloc() {
    _bloc?.close();
    _bloc = LocationBloc(locationService: _currentService);
  }

  Future<void> _toggleService() async {
    if (_bloc?.state.isTracking ?? false) {
      _bloc?.add(StopTracking());
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() {
      _currentService =
          _currentService is GpsLocationService ? _mockService : _gpsService;
      _createBloc();
    });
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc!,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Location History Tracker'),
        ),
        body: LocationTrackerView(
          isUsingGps: _currentService is GpsLocationService,
          onServiceToggle: _toggleService,
        ),
      ),
    );
  }
}

class LocationTrackerView extends StatefulWidget {
  final bool isUsingGps;
  final VoidCallback onServiceToggle;

  const LocationTrackerView({
    super.key,
    required this.isUsingGps,
    required this.onServiceToggle,
  });

  @override
  State<LocationTrackerView> createState() => _LocationTrackerViewState();
}

class _LocationTrackerViewState extends State<LocationTrackerView> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _moveToCurrentLocation(List<LocationModel> locations) {
    if (locations.isNotEmpty) {
      final currentLocation = locations.last;
      _mapController.move(
        LatLng(currentLocation.latitude, currentLocation.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<LocationBloc>().add(state.isTracking
                              ? StopTracking()
                              : StartTracking());
                        },
                        icon: Icon(
                          state.isTracking ? Icons.stop : Icons.play_arrow,
                        ),
                        label: Text(state.isTracking
                            ? 'Stop Tracking'
                            : 'Start Tracking'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: widget.onServiceToggle,
                        icon: Icon(
                          widget.isUsingGps ? Icons.gps_fixed : Icons.route,
                        ),
                        label: Text(
                          widget.isUsingGps
                              ? 'Switch to Mock'
                              : 'Switch to GPS',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Stack(
                          children: [
                            _buildMap(state.locations),
                            if (state.locations.isNotEmpty)
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: FloatingActionButton(
                                  onPressed: () =>
                                      _moveToCurrentLocation(state.locations),
                                  child: const Icon(Icons.my_location),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: LocationsList(locations: state.locations),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMap(List<LocationModel> locations) {
    if (locations.isEmpty) {
      return FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: wroclaw,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.bloc_gps_workshop',
            maxZoom: 19,
          ),
          const MarkerLayer(
            markers: [
              Marker(
                point: wroclaw,
                child: Icon(
                  Icons.location_city,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final currentLocation = locations.last;
    final points =
        locations.map((loc) => LatLng(loc.latitude, loc.longitude)).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter:
            LatLng(currentLocation.latitude, currentLocation.longitude),
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.bloc_gps_workshop',
          maxZoom: 19,
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              color: Colors.blue.withOpacity(0.7),
              strokeWidth: 3,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point:
                  LatLng(currentLocation.latitude, currentLocation.longitude),
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
            ...locations.take(locations.length - 1).map(
                  (loc) => Marker(
                    point: LatLng(loc.latitude, loc.longitude),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class LocationsList extends StatelessWidget {
  final List<LocationModel> locations;

  const LocationsList({super.key, required this.locations});

  String _formatCoordinates(LocationModel location) {
    return '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coordinates copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        final coordinates = _formatCoordinates(location);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: SelectableText(coordinates),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(context, coordinates),
                  tooltip: 'Copy coordinates',
                ),
              ],
            ),
            subtitle: Text(location.timestamp.toString()),
          ),
        );
      },
    );
  }
}

const LatLng wroclaw = LatLng(51.1079, 17.0385);
