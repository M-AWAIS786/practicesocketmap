import 'dart:async';
import 'dart:developer';
import 'package:location/location.dart';
import 'package:practicesocketmap/services/web_sockets_service.dart';
import 'package:practicesocketmap/services/location_service.dart';

class LocationRepository {
  final _socketApiServices = SocketApiServices();
  final _locationService = LocationService();
  String? _currentUrl;
  StreamSubscription<LocationData>? _locationSubscription;
  String? _currentUserId;
  bool _isEmittingLocation = false;

  // Connect to socket and start emitting location updates
  Future<void> startLocationUpdates(String url, String token, String userId) async {
    try {
      log('Starting location updates for user: $userId');
      _currentUrl = url;
      _currentUserId = userId;
      
      // Connect to socket if not already connected
      await _socketApiServices.connect(url, token);
      
      // Start location tracking
      bool locationStarted = await _locationService.startTracking();
      if (!locationStarted) {
        throw Exception('Failed to start location tracking');
      }
      
      // Listen to location updates and emit to socket
      _locationSubscription = _locationService.locationStream.listen(
        (LocationData locationData) {
          _emitLocationUpdate(locationData);
        },
        onError: (error) {
          log('Location stream error: $error');
        },
      );
      
      // Listen for incoming location updates from other users/drivers
      _socketApiServices.on(url, 'location_update', (data) {
        _handleIncomingLocationUpdate(data);
      });
      
      _isEmittingLocation = true;
      log('Location updates started successfully');
    } catch (e) {
      log('Error starting location updates: $e');
      rethrow;
    }
  }

  // Stop location updates
  Future<void> stopLocationUpdates() async {
    try {
      log('Stopping location updates');
      
      // Cancel location subscription
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      
      // Stop location service
      await _locationService.stopTracking();
      
      _isEmittingLocation = false;
      log('Location updates stopped');
    } catch (e) {
      log('Error stopping location updates: $e');
    }
  }

  // Emit single location update
  void emitLocationUpdate(double latitude, double longitude, {String? userId}) {
    if (_currentUrl == null) {
      log('Socket not connected, cannot emit location');
      return;
    }
    
    final locationData = {
      'userId': userId ?? _currentUserId,
      'coordinates': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _socketApiServices.emit(_currentUrl!, 'location_update', locationData);
    log('Emitted location update: lat=$latitude, lon=$longitude for user: ${userId ?? _currentUserId}');
  }

  // Private method to emit location updates from location service
  void _emitLocationUpdate(LocationData locationData) {
    if (_currentUrl == null || _currentUserId == null) {
      log('Socket not connected or user ID not set');
      return;
    }
    
    if (locationData.latitude == null || locationData.longitude == null) {
      log('Invalid location data received');
      return;
    }
    
    final locationUpdateData = {
      'userId': _currentUserId,
      'coordinates': {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'accuracy': locationData.accuracy,
      'speed': locationData.speed,
      'heading': locationData.heading,
    };
    
    _socketApiServices.emit(_currentUrl!, 'location_update', locationUpdateData);
    log('Auto-emitted location update: lat=${locationData.latitude}, lon=${locationData.longitude}');
  }

  // Handle incoming location updates from other users
  void _handleIncomingLocationUpdate(dynamic data) {
    try {
      log('Received location update: $data');
      
      if (data is Map<String, dynamic>) {
        final userId = data['userId'];
        final coordinates = data['coordinates'];
        final userRole = data['userRole'] ?? 'unknown';
        
        if (coordinates != null && coordinates is Map<String, dynamic>) {
          final latitude = coordinates['latitude'];
          final longitude = coordinates['longitude'];
          
          log('$userRole location: lat=$latitude, lon=$longitude from user: $userId');
          
          // You can add callback here to notify UI about location updates
          // For example: _onLocationUpdateCallback?.call(data);
        }
      }
    } catch (e) {
      log('Error handling incoming location update: $e');
    }
  }

  // Join location room for receiving updates
  Future<void> joinLocationRoom(String url, String token, String userId, String roomType) async {
    try {
      log('Joining location room: $roomType for user: $userId');
      _currentUrl = url;
      _currentUserId = userId;
      
      await _socketApiServices.connect(url, token);
      _socketApiServices.emit(url, 'join_location_room', {
        'userId': userId,
        'roomType': roomType, // 'user' or 'driver'
      });
      
      // Listen for location updates
      _socketApiServices.on(url, 'location_update', (data) {
        _handleIncomingLocationUpdate(data);
      });
      
      log('Joined location room successfully');
    } catch (e) {
      log('Error joining location room: $e');
      rethrow;
    }
  }

  // Get current location once
  Future<LocationData?> getCurrentLocation() async {
    try {
      return await _locationService.getCurrentLocation();
    } catch (e) {
      log('Error getting current location: $e');
      return null;
    }
  }

  // Check if location updates are active
  bool get isEmittingLocation => _isEmittingLocation;
  
  // Check if location service is tracking
  bool get isLocationTracking => _locationService.isTracking;

  // Disconnect from socket
  void disconnect() {
    if (_currentUrl != null) {
      stopLocationUpdates();
      _socketApiServices.disconnect(_currentUrl!);
      _currentUrl = null;
      _currentUserId = null;
    }
  }

  // Dispose resources
  void dispose() {
    disconnect();
  }
}