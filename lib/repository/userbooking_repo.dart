import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:practicesocketmap/app_url.dart';
import 'package:practicesocketmap/modal/booking_modal.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:practicesocketmap/services/web_sockets_service.dart';

// Booking repository
class BookingRepository {
  final SocketApiServices _socketApiServices = SocketApiServices();

  Future<BookingResponse> createBooking(String token, dynamic data) async {
    try {
      // Step 1: Call REST API to create booking
      final response = await http.post(
        Uri.parse('${AppUrls.baseUrl}/bookings/create-booking'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      log("our booking response is ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final bookingResponse = BookingResponse.fromJson(responseData);

        // Step 2: Emit Socket.IO event
        await _socketApiServices.connect(AppUrls.baseUrl, token);
        _socketApiServices.emit(AppUrls.baseUrl, 'create_booking', {
          'bookingId': bookingResponse.bookingId,
          'userId': data.toJson()['userId'] ?? '', // Fallback if userId is not in BookingRequest
        });

        return bookingResponse;
      } else {
        throw Exception('Failed to create booking: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in createBooking: $e');
      rethrow;
    }
  }

  void listenForBookingRequestCreated(void Function(List<dynamic> driversFound) onDriversFound) {
    // Fix: Pass the URL as the first argument to _socketApiServices.on
    _socketApiServices.on(AppUrls.baseUrl, 'booking_request_created', (data) {
      developer.log('Booking request created: $data');
      onDriversFound(data['driversFound'] as List<dynamic>? ?? []);
    });
  }
}

// Riverpod provider
final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier(ref.watch(bookingRepositoryProvider));
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) => BookingRepository());

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingRepository _repository;

  BookingNotifier(this._repository) : super(BookingState());

  Future<void> createBooking(String token, BookingRequest request) async {
    state = state.copyWith(isLoading: true, error: null, driversFound: null);
    try {
      // !!!!!!!!!!!!! final car recover data 
//       final data = {
//   "pickupLocation": {
//     "coordinates": [55.2708, 25.2048],
//     "address": "Sheikh Zayed Road, Dubai"
//   },
//   "dropoffLocation": {
//     "coordinates": [55.2744, 25.1972],
//     "address": "Dubai Auto Service Center"
//   },
//   "serviceType": "car recovery",
//   "serviceCategory": "towing services",
//   "vehicleType": "flatbed towing",
//   "routeType": "one_way",
//   "distanceInMeters": 8000,
//   "passengerCount": 2,
//   "serviceDetails": {
//     "carRecovery": {
//       "issueDescription": "Engine won't start, battery seems dead",
//       "urgencyLevel": "high",
//       "needHelper": false,
//       "wheelchairHelper": false,
//       "vehicleMake": "Toyota",
//       "vehicleModel": "Camry",
//       "vehicleYear": "2020",
//       "licensePlate": "ABC-1234",
//       "vehicleColor": "White",
//       "vehicleType": "Sedan",
//       "isLuxury": false,
//       "isHeavyDuty": false,
//       "hasTrailer": false,
//       "trailerDetails": null,
//       "chassisNumber": "ABC123456789",
//       "registrationExpiryDate": "2025-12-31",
//       "companyName": "Toyota Motors",
//       "vehicleOwnerName": "John Doe"
//     }
//   },
//   "itemDetails": [],
//   "driverPreference": "nearby",
//   "pinnedDriverId": null,
//   "pinkCaptainOptions": {
//     "femalePassengersOnly": false,
//     "familyRides": false,
//     "safeZoneRides": false,
//     "familyWithGuardianMale": false,
//     "maleWithoutFemale": false,
//     "noMaleCompanion": false
//   },
//   "paymentMethod": "cash",
//   "scheduledTime": null,
//   "driverFilters": {
//     "vehicleModel": null,
//     "specificDriverId": null,
//     "searchRadius": 20
//   },
//   "serviceOptions": {
//     "emergencyService": true,
//     "insurance": true,
//     "roadsideAssistance": true,
//     "fuelDelivery": false,
//     "batteryJumpStart": false,
//     "tireChange": false,
//     "lockoutService": false,
//     "winchingService": false,
//     "specializedRecovery": {
//       "luxuryVehicles": false,
//       "heavyDutyVehicles": false,
//       "motorcycles": false,
//       "boats": false
//     }
//   },
//   "extras": [
//     { "name": "Fuel Delivery", "count": 1, "price": 25 },
//     { "name": "Battery Jump Start", "count": 1, "price": 30 },
//     { "name": "Tire Change", "count": 1, "price": 40 }
//   ]
// };
final data = {
  "pickupLocation": {
    "coordinates": [55.2708, 25.2048],
    "address": "Dubai Mall, Dubai, UAE"
  },
  "dropoffLocation": {
    "coordinates": [55.2744, 25.1972],
    "address": "Burj Khalifa, Dubai, UAE"
  },
  "serviceType": "car cab",
  "serviceCategory": "transport",
  "vehicleType": "economy",
  "routeType": "one_way",
  "distanceInMeters": 2500,
  "passengerCount": 2,
  "wheelchairAccessible": false,
  "driverPreference": "nearby",
  "pinnedDriverId": null,
  "pinkCaptainOptions": {
    "femalePassengersOnly": false,
    "familyRides": false,
    "safeZoneRides": false,
    "familyWithGuardianMale": false,
    "maleWithoutFemale": false,
    "noMaleCompanion": false
  },
  "paymentMethod": "cash",
  "scheduledTime": null,
  "driverFilters": {
    "vehicleModel": null,
    "specificDriverId": null,
    "searchRadius": 20
  },
  "serviceOptions": {
    "airConditioning": true,
    "music": false,
    "wifi": false,
    "childSeat": false,
    "petFriendly": false,
    "wheelchairAccessible": false,
    "premiumFeatures": {
      "leatherSeats": false,
      "climateControl": false,
      "entertainmentSystem": false
    }
  },
  "extras": [
    { "name": "Child Seat", "count": 1, "price": 15 },
    { "name": "Pet Carrier", "count": 1, "price": 10 }
  ]
};
      final bookingResponse = await _repository.createBooking(token, data);
      _repository.listenForBookingRequestCreated((driversFound) {
        state = state.copyWith(
          isLoading: false,
          bookingResponse: bookingResponse,
          driversFound: driversFound,
        );
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}