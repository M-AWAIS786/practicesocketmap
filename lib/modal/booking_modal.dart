class BookingRequest {
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> dropoffLocation;
  final String serviceType;
  final String serviceCategory;
  final String vehicleType;
  final String routeType;
  final int distanceInMeters;
  final int passengerCount;
  final String driverPreference;
  final Map<String, bool> pinkCaptainOptions;
  final String paymentMethod;
  final String? scheduledTime;
  final Map<String, dynamic> driverFilters;
  final Map<String, bool> serviceOptions;
  final List<dynamic> extras;

  BookingRequest({
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.serviceType,
    required this.serviceCategory,
    required this.vehicleType,
    required this.routeType,
    required this.distanceInMeters,
    required this.passengerCount,
    required this.driverPreference,
    required this.pinkCaptainOptions,
    required this.paymentMethod,
    this.scheduledTime,
    required this.driverFilters,
    required this.serviceOptions,
    required this.extras,
  });

  Map<String, dynamic> toJson() {
    return {
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'serviceType': serviceType,
      'serviceCategory': serviceCategory,
      'vehicleType': vehicleType,
      'routeType': routeType,
      'distanceInMeters': distanceInMeters,
      'passengerCount': passengerCount,
      'driverPreference': driverPreference,
      'pinkCaptainOptions': pinkCaptainOptions,
      'paymentMethod': paymentMethod,
      'scheduledTime': scheduledTime,
      'driverFilters': driverFilters,
      'serviceOptions': serviceOptions,
      'extras': extras,
    };
  }
}

class BookingResponse {
  final String bookingId;
  final String status;

  BookingResponse({required this.bookingId, required this.status});

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      bookingId: json['bookingId'] as String,
      status: json['status'] as String,
    );
  }
}

// State for the booking provider
class BookingState {
  final bool isLoading;
  final BookingResponse? bookingResponse;
  final String? error;
  final List<dynamic>? driversFound;

  BookingState({
    this.isLoading = false,
    this.bookingResponse,
    this.error,
    this.driversFound,
  });

  BookingState copyWith({
    bool? isLoading,
    BookingResponse? bookingResponse,
    String? error,
    List<dynamic>? driversFound,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      bookingResponse: bookingResponse ?? this.bookingResponse,
      error: error,
      driversFound: driversFound ?? this.driversFound,
    );
  }
}
