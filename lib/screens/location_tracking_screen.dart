import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:practicesocketmap/provider/location_provider.dart';
import 'package:practicesocketmap/provider/socket_connect_provider.dart';
import 'package:practicesocketmap/services/driver_auth_service.dart';

class LocationTrackingScreen extends ConsumerStatefulWidget {
  const LocationTrackingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationTrackingScreen> createState() => _LocationTrackingScreenState();
}

class _LocationTrackingScreenState extends ConsumerState<LocationTrackingScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndInitialize();
    });
  }

  Future<void> _checkAuthAndInitialize() async {
    final authService = ref.read(driverAuthServiceProvider);
    await authService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final authService = ref.watch(driverAuthServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Authentication Status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authentication Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Logged In: ${authService.isLoggedIn}'),
                      Text('Driver ID: ${authService.driverId ?? "Not available"}'),
                      Text('Token: ${authService.token != null ? "Available" : "Not available"}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
          
              // Location Status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: locationState.when(
                    data: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Tracking: ${state.isTracking}'),
                        Text('Connected: ${state.isConnected}'),
                        if (state.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${state.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                        if (state.currentLocation != null) ...[
                          const SizedBox(height: 8),
                          Text('Latitude: ${state.currentLocation!.latitude?.toStringAsFixed(6)}'),
                          Text('Longitude: ${state.currentLocation!.longitude?.toStringAsFixed(6)}'),
                          Text('Accuracy: ${state.currentLocation!.accuracy?.toStringAsFixed(2)}m'),
                          if (state.currentLocation!.speed != null)
                            Text('Speed: ${state.currentLocation!.speed?.toStringAsFixed(2)}m/s'),
                        ],
                      ],
                    ),
                    loading: () => const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Loading location data...'),
                      ],
                    ),
                    error: (error, stack) => Column(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Error: $error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
          
              // Control Buttons
              if (!authService.isLoggedIn) ...[
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please login first to use location services'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Login Required'),
                ),
              ] else ...[
                // Permission Check Button
                ElevatedButton(
                  onPressed: () async {
                    final hasPermission = await ref.read(locationProvider.notifier).checkLocationPermission();
                    if (!hasPermission) {
                      final granted = await ref.read(locationProvider.notifier).requestLocationPermission();
                      if (granted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location permission granted'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location permission denied'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location permission already granted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Check/Request Location Permission'),
                ),
                const SizedBox(height: 12),
          
                // Get Current Location Button
                ElevatedButton(
                  onPressed: () {
                    ref.read(locationProvider.notifier).getCurrentLocation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Get Current Location'),
                ),
                const SizedBox(height: 12),
          
                // Start/Stop Tracking Buttons
                locationState.when(
                  data: (state) => state.isTracking
                      ? ElevatedButton(
                          onPressed: () {
                            ref.read(locationProvider.notifier).stopLocationTracking();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Stop Location Tracking'),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            ref.read(locationProvider.notifier).startLocationTracking();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Location Tracking'),
                        ),
                  loading: () => const ElevatedButton(
                    onPressed: null,
                    child: Text('Loading...'),
                  ),
                  error: (_, __) => ElevatedButton(
                    onPressed: () {
                      ref.read(locationProvider.notifier).startLocationTracking();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry Location Tracking'),
                  ),
                ),
                const SizedBox(height: 12),
          
                // Join Location Room Button
                ElevatedButton(
                  onPressed: () {
                    ref.read(locationProvider.notifier).joinLocationRoom(roomType: 'driver');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Join Location Room (Driver)'),
                ),
                const SizedBox(height: 12),
          
                // Manual Location Emit Button
                ElevatedButton(
                  onPressed: () {
                    // Example coordinates (you can replace with actual current location)
                    ref.read(locationProvider.notifier).emitLocationUpdate(40.7128, -74.0060);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Manual location update sent'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send Test Location Update'),
                ),
              ],
          
              const SizedBox(height: 24),
          
              // Clear Error Button
              locationState.when(
                data: (state) => state.error != null
                    ? ElevatedButton(
                        onPressed: () {
                          ref.read(locationProvider.notifier).clearError();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Clear Error'),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}