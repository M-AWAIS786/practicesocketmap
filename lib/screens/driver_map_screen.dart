import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../services/ride_booking_service.dart';
import '../services/driver_auth_service.dart';
import 'driver_login_screen.dart';

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({Key? key}) : super(key: key);

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  final RideBookingService _rideService = RideBookingService();
  final DriverAuthService _authService = DriverAuthService();
  GoogleMapController? _mapController;
  Location location = Location();
  
  // Map state
  LatLng _currentPosition = const LatLng(24.8607, 67.0011); // Karachi default
  Set<Marker> _markers = {};
  bool _isLoading = true;
  
  // Driver data
  List<Map<String, dynamic>> _onlineDrivers = [];
  StreamSubscription? _driversLocationSubscription;
  StreamSubscription? _connectionStatusSubscription;
  
  // Driver status
  bool _isDriverOnline = false;
  String _driverStatus = 'offline';
  
  // Get driver ID from auth service
  String? get _driverId => _authService.driverId;
  Map<String, dynamic>? get _driverData => _authService.driverData;
  
  @override
  void initState() {
    super.initState();
    _initializeDriver();
  }
  
  Future<void> _initializeDriver() async {
    await _authService.initialize();
    
    if (!_authService.isLoggedIn || _authService.token == null) {
      // Redirect to login if not authenticated
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DriverLoginScreen()),
        );
      }
      return;
    }
    
    // Reinitialize ride service with auth credentials
    await _rideService.reinitializeWithAuth();
    
    _initializeMap();
    _setupSocketListeners();
  }
  
  Future<void> _initializeMap() async {
    try {
      // Check location permission
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() => _isLoading = false);
          return;
        }
      }
      
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() => _isLoading = false);
          return;
        }
      }
      
      // Get current location
      LocationData locationData = await location.getLocation();
      setState(() {
        _currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
        _isLoading = false;
      });
      
      // Connect to socket service
      _rideService.connect();
      
    } catch (e) {
      debugPrint('Error initializing map: $e');
      setState(() => _isLoading = false);
    }
  }
  
  void _setupSocketListeners() {
    // Listen to drivers location updates
    _driversLocationSubscription = _rideService.driversLocationStream.listen((drivers) {
      setState(() {
        _onlineDrivers = drivers;
        _updateDriverMarkers();
      });
    });
    
    // Listen to connection status
    _connectionStatusSubscription = _rideService.connectionStatusStream.listen((status) {
      debugPrint('Connection status: $status');
    });
  }
  
  void _updateDriverMarkers() {
    Set<Marker> newMarkers = {};
    
    // Add current location marker
    newMarkers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Current position',
        ),
      ),
    );
    
    // Add driver markers
    for (var driver in _onlineDrivers) {
      if (driver['coordinates'] != null && driver['coordinates'] is List) {
        List<dynamic> coords = driver['coordinates'];
        if (coords.length >= 2) {
          newMarkers.add(
            Marker(
              markerId: MarkerId('driver_${driver['driverId'] ?? driver['id']}'),
              position: LatLng(coords[1].toDouble(), coords[0].toDouble()),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                driver['status'] == 'available' 
                    ? BitmapDescriptor.hueGreen 
                    : BitmapDescriptor.hueOrange
              ),
              infoWindow: InfoWindow(
                title: 'Driver ${driver['driverId'] ?? driver['id']}',
                snippet: 'Status: ${driver['status'] ?? 'unknown'}\nService: ${driver['serviceTypes']?.join(', ') ?? 'N/A'}',
              ),
            ),
          );
        }
      }
    }
    
    setState(() {
      _markers = newMarkers;
    });
  }
  
  void _toggleDriverStatus() {
    if (_driverId == null) return;
    
    if (_isDriverOnline) {
      // Go offline
      _rideService.setDriverStatus(_driverId!, 'offline');
      setState(() {
        _isDriverOnline = false;
        _driverStatus = 'offline';
      });
    } else {
      // Go online
      final driverInfo = {
        'name': _driverData?['name'] ?? _driverId,
        'vehicleType': _driverData?['vehicleType'] ?? 'car',
        'serviceTypes': _driverData?['serviceTypes'] ?? ['car cab'],
        'rating': _driverData?['rating'] ?? 4.5,
      };
      
      _rideService.joinDriverRoom(_driverId!, driverInfo);
      
      _rideService.setDriverStatus(_driverId!, 'available', 
        serviceTypes: _driverData?['serviceTypes'] ?? ['car cab'],
        autoAccept: false
      );
      
      // Update driver location
      _rideService.updateDriverLocation(
        _driverId!, 
        [_currentPosition.longitude, _currentPosition.latitude],
        status: 'available'
      );
      
      setState(() {
        _isDriverOnline = true;
        _driverStatus = 'available';
      });
    }
  }
  
  Future<void> _logout() async {
    // Go offline first
    if (_isDriverOnline && _driverId != null) {
      _rideService.setDriverStatus(_driverId!, 'offline');
    }
    
    // Disconnect socket
    _rideService.disconnect();
    
    // Logout from auth service
    await _authService.logout();
    
    // Navigate to login screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DriverLoginScreen()),
      );
    }
  }
  
  void _requestNearbyDrivers() {
    _rideService.requestNearbyDrivers(
      [_currentPosition.longitude, _currentPosition.latitude],
      radius: 10.0,
      serviceTypes: ['car cab', 'bike']
    );
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Move camera to current position
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 14.0,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _driversLocationSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Map'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _requestNearbyDrivers,
            tooltip: 'Refresh Drivers',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapType: MapType.normal,
                ),
                
                // Driver status card
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Driver Status: $_driverStatus',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch(
                                value: _isDriverOnline,
                                onChanged: (value) => _toggleDriverStatus(),
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Online Drivers: ${_onlineDrivers.length}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Driver list
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 120,
                    child: Card(
                      elevation: 4,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Online Drivers',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _onlineDrivers.isEmpty
                                ? const Center(
                                    child: Text('No drivers online'),
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _onlineDrivers.length,
                                    itemBuilder: (context, index) {
                                      final driver = _onlineDrivers[index];
                                      return Container(
                                        width: 120,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.local_taxi,
                                                  color: driver['status'] == 'available'
                                                      ? Colors.green
                                                      : Colors.orange,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'ID: ${driver['driverId']?.toString().substring(0, 8) ?? 'N/A'}',
                                                  style: const TextStyle(fontSize: 10),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  driver['status'] ?? 'unknown',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _requestNearbyDrivers,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.search, color: Colors.white),
        tooltip: 'Find Nearby Drivers',
      ),
    );
  }
}