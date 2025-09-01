class QualifiedDriversResponse {
  final bool success;
  final List<QualifiedDriver> drivers;
  final int driversCount;
  final String serviceType;
  final String vehicleType;
  final SearchCriteria searchCriteria;
  final SearchStats searchStats;
  final String timestamp;

  QualifiedDriversResponse({
    required this.success,
    required this.drivers,
    required this.driversCount,
    required this.serviceType,
    required this.vehicleType,
    required this.searchCriteria,
    required this.searchStats,
    required this.timestamp,
  });

  factory QualifiedDriversResponse.fromJson(Map<String, dynamic> json) {
    return QualifiedDriversResponse(
      success: json['success'] ?? false,
      drivers: (json['drivers'] as List<dynamic>? ?? [])
          .map((driver) => QualifiedDriver.fromJson(driver))
          .toList(),
      driversCount: json['driversCount'] ?? 0,
      serviceType: json['serviceType'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      searchCriteria: SearchCriteria.fromJson(json['searchCriteria'] ?? {}),
      searchStats: SearchStats.fromJson(json['searchStats'] ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'drivers': drivers.map((driver) => driver.toJson()).toList(),
      'driversCount': driversCount,
      'serviceType': serviceType,
      'vehicleType': vehicleType,
      'searchCriteria': searchCriteria.toJson(),
      'searchStats': searchStats.toJson(),
      'timestamp': timestamp,
    };
  }
}

class QualifiedDriver {
  final String driverId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phoneNumber;
  final bool isActive;
  final String driverStatus;
  final String lastActiveAt;
  final List<double> coordinates;
  final CurrentLocation currentLocation;
  final double distance;
  final double estimatedArrival;
  final double rating;
  final int totalRides;
  final List<Vehicle> vehicles;
  final String gender;
  final DriverSettings driverSettings;

  QualifiedDriver({
    required this.driverId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.isActive,
    required this.driverStatus,
    required this.lastActiveAt,
    required this.coordinates,
    required this.currentLocation,
    required this.distance,
    required this.estimatedArrival,
    required this.rating,
    required this.totalRides,
    required this.vehicles,
    required this.gender,
    required this.driverSettings,
  });

  factory QualifiedDriver.fromJson(Map<String, dynamic> json) {
    return QualifiedDriver(
      driverId: json['driverId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isActive: json['isActive'] ?? false,
      driverStatus: json['driverStatus'] ?? '',
      lastActiveAt: json['lastActiveAt'] ?? '',
      coordinates: (json['coordinates'] as List<dynamic>? ?? [])
          .map((coord) => (coord as num).toDouble())
          .toList(),
      currentLocation: CurrentLocation.fromJson(json['currentLocation'] ?? {}),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      estimatedArrival: (json['estimatedArrival'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRides: json['totalRides'] ?? 0,
      vehicles: (json['vehicles'] as List<dynamic>? ?? [])
          .map((vehicle) => Vehicle.fromJson(vehicle))
          .toList(),
      gender: json['gender'] ?? '',
      driverSettings: DriverSettings.fromJson(json['driverSettings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
      'driverStatus': driverStatus,
      'lastActiveAt': lastActiveAt,
      'coordinates': coordinates,
      'currentLocation': currentLocation.toJson(),
      'distance': distance,
      'estimatedArrival': estimatedArrival,
      'rating': rating,
      'totalRides': totalRides,
      'vehicles': vehicles.map((vehicle) => vehicle.toJson()).toList(),
      'gender': gender,
      'driverSettings': driverSettings.toJson(),
    };
  }
}

class CurrentLocation {
  final String type;
  final List<double> coordinates;

  CurrentLocation({
    required this.type,
    required this.coordinates,
  });

  factory CurrentLocation.fromJson(Map<String, dynamic> json) {
    return CurrentLocation(
      type: json['type'] ?? 'Point',
      coordinates: (json['coordinates'] as List<dynamic>? ?? [])
          .map((coord) => (coord as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}

class Vehicle {
  final String id;
  final String serviceType;
  final String vehicleType;

  Vehicle({
    required this.id,
    required this.serviceType,
    required this.vehicleType,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      serviceType: json['serviceType'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceType': serviceType,
      'vehicleType': vehicleType,
    };
  }
}

class DriverSettings {
  final AutoAccept autoAccept;
  final RidePreferences ridePreferences;

  DriverSettings({
    required this.autoAccept,
    required this.ridePreferences,
  });

  factory DriverSettings.fromJson(Map<String, dynamic> json) {
    return DriverSettings(
      autoAccept: AutoAccept.fromJson(json['autoAccept'] ?? {}),
      ridePreferences: RidePreferences.fromJson(json['ridePreferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoAccept': autoAccept.toJson(),
      'ridePreferences': ridePreferences.toJson(),
    };
  }
}

class AutoAccept {
  final bool enabled;
  final double maxDistance;
  final double minFare;
  final List<String> serviceTypes;

  AutoAccept({
    required this.enabled,
    required this.maxDistance,
    required this.minFare,
    required this.serviceTypes,
  });

  factory AutoAccept.fromJson(Map<String, dynamic> json) {
    return AutoAccept(
      enabled: json['enabled'] ?? false,
      maxDistance: (json['maxDistance'] as num?)?.toDouble() ?? 0.0,
      minFare: (json['minFare'] as num?)?.toDouble() ?? 0.0,
      serviceTypes: (json['serviceTypes'] as List<dynamic>? ?? [])
          .map((type) => type.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'maxDistance': maxDistance,
      'minFare': minFare,
      'serviceTypes': serviceTypes,
    };
  }
}

class RidePreferences {
  final bool acceptBike;
  final bool acceptCar;
  final bool acceptFemaleOnly;
  final double maxRideDistance;
  final bool pinkCaptainMode;

  RidePreferences({
    required this.acceptBike,
    required this.acceptCar,
    required this.acceptFemaleOnly,
    required this.maxRideDistance,
    required this.pinkCaptainMode,
  });

  factory RidePreferences.fromJson(Map<String, dynamic> json) {
    return RidePreferences(
      acceptBike: json['acceptBike'] ?? false,
      acceptCar: json['acceptCar'] ?? false,
      acceptFemaleOnly: json['acceptFemaleOnly'] ?? false,
      maxRideDistance: (json['maxRideDistance'] as num?)?.toDouble() ?? 0.0,
      pinkCaptainMode: json['pinkCaptainMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acceptBike': acceptBike,
      'acceptCar': acceptCar,
      'acceptFemaleOnly': acceptFemaleOnly,
      'maxRideDistance': maxRideDistance,
      'pinkCaptainMode': pinkCaptainMode,
    };
  }
}

class SearchCriteria {
  final PickupLocation pickupLocation;
  final String serviceType;
  final String vehicleType;
  final String? driverPreference;

  SearchCriteria({
    required this.pickupLocation,
    required this.serviceType,
    required this.vehicleType,
    this.driverPreference,
  });

  factory SearchCriteria.fromJson(Map<String, dynamic> json) {
    return SearchCriteria(
      pickupLocation: PickupLocation.fromJson(json['pickupLocation'] ?? {}),
      serviceType: json['serviceType'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      driverPreference: json['driverPreference'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pickupLocation': pickupLocation.toJson(),
      'serviceType': serviceType,
      'vehicleType': vehicleType,
      'driverPreference': driverPreference,
    };
  }
}

class PickupLocation {
  final String type;
  final List<double> coordinates;

  PickupLocation({
    required this.type,
    required this.coordinates,
  });

  factory PickupLocation.fromJson(Map<String, dynamic> json) {
    return PickupLocation(
      type: json['type'] ?? 'Point',
      coordinates: (json['coordinates'] as List<dynamic>? ?? [])
          .map((coord) => (coord as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}

class SearchStats {
  final int totalDriversFound;
  final int totalVehiclesFound;
  final int driversWithVehicles;
  final int driversInRadius;
  final int finalQualifiedDrivers;

  SearchStats({
    required this.totalDriversFound,
    required this.totalVehiclesFound,
    required this.driversWithVehicles,
    required this.driversInRadius,
    required this.finalQualifiedDrivers,
  });

  factory SearchStats.fromJson(Map<String, dynamic> json) {
    return SearchStats(
      totalDriversFound: json['totalDriversFound'] ?? 0,
      totalVehiclesFound: json['totalVehiclesFound'] ?? 0,
      driversWithVehicles: json['driversWithVehicles'] ?? 0,
      driversInRadius: json['driversInRadius'] ?? 0,
      finalQualifiedDrivers: json['finalQualifiedDrivers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDriversFound': totalDriversFound,
      'totalVehiclesFound': totalVehiclesFound,
      'driversWithVehicles': driversWithVehicles,
      'driversInRadius': driversInRadius,
      'finalQualifiedDrivers': finalQualifiedDrivers,
    };
  }
}

// Request model for socket emit
class QualifiedDriversRequest {
  final PickupLocation pickupLocation;
  final String serviceType;
  final String vehicleType;
  final String driverPreference;

  QualifiedDriversRequest({
    required this.pickupLocation,
    required this.serviceType,
    required this.vehicleType,
    required this.driverPreference,
  });

  Map<String, dynamic> toJson() {
    return {
      'pickupLocation': pickupLocation.toJson(),
      'serviceType': serviceType,
      'vehicleType': vehicleType,
      'driverPreference': driverPreference,
    };
  }

  factory QualifiedDriversRequest.fromJson(Map<String, dynamic> json) {
    return QualifiedDriversRequest(
      pickupLocation: PickupLocation.fromJson(json['pickupLocation'] ?? {}),
      serviceType: json['serviceType'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      driverPreference: json['driverPreference'] ?? '',
    );
  }
}