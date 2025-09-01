import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:practicesocketmap/modal/booking_modal.dart';
import 'package:practicesocketmap/repository/userbooking_repo.dart';


class BookingScreen extends ConsumerStatefulWidget {
  final String userToken;
  final String userId;
  final String userName;

  const BookingScreen({
    required this.userToken,
    required this.userId,
    required this.userName,
    super.key,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController(text: 'Dubai Mall, Dubai, UAE');
  final _dropoffController = TextEditingController(text: 'Burj Khalifa, Dubai, UAE');
  String _serviceType = 'car cab';
  String _vehicleType = 'economy';
  int _passengerCount = 2;
  String _paymentMethod = 'cash';

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _submitBooking() {
    if (_formKey.currentState!.validate()) {
      final bookingRequest = BookingRequest(
        pickupLocation: {
          'coordinates': [55.2708, 25.2048], // Replace with dynamic input (e.g., from map)
          'address': _pickupController.text,
        },
        dropoffLocation: {
          'coordinates': [55.2744, 25.1972], // Replace with dynamic input
          'address': _dropoffController.text,
        },
        serviceType: _serviceType,
        serviceCategory: 'transport',
        vehicleType: _vehicleType,
        routeType: 'one_way',
        distanceInMeters: 2500, // Calculate dynamically in production
        passengerCount: 2,
        driverPreference: 'nearby',
        pinkCaptainOptions: {
          'femalePassengersOnly': false,
          'familyRides': false,
          'safeZoneRides': false,
          'familyWithGuardianMale': false,
          'maleWithoutFemale': false,
          'noMaleCompanion': false,
        },
        paymentMethod: _paymentMethod,
        scheduledTime: null,
        driverFilters: {
          'vehicleModel': null,
          'specificDriverId': null,
          'searchRadius': 10,
        },
        serviceOptions: {
          'airConditioning': true,
          'music': false,
          'wifi': false,
        },
        extras: [],
      );

      ref.read(bookingProvider.notifier).createBooking(widget.userToken, bookingRequest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Booking - ${widget.userName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _pickupController,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter pickup location' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dropoffController,
                      decoration: const InputDecoration(
                        labelText: 'Dropoff Location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter dropoff location' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _serviceType,
                      decoration: const InputDecoration(
                        labelText: 'Service Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['car cab', 'bike', 'van'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _serviceType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _vehicleType,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['economy', 'premium', 'luxury'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _vehicleType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _passengerCount.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Passenger Count',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Enter passenger count';
                        final count = int.tryParse(value);
                        if (count == null || count <= 0) return 'Enter a valid number';
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _passengerCount = int.parse(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                      ),
                      items: ['cash', 'card', 'mobile'].map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitBooking,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Create Booking',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (bookingState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (bookingState.error != null)
                      Text(
                        'Error: ${bookingState.error}',
                        style: const TextStyle(color: Colors.red),
                      )
                    else if (bookingState.bookingResponse != null)
                      Column(
                        children: [
                          Text(
                            'Booking Created: ${bookingState.bookingResponse!.bookingId}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (bookingState.driversFound != null)
                            Text(
                              'Drivers Found: ${bookingState.driversFound!.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}