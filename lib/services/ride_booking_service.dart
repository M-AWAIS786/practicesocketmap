import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class RideBookingService {
  static const String baseUrl = 'http://159.198.74.112:3001';
  static const String apiUrl = '$baseUrl/api';
  
  // Authentication credentials from user
  static const String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4YWFjMjNjOTc4NDUwYjdjZTQ5NjMyZiIsImlhdCI6MTc1NjA0OTYyNSwiZXhwIjoxNzU4NjQxNjI1fQ.IvUCEXC6Pf1KKnNqedYxnZDENIKPW0WRfH_ChSmqgpo';
  static const String userId = '68aac23c978450b7ce49632f';
  static const String username = 'ali1';
  static const String sponsorId = '61e8f9b9-308441';
  
  late IO.Socket socket;
  bool isConnected = false;
  
  // Stream controllers for real-time updates
  final StreamController<Map<String, dynamic>> _driverAcceptedController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _rideStatusController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _locationUpdateController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _bookingErrorController = StreamController.broadcast();
  final StreamController<String> _connectionStatusController = StreamController.broadcast();
  final StreamController<List<Map<String, dynamic>>> _driversLocationController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _newBookingRequestController = StreamController.broadcast();
  
  // Getters for streams
  Stream<Map<String, dynamic>> get driverAcceptedStream => _driverAcceptedController.stream;
  Stream<Map<String, dynamic>> get rideStatusStream => _rideStatusController.stream;
  Stream<Map<String, dynamic>> get locationUpdateStream => _locationUpdateController.stream;
  Stream<Map<String, dynamic>> get bookingErrorStream => _bookingErrorController.stream;
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;
  Stream<List<Map<String, dynamic>>> get driversLocationStream => _driversLocationController.stream;
  Stream<Map<String, dynamic>> get newBookingRequestStream => _newBookingRequestController.stream;
  
  RideBookingService() {
    _initializeSocket();
  }
  
  void _initializeSocket() {
    try {
      socket = IO.io(baseUrl, {
        'transports': ['websocket'],
        'auth': {'token': token},
        'autoConnect': false,
      });
      
      _setupSocketListeners();
    } catch (e) {
      debugPrint('Socket initialization error: $e');
    }
  }
  
  void _setupSocketListeners() {
    socket.onConnect((_) {
      isConnected = true;
      _connectionStatusController.add('Connected to server');
      debugPrint('Socket connected');
    });
    
    socket.onDisconnect((_) {
      isConnected = false;
      _connectionStatusController.add('Disconnected from server');
      debugPrint('Socket disconnected');
    });
    
    socket.on('authenticated', (data) {
      _connectionStatusController.add('Authenticated successfully');
      debugPrint('Authenticated: $data');
    });
    
    // Driver response events
    socket.on('driver_accepted', (data) {
      _driverAcceptedController.add(Map<String, dynamic>.from(data));
      debugPrint('Driver accepted: $data');
    });
    
    socket.on('no_drivers_available', (data) {
      _bookingErrorController.add({
        'type': 'no_drivers',
        'message': 'No drivers available',
        'data': data
      });
    });
    
    // Ride status events
    socket.on('driver_arriving', (data) {
      _rideStatusController.add({
        'status': 'driver_arriving',
        'data': data
      });
    });
    
    socket.on('driver_arrived', (data) {
      _rideStatusController.add({
        'status': 'driver_arrived',
        'data': data
      });
    });
    
    socket.on('ride_started', (data) {
      _rideStatusController.add({
        'status': 'ride_started',
        'data': data
      });
    });
    
    socket.on('ride_completed', (data) {
      _rideStatusController.add({
        'status': 'ride_completed',
        'data': data
      });
    });
    
    // Location updates
    socket.on('driver_location_update', (data) {
      _locationUpdateController.add(Map<String, dynamic>.from(data));
    });
    
    // Cancellation events
    socket.on('booking_cancelled', (data) {
      _rideStatusController.add({
        'status': 'booking_cancelled',
        'data': data
      });
    });
    
    socket.on('driver_cancelled', (data) {
      _rideStatusController.add({
        'status': 'driver_cancelled',
        'data': data
      });
    });
    
    // Error handling
    socket.on('booking_error', (error) {
      _bookingErrorController.add({
        'type': 'booking_error',
        'message': error['error'] ?? 'Unknown booking error',
        'code': error['code'] ?? 'UNKNOWN',
        'data': error
      });
    });
    
    socket.onError((error) {
      _connectionStatusController.add('Socket error: $error');
      debugPrint('Socket error: $error');
    });

    // Driver-specific events
    socket.on('new_booking_request', (data) {
      _newBookingRequestController.add(Map<String, dynamic>.from(data));
      debugPrint('New booking request: $data');
    });

    socket.on('drivers_location_update', (data) {
      if (data is List) {
        _driversLocationController.add(List<Map<String, dynamic>>.from(data));
      }
      debugPrint('Drivers location update: $data');
    });

    socket.on('booking_accepted_confirmation', (data) {
      _rideStatusController.add({
        'status': 'booking_accepted_confirmation',
        'data': data
      });
      debugPrint('Booking accepted confirmation: $data');
    });

    socket.on('booking_rejected_confirmation', (data) {
      _rideStatusController.add({
        'status': 'booking_rejected_confirmation',
        'data': data
      });
      debugPrint('Booking rejected confirmation: $data');
    });
  }
  
  void connect() {
    if (!isConnected) {
      socket.connect();
    }
  }
  
  void disconnect() {
    if (isConnected) {
      socket.disconnect();
    }
  }
  
  // HTTP request helper
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  
  // Test API connectivity
  Future<void> testApiConnection() async {
    try {
      debugPrint('Testing API connection to: $apiUrl/fare/estimate-fare');
      debugPrint('Using headers: $_headers');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: _headers,
      );
      
      debugPrint('Health check status: ${response.statusCode}');
      debugPrint('Health check response: ${response.body}');
    } catch (e) {
      debugPrint('API connection test error: $e');
    }
  }
  
  // Test fare estimation endpoint specifically
  Future<void> testFareEstimationEndpoint() async {
    try {
      debugPrint('Testing fare estimation endpoint: $apiUrl/fare/estimate-fare');
      
      final testBody = {
        'pickupLocation': {
          'coordinates': [67.0011, 24.8607],
          'address': 'Karachi, Pakistan'
        },
        'dropoffLocation': {
          'coordinates': [67.0025, 24.8615],
          'address': 'Clifton, Karachi, Pakistan'
        },
        'serviceType': 'car cab',
        'serviceCategory': 'standard',
        'vehicleType': 'economy',
        'distanceInMeters': 12500
      };
      
      debugPrint('Request body: ${jsonEncode(testBody)}');
      
      final response = await http.post(
        Uri.parse('$apiUrl/fare-estimation/estimate'),
        headers: _headers,
        body: jsonEncode(testBody),
      );
      
      debugPrint('Test fare estimation status: ${response.statusCode}');
      debugPrint('Test fare estimation response: ${response.body}');
      debugPrint('Response headers: ${response.headers}');
      
    } catch (e) {
      debugPrint('Fare estimation test error: $e');
    }
  }
  
  // Fare estimation with comprehensive service types
  Future<Map<String, dynamic>> getFareEstimation({
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required String serviceType,
    String serviceCategory = 'standard',
    String vehicleType = 'economy',
    String routeType = 'one_way',
    int distanceInMeters = 12500,
    int estimatedDuration = 25,
    String trafficCondition = 'moderate',
    bool isNightTime = false,
    double demandRatio = 1.0,
    int waitingMinutes = 0,
    String? scheduledTime,
    Map<String, dynamic>? serviceDetails,
    List<Map<String, dynamic>>? itemDetails,
    Map<String, dynamic>? serviceOptions,
  }) async {
    try {
      final body = {
        'pickupLocation': pickupLocation,
        'dropoffLocation': dropoffLocation,
        'serviceType': serviceType,
        'serviceCategory': serviceCategory,
        'vehicleType': vehicleType,
        'routeType': routeType,
        'distanceInMeters': distanceInMeters,
        'estimatedDuration': estimatedDuration,
        'trafficCondition': trafficCondition,
        'isNightTime': isNightTime,
        'demandRatio': demandRatio,
        'waitingMinutes': waitingMinutes,
        if (scheduledTime != null) 'scheduledTime': scheduledTime,
        if (serviceDetails != null) 'serviceDetails': serviceDetails,
        if (itemDetails != null) 'itemDetails': itemDetails,
        if (serviceOptions != null) 'serviceOptions': serviceOptions,
      };
      log("our post data is $body");
      
      final response = await http.post(
        Uri.parse('$apiUrl/fare/estimate-fare'),
        headers: _headers,
        body: jsonEncode(body),
      );
      
      debugPrint('Fare estimation response status: ${response.statusCode}');
      debugPrint('Fare estimation response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Fare estimation failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Fare estimation error: $e');
      rethrow;
    }
  }
  
  // Create booking with comprehensive fields
  Future<Map<String, dynamic>> createBooking({
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required String serviceType,
    required double offeredFare,
    String serviceCategory = 'standard',
    String vehicleType = 'economy',
    String routeType = 'one_way',
    String driverPreference = 'nearby',
    String? pinnedDriverId,
    int distanceInMeters = 12500,
    int estimatedDuration = 25,
    String trafficCondition = 'moderate',
    bool isNightTime = false,
    double demandRatio = 1.0,
    int waitingMinutes = 0,
    String? scheduledTime,
    int passengerCount = 1,
    bool wheelchairAccessible = false,
    String paymentMethod = 'cash',
    Map<String, dynamic>? pinkCaptainOptions,
    Map<String, dynamic>? driverFilters,
    Map<String, dynamic>? serviceDetails,
    List<Map<String, dynamic>>? itemDetails,
    Map<String, dynamic>? serviceOptions,
    List<String>? extras,
    Map<String, dynamic>? appointmentDetails,
  }) async {
    try {
      final body = {
        'pickupLocation': pickupLocation,
        'dropoffLocation': dropoffLocation,
        'serviceType': serviceType,
        'serviceCategory': serviceCategory,
        'vehicleType': vehicleType,
        'routeType': routeType,
        'driverPreference': driverPreference,
        if (pinnedDriverId != null) 'pinnedDriverId': pinnedDriverId,
        'offeredFare': offeredFare,
        'distanceInMeters': distanceInMeters,
        'estimatedDuration': estimatedDuration,
        'trafficCondition': trafficCondition,
        'isNightTime': isNightTime,
        'demandRatio': demandRatio,
        'waitingMinutes': waitingMinutes,
        if (scheduledTime != null) 'scheduledTime': scheduledTime,
        'passengerCount': passengerCount,
        'wheelchairAccessible': wheelchairAccessible,
        'paymentMethod': paymentMethod,
        if (pinkCaptainOptions != null) 'pinkCaptainOptions': pinkCaptainOptions,
        if (driverFilters != null) 'driverFilters': driverFilters,
        if (serviceDetails != null) 'serviceDetails': serviceDetails,
        if (itemDetails != null) 'itemDetails': itemDetails,
        if (serviceOptions != null) 'serviceOptions': serviceOptions,
        if (extras != null) 'extras': extras,
        if (appointmentDetails != null) 'appointmentDetails': appointmentDetails,
      };
      
      final response = await http.post(
        Uri.parse('$apiUrl/bookings/create'),
        headers: _headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Booking creation failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Booking creation error: $e');
      rethrow;
    }
  }
  
  // Socket methods for real-time booking
  void startBooking(String bookingId, Map<String, double> userLocation) {
    if (isConnected) {
      socket.emit('start_booking', {
        'bookingId': bookingId,
        'userLocation': userLocation,
      });
    }
  }
  
  void updateLocation(List<double> coordinates) {
    if (isConnected) {
      socket.emit('update_location', {
        'coordinates': coordinates,
      });
    }
  }
  
  void cancelBooking(String bookingId, String reason) {
    if (isConnected) {
      socket.emit('cancel_booking', {
        'bookingId': bookingId,
        'reason': reason,
      });
    }
  }

  // Driver-specific socket methods
  void joinDriverRoom(String driverId, Map<String, dynamic> driverInfo) {
    if (isConnected) {
      socket.emit('join_driver_room', {
        'driverId': driverId,
        'driverInfo': driverInfo,
      });
      debugPrint('Driver joined room: $driverId');
    }
  }

  void updateDriverLocation(String driverId, List<double> coordinates, {
    double? heading,
    double? speed,
    String status = 'available'
  }) {
    if (isConnected) {
      socket.emit('update_driver_location', {
        'driverId': driverId,
        'coordinates': coordinates,
        'heading': heading,
        'speed': speed,
        'status': status,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  void setDriverStatus(String driverId, String status, {
    List<String>? serviceTypes,
    bool autoAccept = false
  }) {
    if (isConnected) {
      socket.emit('driver_status_update', {
        'driverId': driverId,
        'status': status, // 'available', 'busy', 'offline'
        'serviceTypes': serviceTypes ?? ['car cab'],
        'autoAccept': autoAccept,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('Driver status updated: $status');
    }
  }

  void setAutoAccept(String driverId, bool autoAccept, {
    List<String>? serviceTypes,
    double? maxDistance
  }) {
    if (isConnected) {
      socket.emit('set_auto_accept', {
        'driverId': driverId,
        'autoAccept': autoAccept,
        'serviceTypes': serviceTypes ?? ['car cab'],
        'maxDistance': maxDistance ?? 5.0, // km
      });
      debugPrint('Auto accept set: $autoAccept');
    }
  }

  void acceptBookingRequest(String bookingId, String driverId) {
    if (isConnected) {
      socket.emit('accept_booking_request', {
        'bookingId': bookingId,
        'driverId': driverId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('Booking accepted: $bookingId');
    }
  }

  void rejectBookingRequest(String bookingId, String driverId, String reason) {
    if (isConnected) {
      socket.emit('reject_booking_request', {
        'bookingId': bookingId,
        'driverId': driverId,
        'reason': reason,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('Booking rejected: $bookingId, reason: $reason');
    }
  }

  void startRide(String bookingId, String driverId) {
    if (isConnected) {
      socket.emit('start_ride', {
        'bookingId': bookingId,
        'driverId': driverId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('Ride started: $bookingId');
    }
  }

  void completeRide(String bookingId, String driverId, {
    double? finalFare,
    Map<String, dynamic>? rideDetails
  }) {
    if (isConnected) {
      socket.emit('complete_ride', {
        'bookingId': bookingId,
        'driverId': driverId,
        'finalFare': finalFare,
        'rideDetails': rideDetails,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('Ride completed: $bookingId');
    }
  }

  void requestNearbyDrivers(List<double> coordinates, {
    double radius = 5.0,
    List<String>? serviceTypes
  }) {
    if (isConnected) {
      socket.emit('request_nearby_drivers', {
        'coordinates': coordinates,
        'radius': radius,
        'serviceTypes': serviceTypes ?? ['car cab'],
      });
      debugPrint('Requesting nearby drivers');
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    _driverAcceptedController.close();
    _rideStatusController.close();
    _locationUpdateController.close();
    _bookingErrorController.close();
    _connectionStatusController.close();
    _driversLocationController.close();
    _newBookingRequestController.close();
    socket.dispose();
  }
}

// Service type configurations
class ServiceTypeConfig {
  static const Map<String, List<String>> vehicleTypes = {
    'car cab': ['economy', 'premium', 'luxury'],
    'bike': ['standard', 'electric'],
    'car recovery': ['tow_truck', 'flatbed'],
    'shifting & movers': ['small_truck', 'medium_truck', 'large_truck'],
  };
  
  static const Map<String, List<String>> serviceCategories = {
    'car cab': ['standard', 'premium', 'luxury'],
    'bike': ['standard', 'premium'],
    'car recovery': ['standard', 'premium', 'luxury'],
    'shifting & movers': ['standard', 'premium'],
  };
  
  static const List<String> trafficConditions = ['light', 'moderate', 'heavy'];
  static const List<String> paymentMethods = ['cash', 'card', 'wallet', 'upi'];
  static const List<String> driverPreferences = ['nearby', 'pinned', 'pink_captain'];
}