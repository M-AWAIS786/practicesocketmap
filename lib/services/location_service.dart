import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _currentLocation;
  bool _isTracking = false;
  
  // Stream controller for location updates
  final StreamController<LocationData> _locationController = StreamController<LocationData>.broadcast();
  
  // Getters
  LocationData? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  Stream<LocationData> get locationStream => _locationController.stream;
  
  // Initialize location service
  Future<bool> initialize() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          log('Location service is not enabled');
          return false;
        }
      }

      // Check location permissions
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          log('Location permission not granted');
          return false;
        }
      }

      // Configure location settings
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 5000, // 5 seconds
        distanceFilter: 10, // 10 meters
      );

      log('LocationService initialized successfully');
      return true;
    } catch (e) {
      log('Error initializing LocationService: $e');
      return false;
    }
  }

  // Start location tracking
  Future<bool> startTracking() async {
    if (_isTracking) {
      log('Location tracking is already active');
      return true;
    }

    try {
      // Initialize if not already done
      bool initialized = await initialize();
      if (!initialized) {
        return false;
      }

      // Start listening to location changes
      _locationSubscription = _location.onLocationChanged.listen(
        (LocationData locationData) {
          _currentLocation = locationData;
          _locationController.add(locationData);
          log('Location updated: lat=${locationData.latitude}, lon=${locationData.longitude}');
        },
        onError: (error) {
          log('Location tracking error: $error');
        },
      );

      _isTracking = true;
      log('Location tracking started');
      return true;
    } catch (e) {
      log('Error starting location tracking: $e');
      return false;
    }
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) {
      log('Location tracking is not active');
      return;
    }

    try {
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      _isTracking = false;
      log('Location tracking stopped');
    } catch (e) {
      log('Error stopping location tracking: $e');
    }
  }

  // Get current location once
  Future<LocationData?> getCurrentLocation() async {
    try {
      bool initialized = await initialize();
      if (!initialized) {
        return null;
      }

      LocationData locationData = await _location.getLocation();
      _currentLocation = locationData;
      return locationData;
    } catch (e) {
      log('Error getting current location: $e');
      return null;
    }
  }

  // Check location permissions
  Future<bool> hasLocationPermission() async {
    try {
      PermissionStatus permissionGranted = await _location.hasPermission();
      return permissionGranted == PermissionStatus.granted;
    } catch (e) {
      log('Error checking location permission: $e');
      return false;
    }
  }

  // Request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      PermissionStatus permissionGranted = await _location.requestPermission();
      return permissionGranted == PermissionStatus.granted;
    } catch (e) {
      log('Error requesting location permission: $e');
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}

// Riverpod provider for LocationService

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});