import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:practicesocketmap/provider/socket_connect_provider.dart';
import 'package:practicesocketmap/modal/qualified_drivers_response_modal.dart';
import 'dart:convert';
import 'dart:async';

class DriversMapScreen extends ConsumerStatefulWidget {
  const DriversMapScreen({super.key});

  @override
  ConsumerState<DriversMapScreen> createState() => _DriversMapScreenState();
}

class _DriversMapScreenState extends ConsumerState<DriversMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = false;
  bool _isSocketConnected = false;
  QualifiedDriversResponse? _driversResponse;
  String _statusMessage = 'Ready to search for drivers';
  
  // Default pickup location (Lahore, Pakistan)
  final LatLng _pickupLocation = const LatLng(33.6402842, 73.0756609);
  
  // Request parameters
  String _serviceType = 'bike';
  String _vehicleType = 'economy';
  String _driverPreference = 'nearby';

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _addPickupMarker();
  }

  Future<void> _initializeSocket() async {
    try {
      final socketService = ref.read(socketConnectProvider.notifier);
      await socketService.connectSocket();
      
      setState(() {
        _isSocketConnected = socketService.isConnected;
        _statusMessage = _isSocketConnected 
            ? 'Socket connected - Ready to search'
            : 'Socket connection failed';
      });
      
      // Listen for qualified drivers response
      socketService.on('qualified_drivers_response', _handleDriversResponse);
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Socket error: $e';
      });
      print('DEBUG MAP: Socket initialization error: $e');
    }
  }

  void _addPickupMarker() {
    final pickupMarker = Marker(
      markerId: const MarkerId('pickup'),
      position: _pickupLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(
        title: 'Pickup Location',
        snippet: 'Your current location',
      ),
    );
    
    setState(() {
      _markers.add(pickupMarker);
    });
  }

  void _handleDriversResponse(dynamic data) {
    print('DEBUG MAP: Received drivers response: $data');
    
    try {
      final response = QualifiedDriversResponse.fromJson(data);
      setState(() {
        _driversResponse = response;
        _isLoading = false;
        _statusMessage = 'Found ${response.driversCount} drivers';
      });
      
      _updateDriverMarkers(response.drivers);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error parsing response: $e';
      });
      print('DEBUG MAP: Error parsing drivers response: $e');
    }
  }

  void _updateDriverMarkers(List<QualifiedDriver> drivers) {
    // Remove existing driver markers (keep pickup marker)
    _markers.removeWhere((marker) => marker.markerId.value.startsWith('driver_'));
    
    for (int i = 0; i < drivers.length; i++) {
      final driver = drivers[i];
      
      if (driver.coordinates.length >= 2) {
        final driverPosition = LatLng(
          driver.coordinates[1], // latitude
          driver.coordinates[0], // longitude
        );
        
        print('DEBUG MAP: Adding driver marker at ${driver.coordinates[1]}, ${driver.coordinates[0]}');
        
        final driverMarker = Marker(
          markerId: MarkerId('driver_${driver.driverId}'),
          position: driverPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerColor(driver.vehicles.isNotEmpty ? driver.vehicles.first.serviceType : 'bike')
          ),
          infoWindow: InfoWindow(
            title: '${driver.firstName} ${driver.lastName}',
            snippet: '${driver.vehicles.isNotEmpty ? driver.vehicles.first.serviceType : 'N/A'} • ${driver.driverStatus} • Rating: ${driver.rating}',
          ),
        );
        
        setState(() {
          _markers.add(driverMarker);
        });
      }
    }
    
    // Adjust camera to show all markers
    _fitMarkersInView();
  }

  double _getMarkerColor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'bike':
        return BitmapDescriptor.hueBlue;
      case 'car':
        return BitmapDescriptor.hueRed;
      case 'truck':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueBlue;
    }
  }

  void _fitMarkersInView() {
    if (_mapController != null && _markers.isNotEmpty) {
      final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _requestQualifiedDrivers() async {
    if (!_isSocketConnected) {
      _showSnackBar('Socket not connected', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Searching for drivers...';
    });

    try {
      final socketService = ref.read(socketConnectProvider.notifier);
      
      final request = QualifiedDriversRequest(
        pickupLocation: PickupLocation(
          type: 'Point',
          coordinates: [_pickupLocation.longitude, _pickupLocation.latitude],
        ),
        serviceType: _serviceType,
        vehicleType: _vehicleType,
        driverPreference: _driverPreference,
      );
      
      print('DEBUG MAP: Emitting request: ${jsonEncode(request.toJson())}');
      socketService.emit('request_qualified_drivers', request.toJson());
      
      // Set timeout
      Timer(const Duration(seconds: 10), () {
        if (_isLoading) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Request timeout - no response received';
          });
        }
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error requesting drivers: $e';
      });
      print('DEBUG MAP: Error requesting drivers: $e');
    }
  }

  void _clearDrivers() {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('driver_'));
      _driversResponse = null;
      _statusMessage = 'Drivers cleared';
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers Map'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _requestQualifiedDrivers,
            tooltip: 'Refresh Drivers',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearDrivers,
            tooltip: 'Clear Drivers',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status and Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Connection Status
                Row(
                  children: [
                    Icon(
                      _isSocketConnected ? Icons.wifi : Icons.wifi_off,
                      color: _isSocketConnected ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _isSocketConnected ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Service Type Selection
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _serviceType,
                        decoration: const InputDecoration(
                          labelText: 'Service',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: ['bike', 'car', 'truck'].map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _serviceType = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _vehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: ['economy', 'premium', 'luxury'].map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _vehicleType = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _requestQualifiedDrivers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),
                
                // Driver Count
                if (_driversResponse != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Found ${_driversResponse!.driversCount} drivers (${_driversResponse!.searchStats.finalQualifiedDrivers} qualified)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Map
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _pickupLocation,
                zoom: 14.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}