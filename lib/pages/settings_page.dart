import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/settings_bloc.dart';
import '../color_utils.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          // We have three states: SettingsLoading, SettingsError, and SettingsData.
          // We can handle them using a switch pattern (Dart 3):
          switch (state) {
            case SettingsLoading():
              return const Center(
                child: CircularProgressIndicator(),
              );
            case SettingsError(errorMessage: var error):
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Error: $error"),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Attempt to reload settings
                        bloc.add(LoadSettings());
                      },
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            case SettingsData(useMockGPS: var useMockGPS, markerColorName: var markerColorName):
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SwitchListTile(
                    title: const Text("Use Mock GPS"),
                    subtitle: const Text("Toggle between real and mock GPS data"),
                    value: useMockGPS,
                    onChanged: (value) {
                      bloc.add(ToggleMockGPS(value));
                    },
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text("Location Marker Color"),
                    subtitle: const Text("Select the color for the map marker"),
                    trailing: DropdownButton<String>(
                      value: markerColorName,
                      items: colorOptions.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: entry.value,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(entry.key),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newColorName) {
                        if (newColorName != null) {
                          bloc.add(ChangeMarkerColor(newColorName));
                        }
                      },
                    ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}
