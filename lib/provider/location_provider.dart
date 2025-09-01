import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:practicesocketmap/provider/socket_connect_provider.dart';
import 'package:practicesocketmap/repository/location_repo.dart';
import 'package:practicesocketmap/services/app_exceptions.dart';
import 'package:practicesocketmap/services/driver_auth_service.dart';
import 'package:practicesocketmap/services/location_service.dart';

// Location state model
class LocationState {
  final LocationData? currentLocation;
  final bool isTracking;
  final bool isConnected;
  final String? error;
  final List<Map<String, dynamic>> nearbyUsers;

  const LocationState({
    this.currentLocation,
    this.isTracking = false,
    this.isConnected = false,
    this.error,
    this.nearbyUsers = const [],
  });

  LocationState copyWith({
    LocationData? currentLocation,
    bool? isTracking,
    bool? isConnected,
    String? error,
    List<Map<String, dynamic>>? nearbyUsers,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      isTracking: isTracking ?? this.isTracking,
      isConnected: isConnected ?? this.isConnected,
      error: error,
      nearbyUsers: nearbyUsers ?? this.nearbyUsers,
    );
  }
}

// Location provider
final locationProvider = StateNotifierProvider<LocationNotifier, AsyncValue<LocationState>>((ref) {
  return LocationNotifier(ref);
});

class LocationNotifier extends StateNotifier<AsyncValue<LocationState>> {
  final Ref _ref;
  final _locationRepo = LocationRepository();
  final _locationService = LocationService();

  LocationNotifier(this._ref) : super(const AsyncData(LocationState())) {
    _initializeLocationService();
  }

  // Initialize location service
  Future<void> _initializeLocationService() async {
    try {
      await _locationService.initialize();
    } catch (e) {
      log('Error initializing location service: $e');
    }
  }

  // Start location tracking and socket connection
  Future<void> startLocationTracking() async {
    state = AsyncLoading();
    try {
      final authService = _ref.read(driverAuthServiceProvider);
      final token = authService.token;
      final userId = authService.driverId;
      
      if (token == null || userId == null) {
        throw FetchDataException('Not authenticated');
      }

      // Start location updates with socket connection
      await _locationRepo.startLocationUpdates(
        'http://159.198.74.112:3001',
        token,
        userId,
      );

      // Get current location
      final currentLocation = await _locationService.getCurrentLocation();
      
      state = AsyncData(LocationState(
        currentLocation: currentLocation,
        isTracking: true,
        isConnected: true,
      ));
      
      log('Location tracking started successfully');
    } catch (e, stack) {
      log('Error starting location tracking: $e');
      state = AsyncError(e, stack);
    }
  }

  // Stop location tracking
  Future<void> stopLocationTracking() async {
    try {
      await _locationRepo.stopLocationUpdates();
      
      final currentState = state.value ?? const LocationState();
      state = AsyncData(currentState.copyWith(
        isTracking: false,
        isConnected: false,
      ));
      
      log('Location tracking stopped');
    } catch (e) {
      log('Error stopping location tracking: $e');
      final currentState = state.value ?? const LocationState();
      state = AsyncData(currentState.copyWith(
        error: 'Failed to stop location tracking: $e',
      ));
    }
  }

  // Join location room for receiving updates from other users
  Future<void> joinLocationRoom({String roomType = 'driver'}) async {
    try {
      final authService = _ref.read(driverAuthServiceProvider);
      final token = authService.token;
      final userId = authService.driverId;
      
      if (token == null || userId == null) {
        throw FetchDataException('Not authenticated');
      }

      await _locationRepo.joinLocationRoom(
        'http://159.198.74.112:3001',
        token,
        userId,
        roomType,
      );
      
      final currentState = state.value ?? const LocationState();
      state = AsyncData(currentState.copyWith(isConnected: true));
      
      log('Joined location room as $roomType');
    } catch (e, stack) {
      log('Error joining location room: $e');
      state = AsyncError(e, stack);
    }
  }

  // Emit single location update
  void emitLocationUpdate(double latitude, double longitude) {
    try {
      _locationRepo.emitLocationUpdate(latitude, longitude);
      
      // Update current location in state
      final locationData = LocationData.fromMap({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toDouble(),
      });
      
      final currentState = state.value ?? const LocationState();
      state = AsyncData(currentState.copyWith(
        currentLocation: locationData,
      ));
      
      log('Location update emitted: lat=$latitude, lon=$longitude');
    } catch (e) {
      log('Error emitting location update: $e');
      final currentState = state.value ?? const LocationState();
      state = AsyncData(currentState.copyWith(
        error: 'Failed to emit location: $e',
      ));
    }
  }

  // Get current location once
  Future<void> getCurrentLocation() async {
    try {
      final locationData = await _locationRepo.getCurrentLocation();
      
      final currentState = state.value ?? const LocationState();
      state = AsyncData(currentState.copyWith(
        currentLocation: locationData,
      ));
      
      if (locationData != null) {
        log('Current location: lat=${locationData.latitude}, lon=${locationData.longitude}');
      }
    } catch (e) {
      log('Error getting current location: $e');
      final currentState = state.value ?? const LocationState();
      state = AsyncData(currentState.copyWith(
        error: 'Failed to get location: $e',
      ));
    }
  }

  // Check location permissions
  Future<bool> checkLocationPermission() async {
    try {
      return await _locationService.hasLocationPermission();
    } catch (e) {
      log('Error checking location permission: $e');
      return false;
    }
  }

  // Request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      return await _locationService.requestLocationPermission();
    } catch (e) {
      log('Error requesting location permission: $e');
      return false;
    }
  }

  // Clear error state
  void clearError() {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncData(currentState.copyWith(error: null));
    }
  }

  // Check if location tracking is active
  bool get isLocationTracking => _locationRepo.isLocationTracking;
  
  // Check if socket is emitting location
  bool get isEmittingLocation => _locationRepo.isEmittingLocation;

  // Disconnect and cleanup
  void disconnect() {
    _locationRepo.disconnect();
    final currentState = state.value ?? const LocationState();
    state = AsyncData(currentState.copyWith(
      isTracking: false,
      isConnected: false,
    ));
  }

  @override
  void dispose() {
    disconnect();
    _locationRepo.dispose();
    super.dispose();
  }
}

// Convenience providers
final currentLocationProvider = Provider<LocationData?>((ref) {
  final locationState = ref.watch(locationProvider);
  return locationState.value?.currentLocation;
});

final isLocationTrackingProvider = Provider<bool>((ref) {
  final locationState = ref.watch(locationProvider);
  return locationState.value?.isTracking ?? false;
});

final isLocationConnectedProvider = Provider<bool>((ref) {
  final locationState = ref.watch(locationProvider);
  return locationState.value?.isConnected ?? false;
});