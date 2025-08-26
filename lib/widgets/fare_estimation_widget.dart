import 'package:flutter/material.dart';
import '../services/ride_booking_service.dart';

class FareEstimationWidget extends StatefulWidget {
  final RideBookingService bookingService;
  
  const FareEstimationWidget({Key? key, required this.bookingService}) : super(key: key);
  
  @override
  _FareEstimationWidgetState createState() => _FareEstimationWidgetState();
}

class _FareEstimationWidgetState extends State<FareEstimationWidget> {
  String selectedServiceType = 'car cab';
  String selectedVehicleType = 'economy';
  String selectedServiceCategory = 'standard';
  String selectedSubcategory = '';
  String selectedTrafficCondition = 'moderate';
  bool isNightTime = false;
  double demandRatio = 1.0;
  int passengerCount = 1;
  int distanceInMeters = 12500;
  int estimatedDuration = 25;
  
  // Helper options
  bool packingHelper = false;
  bool loadingHelper = false;
  bool fixingHelper = false;
  bool roundTrip = false;
  
  // Service-specific fields
  Map<String, dynamic> serviceDetails = {};
  List<Map<String, dynamic>> itemDetails = [];
  Map<String, dynamic> serviceOptions = {};
  
  // Service type configurations
  final Map<String, List<String>> serviceTypeOptions = {
    'car cab': ['economy', 'premium', 'xl', 'family', 'luxury'],
    'bike': ['economy', 'premium', 'vip'],
    'car recovery': ['flatbed_towing', 'wheel_lift_towing', 'on_road_winching', 'off_road_winching', 'battery_jump_start', 'fuel_delivery', 'luxury_recovery', 'accident_recovery', 'heavy_duty_recovery', 'basement_pullout'],
    'shifting & movers': ['small_mover', 'medium_mover', 'heavy_mover']
  };
  
  final Map<String, Map<String, List<String>>> subcategoryOptions = {
    'car recovery': {
      'towing_services': ['flatbed_towing', 'wheel_lift_towing'],
      'winching_services': ['on_road_winching', 'off_road_winching'],
      'roadside_assistance': ['battery_jump_start', 'fuel_delivery'],
      'specialized_recovery': ['luxury_recovery', 'accident_recovery', 'heavy_duty_recovery', 'basement_pullout']
    },
    'shifting & movers': {
      'vehicle_size': ['small_mover', 'medium_mover', 'heavy_mover']
    }
  };
  
  final Map<String, List<String>> helperAvailability = {
    'car cab': [],
    'bike': [],
    'car recovery': [],
    'shifting & movers': ['packing_helper', 'loading_helper', 'fixing_helper']
  };
  
  Map<String, dynamic>? fareEstimation;
  bool isLoading = false;
  String? errorMessage;
  
  // Sample locations for testing
  final Map<String, dynamic> pickupLocation = {
    'latitude': 24.8607,
    'longitude': 67.0011,
    'address': 'Karachi, Pakistan'
  };
  
  final Map<String, dynamic> dropoffLocation = {
    'latitude': 24.8615,
    'longitude': 67.0025,
    'address': 'Clifton, Karachi, Pakistan'
  };
  
  @override
  void initState() {
    super.initState();
    _updateServiceSpecificFields();
  }
  
  void _updateServiceSpecificFields() {
    setState(() {
      switch (selectedServiceType) {
        case 'car cab':
          serviceDetails = {
            'rideType': selectedVehicleType,
            'passengerCount': passengerCount,
            'luggageCount': 2,
          };
          itemDetails = [];
          serviceOptions = {
            'roundTrip': roundTrip,
            'discount': roundTrip ? 10 : 0,
            'freeStayMinutes': roundTrip ? 30 : 0,
          };
          break;
        case 'bike':
          serviceDetails = {
            'rideType': selectedVehicleType,
            'helmetRequired': true,
          };
          itemDetails = [];
          serviceOptions = {
            'roundTrip': roundTrip,
            'discount': roundTrip ? 10 : 0,
            'freeStayMinutes': roundTrip ? 30 : 0,
          };
          break;
        case 'car recovery':
          serviceDetails = {
            'recoveryType': selectedVehicleType,
            'subcategory': selectedSubcategory.isNotEmpty ? selectedSubcategory : selectedVehicleType,
            'vehicleCondition': 'operational',
            'accessibilityLevel': 'standard',
            'vehicleModel': 'Toyota Camry',
            'vehicleYear': 2020
          };
          itemDetails = [];
          serviceOptions = {};
          break;
        case 'shifting & movers':
          serviceDetails = {
            'moveType': 'residential',
            'vehicleSize': selectedVehicleType,
            'floorLevel': 1,
            'elevatorAccess': true,
            'packingRequired': false,
            'assemblyRequired': true
          };
          itemDetails = [
            {
              'category': 'furniture',
              'items': [
                {'name': 'sofa', 'quantity': 1, 'weight': 50},
                {'name': 'bed', 'quantity': 2, 'weight': 40},
              ]
            },
            {
              'category': 'appliances',
              'items': [
                {'name': 'refrigerator', 'quantity': 1, 'weight': 80},
                {'name': 'washing_machine', 'quantity': 1, 'weight': 60},
              ]
            }
          ];
          serviceOptions = {
            'packingHelper': packingHelper,
            'loadingHelper': loadingHelper,
            'fixingHelper': fixingHelper,
            'roundTrip': roundTrip,
            'discount': roundTrip ? 10 : 0,
            'freeStayMinutes': roundTrip ? 30 : 0,
          };
          break;
      }
    });
  }
  
  Future<void> _getFareEstimation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      fareEstimation = null;
    });
    
    try {
      final result = await widget.bookingService.getFareEstimation(
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        serviceType: selectedServiceType,
        serviceCategory: selectedServiceCategory,
        vehicleType: selectedVehicleType,
        distanceInMeters: distanceInMeters,
        estimatedDuration: estimatedDuration,
        trafficCondition: selectedTrafficCondition,
        isNightTime: isNightTime,
        demandRatio: demandRatio,
        serviceDetails: serviceDetails.isNotEmpty ? serviceDetails : null,
        itemDetails: itemDetails.isNotEmpty ? itemDetails : null,
        serviceOptions: serviceOptions.isNotEmpty ? serviceOptions : null,
      );
      
      setState(() {
        fareEstimation = result;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
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
            const Text(
              'Fare Estimation Testing',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Service Type Selection
            DropdownButtonFormField<String>(
              value: selectedServiceType,
              decoration: const InputDecoration(
                labelText: 'Service Type',
                border: OutlineInputBorder(),
              ),
              items: ['car cab', 'bike', 'car recovery', 'shifting & movers']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedServiceType = value!;
                  selectedVehicleType = serviceTypeOptions[selectedServiceType]?.first ?? 'economy';
                  selectedSubcategory = '';
                });
                _updateServiceSpecificFields();
              },
            ),
            const SizedBox(height: 12),
            
            // Vehicle Type Selection
            DropdownButtonFormField<String>(
              value: selectedVehicleType,
              decoration: const InputDecoration(
                labelText: 'Vehicle Type',
                border: OutlineInputBorder(),
              ),
              items: serviceTypeOptions[selectedServiceType]!.map((type) {
                return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedVehicleType = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Service Category Selection
            DropdownButtonFormField<String>(
              value: selectedServiceCategory,
              decoration: const InputDecoration(
                labelText: 'Service Category',
                border: OutlineInputBorder(),
              ),
              items: ['standard', 'premium', 'express']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedServiceCategory = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Subcategory Selection (for applicable services)
            if (subcategoryOptions.containsKey(selectedServiceType)) ...[
              DropdownButtonFormField<String>(
                value: selectedSubcategory.isEmpty ? null : selectedSubcategory,
                decoration: const InputDecoration(
                  labelText: 'Subcategory',
                  border: OutlineInputBorder(),
                ),
                items: subcategoryOptions[selectedServiceType]!.values
                    .expand((list) => list)
                    .map((subcategory) => DropdownMenuItem(
                          value: subcategory,
                          child: Text(subcategory.replaceAll('_', ' ').toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSubcategory = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            
            // Traffic Condition
            DropdownButtonFormField<String>(
              value: selectedTrafficCondition,
              decoration: const InputDecoration(
                labelText: 'Traffic Condition',
                border: OutlineInputBorder(),
              ),
              items: ['light', 'moderate', 'heavy', 'severe']
                  .map((condition) => DropdownMenuItem(
                        value: condition,
                        child: Text(condition.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedTrafficCondition = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Night Time Toggle
            SwitchListTile(
              title: const Text('Night Time (10 PM - 6 AM)'),
              value: isNightTime,
              onChanged: (value) {
                setState(() {
                  isNightTime = value;
                });
              },
            ),
            
            // Demand Ratio Slider
            Text('Demand Ratio: ${demandRatio.toStringAsFixed(1)}x'),
            Slider(
              value: demandRatio,
              min: 1.0,
              max: 3.0,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  demandRatio = value;
                });
              },
            ),
            
            // Distance and Duration
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: distanceInMeters.toString(),
                    decoration: const InputDecoration(labelText: 'Distance (meters)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      distanceInMeters = int.tryParse(value) ?? 12500;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: estimatedDuration.toString(),
                    decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      estimatedDuration = int.tryParse(value) ?? 25;
                    },
                  ),
                ),
              ],
            ),
            // Helper Options (for applicable services)
            if (helperAvailability[selectedServiceType]!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Helper Options:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (helperAvailability[selectedServiceType]!.contains('packing_helper'))
                CheckboxListTile(
                  title: const Text('Packing Helper'),
                  value: packingHelper,
                  onChanged: (value) {
                    setState(() {
                      packingHelper = value ?? false;
                    });
                  },
                ),
              if (helperAvailability[selectedServiceType]!.contains('loading_helper'))
                CheckboxListTile(
                  title: const Text('Loading Helper'),
                  value: loadingHelper,
                  onChanged: (value) {
                    setState(() {
                      loadingHelper = value ?? false;
                    });
                  },
                ),
              if (helperAvailability[selectedServiceType]!.contains('fixing_helper'))
                CheckboxListTile(
                  title: const Text('Fixing Helper'),
                  value: fixingHelper,
                  onChanged: (value) {
                    setState(() {
                      fixingHelper = value ?? false;
                    });
                  },
                ),
              CheckboxListTile(
                title: const Text('Round Trip'),
                value: roundTrip,
                onChanged: (value) {
                  setState(() {
                    roundTrip = value ?? false;
                  });
                },
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Service-specific details display
            if (serviceDetails.isNotEmpty) ...[
              const Text(
                'Service Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  serviceDetails.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Test API Connection Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.bookingService.testApiConnection(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Test API Connection'),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Test Fare Endpoint Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.bookingService.testFareEstimationEndpoint(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text('Test Fare Endpoint'),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Get Fare Estimation Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _getFareEstimation,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Get Fare Estimation'),
              ),
            ),
            
            // Results Display
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
            
            if (fareEstimation != null) ...[
              const SizedBox(height: 16),
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
                    Text(
                      'Estimated Fare: ${fareEstimation!['currency']} ${fareEstimation!['estimatedFare']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (fareEstimation!['fareBreakdown'] != null) ...[
                      const Text(
                        'Fare Breakdown:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...fareEstimation!['fareBreakdown'].entries.map<Widget>((entry) {
                        return Text('${entry.key}: ${entry.value}');
                      }).toList(),
                      const SizedBox(height: 8),
                    ],
                    if (fareEstimation!['tripDetails'] != null) ...[
                      const Text(
                        'Trip Details:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...fareEstimation!['tripDetails'].entries.map<Widget>((entry) {
                        return Text('${entry.key}: ${entry.value}');
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}