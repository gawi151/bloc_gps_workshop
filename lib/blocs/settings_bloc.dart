import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../color_utils.dart';
import '../services/settings_service.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class ToggleMockGPS extends SettingsEvent {
  final bool useMockGPS;
  const ToggleMockGPS(this.useMockGPS);

  @override
  List<Object?> get props => [useMockGPS];
}

class ChangeMarkerColor extends SettingsEvent {
  final String colorName;
  const ChangeMarkerColor(this.colorName);

  @override
  List<Object?> get props => [colorName];
}


// Sealed class for SettingsState
sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

final class SettingsLoading extends SettingsState {
  const SettingsLoading();

  @override
  List<Object?> get props => [];
}

final class SettingsError extends SettingsState {
  final String errorMessage;

  const SettingsError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

final class SettingsData extends SettingsState {
  final bool useMockGPS;
  final String markerColorName;

  const SettingsData({
    required this.useMockGPS,
    required this.markerColorName,
  });

  Color get markerColor => getColorFromName(markerColorName);

  SettingsData copyWith({
    bool? useMockGPS,
    String? markerColorName,
  }) {
    return SettingsData(
      useMockGPS: useMockGPS ?? this.useMockGPS,
      markerColorName: markerColorName ?? this.markerColorName,
    );
  }

  @override
  List<Object?> get props => [useMockGPS, markerColorName];
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService settingsService;

  SettingsBloc({required this.settingsService}) : super(const SettingsLoading()) {
    on<LoadSettings>((event, emit) async {
      emit(const SettingsLoading());
      try {
        final useMock = await settingsService.loadUseMockGPS();
        final colorName = await settingsService.loadMarkerColor();
        emit(SettingsData(useMockGPS: useMock, markerColorName: colorName));
      } catch (e) {
        emit(SettingsError('Failed to load settings: $e'));
      }
    });

    on<ToggleMockGPS>((event, emit) async {
      final currentState = state;
      // Only modify state if we're currently in the data state
      if (currentState is SettingsData) {
        final updatedState = currentState.copyWith(useMockGPS: event.useMockGPS);
        emit(updatedState);
        // Persist the updated value
        await settingsService.saveUseMockGPS(event.useMockGPS);
      } else {
        // If we’re not in SettingsData, we could either do nothing or handle differently.
        // For now, we just ignore the toggle if we’re not in a data state.
      }
    });

    on<ChangeMarkerColor>((event, emit) async {
      final currentState = state;
      if (currentState is SettingsData) {
        final updatedState = currentState.copyWith(markerColorName: event.colorName);
        emit(updatedState);
        // Persist the updated value
        await settingsService.saveMarkerColor(event.colorName);
      } else {
        // Same reasoning as above, ignore or handle differently if not in data state.
      }
    });
  }
}

