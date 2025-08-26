import 'package:flutter/material.dart';
import 'dart:async';
import '../services/ride_booking_service.dart';

class BookingWidget extends StatefulWidget {
  final RideBookingService bookingService;
  
  const BookingWidget({Key? key, required this.bookingService}) : super(key: key);
  
  @override
  _BookingWidgetState createState() => _BookingWidgetState();
}

class _BookingWidgetState extends State<BookingWidget> {
  String selectedServiceType = 'car cab';
  String selectedVehicleType = 'economy';
  String selectedServiceCategory = 'standard';
  String selectedDriverPreference = 'nearby';
  String selectedPaymentMethod = 'cash';
  double offeredFare = 245.50;
  int passengerCount = 1;
  bool wheelchairAccessible = false;
  
  // Pink Captain options
  bool femalePassengersOnly = false;
  bool familyRides = false;
  bool safeZoneRides = false;
  
  // Driver filters
  double minRating = 4.0;
  List<String> preferredLanguages = ['english'];
  int vehicleAge = 5;
  int experienceYears = 2;
  
  Map<String, dynamic>? currentBooking;
  Map<String, dynamic>? driverInfo;
  String bookingStatus = 'idle';
  bool isLoading = false;
  String? errorMessage;
  
  List<String> statusMessages = [];
  List<String> socketMessages = [];
  
  late StreamSubscription _driverAcceptedSub;
  late StreamSubscription _rideStatusSub;
  late StreamSubscription _locationUpdateSub;
  late StreamSubscription _bookingErrorSub;
  late StreamSubscription _connectionStatusSub;
  
  // Sample locations for testing
  final Map<String, dynamic> pickupLocation = {
    'coordinates': [67.0011, 24.8607],
    'address': 'Karachi, Pakistan'
  };
  
  final Map<String, dynamic> dropoffLocation = {
    'coordinates': [67.0025, 24.8615],
    'address': 'Clifton, Karachi, Pakistan'
  };
  
  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }
  
  void _setupSocketListeners() {
    _driverAcceptedSub = widget.bookingService.driverAcceptedStream.listen((data) {
      setState(() {
        driverInfo = data['driver'];
        bookingStatus = 'driver_accepted';
        statusMessages.add('Driver ${data['driver']['name']} accepted your ride!');
        socketMessages.add('driver_accepted: ${data.toString()}');
      });
    });
    
    _rideStatusSub = widget.bookingService.rideStatusStream.listen((data) {
      setState(() {
        bookingStatus = data['status'];
        switch (data['status']) {
          case 'driver_arriving':
            statusMessages.add('Driver is on the way to pickup location');
            break;
          case 'driver_arrived':
            statusMessages.add('Driver has arrived at pickup location');
            break;
          case 'ride_started':
            statusMessages.add('Ride has started');
            break;
          case 'ride_completed':
            statusMessages.add('Ride completed successfully');
            if (data['data']['pgpEarned'] != null) {
              statusMessages.add('PGP Earned: ${data['data']['pgpEarned']}');
            }
            break;
          case 'booking_cancelled':
            statusMessages.add('Booking cancelled');
            break;
          case 'driver_cancelled':
            statusMessages.add('Driver cancelled - searching for new driver');
            break;
        }
        socketMessages.add('${data['status']}: ${data['data'].toString()}');
      });
    });
    
    _locationUpdateSub = widget.bookingService.locationUpdateStream.listen((data) {
      setState(() {
        socketMessages.add('driver_location_update: ${data.toString()}');
      });
    });
    
    _bookingErrorSub = widget.bookingService.bookingErrorStream.listen((error) {
      setState(() {
        errorMessage = error['message'];
        bookingStatus = 'error';
        statusMessages.add('Error: ${error['message']}');
        socketMessages.add('${error['type']}: ${error.toString()}');
      });
    });
    
    _connectionStatusSub = widget.bookingService.connectionStatusStream.listen((status) {
      setState(() {
        socketMessages.add('Connection: $status');
      });
    });
  }
  
  Future<void> _createBooking() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      statusMessages.clear();
      socketMessages.clear();
      bookingStatus = 'creating';
    });
    
    try {
      // First get fare estimation
      final fareResult = await widget.bookingService.getFareEstimation(
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        serviceType: selectedServiceType,
        serviceCategory: selectedServiceCategory,
        vehicleType: selectedVehicleType,
      );
      
      setState(() {
        offeredFare = fareResult['estimatedFare'].toDouble();
        statusMessages.add('Fare estimated: ${fareResult['currency']} $offeredFare');
      });
      
      // Create booking
      final bookingResult = await widget.bookingService.createBooking(
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        serviceType: selectedServiceType,
        serviceCategory: selectedServiceCategory,
        vehicleType: selectedVehicleType,
        offeredFare: offeredFare,
        driverPreference: selectedDriverPreference,
        paymentMethod: selectedPaymentMethod,
        passengerCount: passengerCount,
        wheelchairAccessible: wheelchairAccessible,
        pinkCaptainOptions: selectedDriverPreference == 'pink_captain' ? {
          'femalePassengersOnly': femalePassengersOnly,
          'familyRides': familyRides,
          'safeZoneRides': safeZoneRides,
        } : null,
        driverFilters: {
          'minRating': minRating,
          'preferredLanguages': preferredLanguages,
          'vehicleAge': vehicleAge,
          'experienceYears': experienceYears,
        },
        extras: ['child_seat', 'music_preference'],
      );
      
      setState(() {
        currentBooking = bookingResult['booking'];
        bookingStatus = 'searching';
        statusMessages.add('Booking created successfully');
        statusMessages.add('Searching for drivers...');
      });
      
      // Start real-time booking process
      widget.bookingService.startBooking(
        currentBooking!['_id'],
        {
          'latitude': pickupLocation['coordinates'][1],
          'longitude': pickupLocation['coordinates'][0],
        },
      );
      
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        bookingStatus = 'error';
        statusMessages.add('Booking failed: $e');
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  void _cancelBooking() {
    if (currentBooking != null) {
      widget.bookingService.cancelBooking(
        currentBooking!['_id'],
        'User cancelled',
      );
      setState(() {
        bookingStatus = 'cancelling';
        statusMessages.add('Cancelling booking...');
      });
    }
  }
  
  void _resetBooking() {
    setState(() {
      currentBooking = null;
      driverInfo = null;
      bookingStatus = 'idle';
      errorMessage = null;
      statusMessages.clear();
      socketMessages.clear();
    });
  }
  
  Color _getStatusColor() {
    switch (bookingStatus) {
      case 'idle':
        return Colors.grey;
      case 'creating':
      case 'searching':
        return Colors.orange;
      case 'driver_accepted':
      case 'driver_arriving':
      case 'driver_arrived':
      case 'ride_started':
        return Colors.blue;
      case 'ride_completed':
        return Colors.green;
      case 'error':
      case 'booking_cancelled':
      case 'driver_cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Ride Booking Testing',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    bookingStatus.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Service Configuration
            if (bookingStatus == 'idle') ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedServiceType,
                      decoration: const InputDecoration(labelText: 'Service Type'),
                      items: ServiceTypeConfig.vehicleTypes.keys.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedServiceType = value!;
                          selectedVehicleType = ServiceTypeConfig.vehicleTypes[value]!.first;
                          selectedServiceCategory = ServiceTypeConfig.serviceCategories[value]!.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedVehicleType,
                      decoration: const InputDecoration(labelText: 'Vehicle Type'),
                      items: ServiceTypeConfig.vehicleTypes[selectedServiceType]!.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedVehicleType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedDriverPreference,
                      decoration: const InputDecoration(labelText: 'Driver Preference'),
                      items: ServiceTypeConfig.driverPreferences.map((pref) {
                        return DropdownMenuItem(value: pref, child: Text(pref));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDriverPreference = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPaymentMethod,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      items: ServiceTypeConfig.paymentMethods.map((method) {
                        return DropdownMenuItem(value: method, child: Text(method));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Pink Captain Options
              if (selectedDriverPreference == 'pink_captain') ...[
                const Text(
                  'Pink Captain Options:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text('Female Passengers Only'),
                  value: femalePassengersOnly,
                  onChanged: (value) {
                    setState(() {
                      femalePassengersOnly = value!;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Family Rides'),
                  value: familyRides,
                  onChanged: (value) {
                    setState(() {
                      familyRides = value!;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Safe Zone Rides'),
                  value: safeZoneRides,
                  onChanged: (value) {
                    setState(() {
                      safeZoneRides = value!;
                    });
                  },
                ),
              ],
              
              // Driver Filters
              const Text(
                'Driver Filters:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Minimum Rating: ${minRating.toStringAsFixed(1)}'),
              Slider(
                value: minRating,
                min: 1.0,
                max: 5.0,
                divisions: 40,
                onChanged: (value) {
                  setState(() {
                    minRating = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Current Booking Info
            if (currentBooking != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking ID: ${currentBooking!['_id']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Service: ${currentBooking!['serviceType']}'),
                    Text('Fare: AED ${currentBooking!['offeredFare']}'),
                    Text('Status: ${currentBooking!['status']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Driver Info
            if (driverInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver Information:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Name: ${driverInfo!['name']}'),
                    Text('Phone: ${driverInfo!['phone']}'),
                    Text('Vehicle: ${driverInfo!['vehicleNumber']}'),
                    Text('Rating: ${driverInfo!['rating']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Action Buttons
            Row(
              children: [
                if (bookingStatus == 'idle') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _createBooking,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Create Booking'),
                    ),
                  ),
                ] else if (bookingStatus == 'searching' || 
                          bookingStatus == 'driver_accepted' ||
                          bookingStatus == 'driver_arriving') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelBooking,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Cancel Booking'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetBooking,
                      child: const Text('New Booking'),
                    ),
                  ),
                ],
              ],
            ),
            
            // Status Messages
            if (statusMessages.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Status Updates:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                height: 120,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: statusMessages.length,
                  itemBuilder: (context, index) {
                    return Text(
                      '• ${statusMessages[index]}',
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),
              ),
            ],
            
            // Socket Messages (Debug)
            if (socketMessages.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Socket Messages (Debug)'),
                children: [
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: socketMessages.length,
                      itemBuilder: (context, index) {
                        return Text(
                          socketMessages[index],
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
            
            // Error Display
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: $errorMessage',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _driverAcceptedSub.cancel();
    _rideStatusSub.cancel();
    _locationUpdateSub.cancel();
    _bookingErrorSub.cancel();
    _connectionStatusSub.cancel();
    super.dispose();
  }
}