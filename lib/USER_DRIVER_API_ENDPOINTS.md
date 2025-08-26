# User & Driver API Endpoints

This document contains API endpoints specifically for mobile users and drivers, excluding admin-only APIs.

## Table of Contents

1. [Authentication & Connection](#authentication--connection)
2. [Socket.IO Events](#socketio-events)
3. [Fare Estimation](#fare-estimation)
4. [Fare Adjustment](#fare-adjustment)
5. [Booking Creation](#booking-creation)
6. [Real-time Booking Flow](#real-time-booking-flow)
7. [Driver Actions](#driver-actions)
8. [User Actions](#user-actions)
9. [Receipt Generation](#receipt-generation)

---

## 1. Authentication & Connection

### User Registration
```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "securePassword123",
  "role": "user" // or "driver"
}
```

### User Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securePassword123"
}
```

### Set Vehicle Ownership (Driver)
```http
POST /api/auth/set-vehicle-ownership
Authorization: Bearer jwt_token
Content-Type: application/json

{
  "hasVehicle": true,
  "vehicleType": "sedan"
}
```

### Socket.IO Connection
```javascript
const socket = io('http://localhost:3001', {
  auth: {
    token: 'your_jwt_token_here'
  }
});
```

---

## 2. Socket.IO Events

### User Connection Events
```javascript
// Join user room
socket.emit('join_user_room', {
  userId: 'user_id_here'
});

// Update user location
socket.emit('update_user_location', {
  coordinates: [77.2090, 28.6139],
  address: "Connaught Place, New Delhi"
});
```

### Driver Connection Events
```javascript
// Join driver room
socket.emit('join_driver_room', {
  driverId: 'driver_id_here'
});

// Update driver location
socket.emit('update_driver_location', {
  coordinates: [77.2090, 28.6139],
  address: "Current Location",
  isAvailable: true
});

// Set auto-accept preferences
socket.emit('set_auto_accept', {
  enabled: true,
  maxDistance: 5, // km
  serviceTypes: ['car cab', 'bike']
});
```

### Graceful Disconnection
```javascript
// User disconnection
socket.emit('user_disconnect', {
  userId: 'user_id_here'
});

// Driver disconnection
socket.emit('driver_disconnect', {
  driverId: 'driver_id_here'
});
```

---

## 3. Fare Estimation

### Car Cab Fare Estimation
```http
POST /api/fare-estimation/estimate
Authorization: Bearer jwt_token
Content-Type: application/json

{
  "pickupLocation": {
    "coordinates": [77.2090, 28.6139],
    "address": "Connaught Place, New Delhi"
  },
  "dropoffLocation": {
    "coordinates": [77.3910, 28.5355],
    "address": "Noida Sector 62"
  },
  "serviceType": "car cab",
  "serviceCategory": "standard",
  "vehicleType": "economy",
  "routeType": "one_way",
  "distanceInMeters": 12500,
  "estimatedDuration": 25,
  "trafficCondition": "moderate",
  "isNightTime": false,
  "demandRatio": 1.2,
  "waitingMinutes": 0,
  "scheduledTime": null
}
```

### Bike Service Fare Estimation
```http
POST /api/fare-estimation/estimate
Authorization: Bearer jwt_token
Content-Type: application/json

{
  "pickupLocation": {
    "coordinates": [77.2090, 28.6139],
    "address": "Connaught Place, New Delhi"
  },
  "dropoffLocation": {
    "coordinates": [77.3910, 28.5355],
    "address": "Noida Sector 62"
  },
  "serviceType": "bike",
  "vehicleType": "standard",
  "routeType": "one_way",
  "distanceInMeters": 12500,
  "estimatedDuration": 20,
  "trafficCondition": "light",
  "isNightTime": false,
  "demandRatio": 1.0,
  "waitingMinutes": 0,
  "scheduledTime": null
}
```

### Car Recovery Service Fare Estimation
```http
POST /api/fare-estimation/estimate
Authorization: Bearer jwt_token
Content-Type: application/json

{
  "pickupLocation": {
    "coordinates": [55.2708, 25.2048],
    "address": "Dubai Mall, Dubai"
  },
  "dropoffLocation": {
    "coordinates": [55.1394, 25.0657],
    "address": "Dubai International Airport"
  },
  "serviceType": "car recovery",
  "serviceCategory": "flatbed towing",
  "vehicleType": "flatbed",
  "routeType": "one_way",
  "distanceInMeters": 15000,
  "estimatedDuration": 30,
  "trafficCondition": "moderate",
  "isNightTime": false,
  "demandRatio": 1.0,
  "waitingMinutes": 0,
  "scheduledTime": null,
  "vehicleCondition": "not_starting"
}
```

### Shifting & Movers Service Fare Estimation
```http
POST /api/fare-estimation/estimate
Authorization: Bearer jwt_token
Content-Type: application/json

{
  "pickupLocation": {
    "coordinates": [77.2090, 28.6139],
    "address": "Connaught Place, New Delhi"
  },
  "dropoffLocation": {
    "coordinates": [77.3910, 28.5355],
    "address": "Noida Sector 62"
  },
  "serviceType": "shifting & movers",
  "vehicleType": "small_truck",
  "routeType": "one_way",
  "distanceInMeters": 15000,
  "estimatedDuration": 45,
  "trafficCondition": "moderate",
  "isNightTime": false,
  "demandRatio": 1.0,
  "waitingMinutes": 0,
  "scheduledTime": null,
  "floors": 3,
  "hasElevator": false,
  "packingRequired": true,
  "assemblyRequired": true,
  "items": {
    "bed": 2,
    "sofa": 1,
    "fridge": 1,
    "dining_table": 1
  },
  "extras": [
    {"name": "custom_box", "count": 5},
    {"name": "fragile_items", "count": 3}
  ],
  "serviceDetails": {
    "shiftingMovers": {
      "selectedServices": {
        "loadingUnloading": true,
        "packing": true,
        "fixing": false,
        "helpers": true,
        "wheelchairHelper": false
      },
      "pickupFloorDetails": {
        "floor": 3,
        "accessType": "stairs",
        "hasLift": false
      },
      "dropoffFloorDetails": {
        "floor": 2,
        "accessType": "lift",
        "hasLift": true
      }
    }
  },
  "serviceOptions": {
    "packingMaterial": true,
    "disassemblyService": true,
    "storageService": false,
    "insuranceCoverage": true
  },
  "paymentMethod": "cash"
}
```

---

## 4. Fare Adjustment

### Adjust Fare (User)
```http
POST /api/fare/adjust-fare
Authorization: Bearer jwt_token
Content-Type: application/json

{
  "originalFare": 245.50,
  "adjustedFare": 260.00,
  "serviceType": "car cab"
}
```

### Fare Modification (Driver)
```javascript
// Driver proposes fare modification
socket.emit('modify_booking_fare', {
  requestId: 'booking_id_here',
  newFare: 250.00,
  reason: 'Traffic conditions'
});

// Listen for modification response
socket.on('fare_modification_sent', (data) => {
  console.log('Modification request sent:', data);
});
```

### User Response to Fare Modification
```javascript
// User receives modification request
socket.on('fare_modification_request', (data) => {
  console.log('Driver requested fare change:', data);
});

// User responds to modification
socket.emit('respond_to_fare_modification', {
  requestId: 'booking_id_here',
  response: 'accepted', // or 'rejected'
  reason: 'Agreed to new fare'
});

// Listen for response confirmation
socket.on('fare_modification_responded', (data) => {
  console.log('Response sent:', data);
});
```

---

## 5. Booking Creation

### Car Cab Booking
```http
POST /api/bookings/create-booking
Authorization: Bearer jwt_token
Content-Type: application/json

{
  "pickupLocation": {
    "coordinates": [77.2090, 28.6139],
    "address": "Connaught Place, New Delhi"
  },
  "dropoffLocation": {
    "coordinates": [77.3910, 28.5355],
    "address": "Noida Sector 62"
  },
  "serviceType": "car cab",
  "serviceCategory": "standard",
  "vehicleType": "economy",
  "routeType": "one_way",
  "driverPreference": "nearby",
  "pinnedDriverId": null,
  "offeredFare": 245.50,
  "distanceInMeters": 12500,
  "estimatedDuration": 25,
  "trafficCondition": "moderate",
  "isNightTime": false,
  "demandRatio": 1.2,
  "waitingMinutes": 0,
  "scheduledTime": null,
  "passengerCount": 2,
  "wheelchairAccessible": false,
  "paymentMethod": "cash",
  "pinkCaptainOptions": {
    "femalePassengersOnly": false,
    "familyRides": true,
    "safeZoneRides": false
  },
  "driverFilters": {
    "minRating": 4.0,
    "preferredLanguages": ["english", "hindi"],
    "vehicleAge": 5,
    "experienceYears": 2
  },
  "extras": ["child_seat", "music_preference"]
}
```

### Bike Booking
```http
POST /api/bookings/create-booking
Authorization: Bearer jwt_token
Content-Type: application/json

{
  "pickupLocation": {
    "coordinates": [77.2090, 28.6139],
    "address": "Connaught Place, New Delhi"
  },
  "dropoffLocation": {
    "coordinates": [77.3910, 28.5355],
    "address": "Noida Sector 62"
  },
  "serviceType": "bike",
  "vehicleType": "standard",
  "routeType": "one_way",
  "driverPreference": "nearby",
  "offeredFare": 85.00,
  "distanceInMeters": 12500,
  "estimatedDuration": 20,
  "trafficCondition": "light",
  "isNightTime": false,
  "demandRatio": 1.0,
  "waitingMinutes": 0,
  "scheduledTime": null,
  "passengerCount": 1,
  "paymentMethod": "cash",
  "driverFilters": {
    "minRating": 4.0,
    "preferredLanguages": ["english", "hindi"],
    "vehicleAge": 3,
    "experienceYears": 1
  },
  "extras": ["helmet_provided", "rain_protection"]
}
```

---

## 6. Real-time Booking Flow

### User Events (Listen)
```javascript
// Booking creation confirmation
socket.on('booking_request_created', (data) => {
  console.log('Booking created:', data.bookingId);
  console.log('Searching for drivers...');
});

// Driver found and accepted
socket.on('booking_accepted', (data) => {
  console.log('Driver found:', data.driver);
  console.log('Driver accepted at:', data.acceptedAt);
});

// No drivers available
socket.on('no_drivers_available', (data) => {
  console.log('No drivers found:', data.bookingId);
});

// Driver location updates
socket.on('driver_location_update', (data) => {
  console.log('Driver location:', data.driverLocation.coordinates);
});

// Ride status updates
socket.on('ride_status_update', (data) => {
  console.log('Ride status:', data.status);
  // Status: 'driver_arriving', 'driver_arrived', 'ride_started', 'ride_completed'
});

// Ride completed with PGP points
socket.on('ride_completed', (data) => {
  console.log('Ride completed!');
  console.log('PGP Points earned:', data.pgpEarned);
  console.log('Total PGP:', data.totalPgp);
  console.log('Total TGP:', data.totalTgp);
});
```

### User Actions (Emit)
```javascript
// Cancel booking request
socket.emit('cancel_booking_request', {
  requestId: 'booking_id_here',
  reason: 'Changed plans'
});

// Increase fare and resend to drivers
socket.emit('increase_fare_and_resend', {
  requestId: 'booking_id_here',
  newFare: 280.00,
  reason: 'Need driver urgently'
});
```

---

## 7. Driver Actions

### Driver Events (Listen)
```javascript
// New booking request
socket.on('new_booking_request', (data) => {
  console.log('New booking request:', data.requestId);
  console.log('Pickup:', data.pickupLocation.address);
  console.log('Fare:', data.offeredFare);
  console.log('Distance:', data.distanceFromDriver, 'km');
});

// Booking cancelled
socket.on('booking_cancelled', (data) => {
  console.log('Booking cancelled:', data.bookingId);
  console.log('Reason:', data.reason);
});

// Fare modification response from user
socket.on('fare_modification_response', (data) => {
  console.log('User responded to fare modification:', data);
});
```

### Driver Actions (Emit)
```javascript
// Accept booking
socket.emit('accept_booking_request', {
  requestId: 'booking_id_here',
  estimatedArrival: 5 // minutes
});

// Reject booking
socket.emit('reject_booking_request', {
  requestId: 'booking_id_here',
  reason: 'Too far'
});

// Update ride status
socket.emit('update_ride_status', {
  bookingId: 'booking_id_here',
  status: 'driver_arrived' // or 'ride_started', 'ride_completed'
});

// Start ride
socket.emit('start_ride', {
  bookingId: 'booking_id_here'
});

// Complete ride
socket.emit('complete_ride', {
  bookingId: 'booking_id_here',
  finalLocation: {
    coordinates: [77.3915, 28.5360],
    address: "Final destination"
  },
  actualDistance: 12.8,
  actualDuration: 28
});
```

---

## 8. User Actions

### Booking Management
```javascript
// Cancel booking
socket.emit('cancel_booking', {
  bookingId: 'booking_id_here',
  reason: 'Changed plans'
});

// Listen for cancellation confirmation
socket.on('booking_cancelled', (data) => {
  console.log('Booking cancelled:', data);
});
```

### Error Handling
```javascript
// Listen for booking errors
socket.on('booking_error', (error) => {
  console.error('Booking error:', error);
});

// General socket errors
socket.on('error', (error) => {
  console.error('Socket error:', error);
});
```

---

## 9. Receipt Generation

### Get Booking Receipt
```http
GET /api/bookings/:bookingId/receipt
Authorization: Bearer jwt_token

Response:
{
  "success": true,
  "message": "Receipt retrieved successfully",
  "receipt": {
    "receiptNumber": "AAAO-1642234567-ABC123",
    "generatedAt": "2024-01-15T11:05:00Z",
    "bookingId": "booking_id",
    "fare": 250,
    "distance": 15.5,
    "duration": 25,
    "serviceType": "car_cab",
    "vehicleType": "sedan",
    "paymentMethod": "wallet",
    "pickupLocation": {
      "address": "Pickup Address",
      "coordinates": [77.2090, 28.6139]
    },
    "dropoffLocation": {
      "address": "Dropoff Address",
      "coordinates": [77.2310, 28.6280]
    },
    "finalLocation": {
      "address": "Final Destination",
      "coordinates": [77.2315, 28.6285]
    },
    "fareBreakdown": {
      "baseFare": 50,
      "distanceFare": 150,
      "timeFare": 30,
      "platformFee": 20
    }
  }
}
```

---

## Key Features

- **TGP/PGP System**: Integrated gaming points system (50 points for rides ≥₹100)
- **5km Radius Limits**: Smart driver search with city-wide Pink Captain access
- **Pink Captain**: Female driver options with safety features
- **Socket-Connected Drivers**: Real-time driver availability
- **Dynamic Pricing**: Traffic, night, and surge pricing with detailed breakdown
- **Comprehensive Service Types**: Car cab, bike, car recovery, shifting & movers
- **Advanced Filtering**: Driver preferences, vehicle specifications, and service options
- **Real-time Updates**: Live tracking and status updates
- **Fare Modification**: Driver-initiated fare changes with user approval
- **Auto-Accept**: Driver preferences for automatic booking acceptance

---

## Testing

The server is running at `http://localhost:3001` with all features implemented and tested.

### Complete Flow Example (REST-First Approach)

1. **Connect** → Authenticate with JWT token via Socket.IO
2. **Join Room** → User/Driver joins appropriate room
3. **Estimate Fare** → Get pricing via REST API (`POST /api/fare-estimation/estimate`)
4. **Adjust Fare** → Optional fare adjustment via REST API (`POST /api/fare/adjust-fare`)
5. **Create Booking** → Submit booking via REST API (`POST /api/bookings/create-booking`)
6. **Automatic Real-time** → Server automatically finds drivers and sends notifications
7. **Track Progress** → Real-time updates until completion via Socket.IO events
8. **Earn Points** → Automatic PGP distribution for qualifying rides

**Key Integration Points:**
- REST API handles validation, persistence, business logic, and triggers real-time operations
- Socket.IO handles real-time driver matching and status updates automatically
- No manual intervention required between REST API call and real-time updates
- Both systems work together seamlessly for optimal user experience