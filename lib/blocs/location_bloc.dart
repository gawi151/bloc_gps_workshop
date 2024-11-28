import 'dart:async';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';

// Events
abstract class LocationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartTracking extends LocationEvent {}

class StopTracking extends LocationEvent {}

class LocationUpdated extends LocationEvent {
  final LocationModel location;
  LocationUpdated(this.location);

  @override
  List<Object?> get props => [location];
}

// State
class LocationState extends Equatable {
  final List<LocationModel> locations;
  final bool isTracking;
  final String? error;

  const LocationState({
    this.locations = const [],
    this.isTracking = false,
    this.error,
  });

  LocationState copyWith({
    List<LocationModel>? locations,
    bool? isTracking,
    String? error,
  }) {
    return LocationState(
      locations: locations ?? this.locations,
      isTracking: isTracking ?? this.isTracking,
      error: error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locations': locations.map((l) => l.toJson()).toList(),
      'isTracking': isTracking,
    };
  }

  factory LocationState.fromJson(Map<String, dynamic> json) {
    return LocationState(
      locations: (json['locations'] as List)
          .map((l) => LocationModel.fromJson(l as Map<String, dynamic>))
          .toList(),
      isTracking: json['isTracking'] as bool,
    );
  }

  @override
  List<Object?> get props => [locations, isTracking, error];
}

// Bloc
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationService locationService;
  StreamSubscription<LocationModel>? _locationSubscription;

  LocationBloc({
    required this.locationService,
  }) : super(const LocationState()) {
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<LocationUpdated>(_onLocationUpdated);
  }

  Future<void> _onStartTracking(
      StartTracking event, Emitter<LocationState> emit) async {
    try {
      await locationService.checkAndRequestPermissions();

      _locationSubscription?.cancel();
      _locationSubscription = null;

      final stream = locationService.getLocationStream();
      await locationService.startTracking();

      _locationSubscription = stream.listen(
        (location) => add(LocationUpdated(location)),
        onError: (error) {
          add(StopTracking());
          emit(state.copyWith(error: error.toString()));
        },
      );

      emit(state.copyWith(isTracking: true, error: null));
    } catch (e) {
      emit(state.copyWith(isTracking: false, error: e.toString()));
    }
  }

  Future<void> _onStopTracking(
      StopTracking event, Emitter<LocationState> emit) async {
    try {
      await locationService.stopTracking();
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      emit(state.copyWith(isTracking: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onLocationUpdated(LocationUpdated event, Emitter<LocationState> emit) {
    final updatedLocations = List<LocationModel>.from(state.locations)
      ..add(event.location);
    emit(state.copyWith(locations: updatedLocations));
  }

  @override
  Future<void> close() async {
    await locationService.stopTracking();
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    return super.close();
  }

  @override
  LocationState? fromJson(Map<String, dynamic> json) {
    return LocationState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(LocationState state) {
    return state.toJson();
  }
}
