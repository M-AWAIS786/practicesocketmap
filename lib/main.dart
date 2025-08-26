import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/ride_booking_service.dart';
import 'services/driver_auth_service.dart';
import 'widgets/fare_estimation_widget.dart';
import 'widgets/booking_widget.dart';
import 'screens/driver_map_screen.dart';
import 'screens/driver_login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final DriverAuthService _authService = DriverAuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await _authService.initialize();
    
    if (_authService.isLoggedIn && _authService.token != null) {
      // Verify token is still valid
      final isValid = await _authService.verifyToken();
      if (isValid) {
        // Navigate to driver map screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const DriverMapScreen(),
            ),
          );
          return;
        }
      }
    }
    
    // Show login screen
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return const DriverLoginScreen();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  LocationData? _currentLocation;
  Location _location = Location();
  Set<Marker> _markers = {};
  late RideBookingService _bookingService;
  late TabController _tabController;
  
  List<String> _connectionMessages = [];
  
  // Default location (Delhi)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _bookingService = RideBookingService();
    _requestLocationPermission();
    _setupBookingServiceListeners();
  }
  
  void _setupBookingServiceListeners() {
    _bookingService.connectionStatusStream.listen((status) {
      setState(() {
        _connectionMessages.add(status);
      });
    });
  }

  @override
  void dispose() {
    _bookingService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    // if (status == PermissionStatus.granted) {
      _getCurrentLocation();
    // }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationData locationData = await _location.getLocation();
      setState(() {
        _currentLocation = locationData;
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(locationData.latitude!, locationData.longitude!),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      });
      
      if (_mapController != null && _currentLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }



  void _connectSocket() {
    _bookingService.connect();
  }

  void _disconnectSocket() {
    _bookingService.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Map & Socket', icon: Icon(Icons.map)),
            Tab(text: 'Fare Estimation', icon: Icon(Icons.calculate)),
            Tab(text: 'Booking Test', icon: Icon(Icons.local_taxi)),
            Tab(text: 'Driver Map', icon: Icon(Icons.drive_eta)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Map and Socket Tab
          Column(
            children: [
              // Socket Status Panel
              Container(
                padding: const EdgeInsets.all(16),
                color: _bookingService.isConnected ? Colors.green[100] : Colors.red[100],
                child: Row(
                  children: [
                    Icon(
                      _bookingService.isConnected ? Icons.wifi : Icons.wifi_off,
                      color: _bookingService.isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _bookingService.isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        color: _bookingService.isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _bookingService.isConnected ? _disconnectSocket : _connectSocket,
                      child: Text(_bookingService.isConnected ? 'Disconnect' : 'Connect'),
                    ),
                  ],
                ),
              ),
              // User Info Panel
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: const Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Socket Test Mode',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'For driver authentication, use Driver Map tab',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Map
              Expanded(
                flex: 2,
                child: GoogleMap(
                  initialCameraPosition: _initialPosition,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (_currentLocation != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                        ),
                      );
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: _markers,
                ),
              ),
              // Connection Messages Panel
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connection Messages:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _connectionMessages.length,
                          itemBuilder: (context, index) {
                            return Text(
                              _connectionMessages[index],
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Fare Estimation Tab
          SingleChildScrollView(
            child: FareEstimationWidget(bookingService: _bookingService),
          ),
          // Booking Test Tab
          SingleChildScrollView(
            child: BookingWidget(bookingService: _bookingService),
          ),
          // Driver Map Tab
          const DriverMapScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        tooltip: 'Get Current Location',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
