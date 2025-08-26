import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DriverAuthService {
  static const String baseUrl = 'http://159.198.74.112:3001';
  static const String apiUrl = '$baseUrl/api';
  
  // Storage keys
  static const String _tokenKey = 'driver_token';
  static const String _driverIdKey = 'driver_id';
  static const String _driverDataKey = 'driver_data';
  static const String _isLoggedInKey = 'is_logged_in';
  
  // Singleton pattern
  static final DriverAuthService _instance = DriverAuthService._internal();
  factory DriverAuthService() => _instance;
  DriverAuthService._internal();
  
  // Current driver data
  String? _token;
  String? _driverId;
  Map<String, dynamic>? _driverData;
  bool _isLoggedIn = false;
  
  // Getters
  String? get token => _token;
  String? get driverId => _driverId;
  Map<String, dynamic>? get driverData => _driverData;
  bool get isLoggedIn => _isLoggedIn;
  
  // Initialize service and load stored credentials
  Future<void> initialize() async {
    await _loadStoredCredentials();
  }
  
  // Load stored credentials from SharedPreferences
  Future<void> _loadStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _token = prefs.getString(_tokenKey);
      _driverId = prefs.getString(_driverIdKey);
      _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      final driverDataString = prefs.getString(_driverDataKey);
      if (driverDataString != null) {
        _driverData = jsonDecode(driverDataString);
      }
      
      debugPrint('Loaded stored credentials: token=${_token != null}, driverId=$_driverId, isLoggedIn=$_isLoggedIn');
    } catch (e) {
      debugPrint('Error loading stored credentials: $e');
    }
  }
  
  // Save credentials to SharedPreferences
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_token != null) {
        await prefs.setString(_tokenKey, _token!);
      }
      if (_driverId != null) {
        await prefs.setString(_driverIdKey, _driverId!);
      }
      if (_driverData != null) {
        await prefs.setString(_driverDataKey, jsonEncode(_driverData!));
      }
      await prefs.setBool(_isLoggedInKey, _isLoggedIn);
      
      debugPrint('Credentials saved successfully');
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }
  
  // Driver login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('Attempting driver login for: $email');
      
      final response = await http.post(
        Uri.parse('$apiUrl/user/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successful login
        _token = responseData['token'];
        _driverId = responseData['userId'];
        _driverData = responseData['user'];
        _isLoggedIn = true;
        
        // Save credentials
        await _saveCredentials();
        
        return {
          'success': true,
          'message': 'Login successful',
          'token': _token,
          'driverId': _driverId,
          'driverData': _driverData,
        };
      } else {
        // Login failed
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }
  
  // Driver registration (optional)
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String vehicleType,
    required String licenseNumber,
  }) async {
    try {
      debugPrint('Attempting driver registration for: $email');
      
      final response = await http.post(
        Uri.parse('$apiUrl/user/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'userType': 'driver',
          'vehicleType': vehicleType,
          'licenseNumber': licenseNumber,
        }),
      );
      
      debugPrint('Registration response status: ${response.statusCode}');
      debugPrint('Registration response body: ${response.body}');
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Registration successful',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
          'error': responseData['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      _token = null;
      _driverId = null;
      _driverData = null;
      _isLoggedIn = false;
      
      // Clear stored credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_driverIdKey);
      await prefs.remove(_driverDataKey);
      await prefs.setBool(_isLoggedInKey, false);
      
      debugPrint('Driver logged out successfully');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
  
  // Verify token validity
  Future<bool> verifyToken() async {
    if (_token == null) return false;
    
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _driverData = responseData['user'] ?? responseData;
        return true;
      } else {
        // Token is invalid, clear credentials
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('Token verification error: $e');
      return false;
    }
  }
  
  // Get driver profile
  Future<Map<String, dynamic>?> getDriverProfile() async {
    if (_token == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _driverData = responseData['user'] ?? responseData;
        await _saveCredentials();
        return _driverData;
      }
    } catch (e) {
      debugPrint('Get profile error: $e');
    }
    
    return null;
  }
  
  // Update driver location (for profile)
  Future<bool> updateDriverLocation(double latitude, double longitude) async {
    if (_token == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/bookings/driver/location'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update location error: $e');
      return false;
    }
  }
  
  // Update driver status
  Future<bool> updateDriverStatus(String status) async {
    if (_token == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/bookings/driver/status'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status, // 'online', 'offline', 'busy'
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update status error: $e');
      return false;
    }
  }
}