import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    _currentService = _gpsService;
    _createBloc();
  }

  void _createBloc() {
    _bloc?.close(); // Close existing bloc if any
    _bloc = LocationBloc(locationService: _currentService);
  }

  void _toggleService() async {
    // Stop tracking if currently tracking
    if (_bloc?.state.isTracking ?? false) {
      _bloc?.add( StopTracking());
      // Wait a bit for the tracking to stop
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
          actions: [
            IconButton(
              icon: Icon(_currentService is GpsLocationService
                  ? Icons.gps_fixed
                  : Icons.route),
              onPressed: _toggleService,
              tooltip: _currentService is GpsLocationService
                  ? 'Switch to Mock GPS'
                  : 'Switch to Real GPS',
            ),
          ],
        ),
        body: const LocationTrackerView(),
      ),
    );
  }
}

class LocationTrackerView extends StatelessWidget {
  const LocationTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        context.read<LocationBloc>().add(state.isTracking
                            ? StopTracking()
                            : StartTracking());
                      },
                      child: Text(state.isTracking
                          ? 'Stop Tracking'
                          : 'Start Tracking'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LocationsList(locations: state.locations),
              ),
            ],
          );
        },
      ),
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
