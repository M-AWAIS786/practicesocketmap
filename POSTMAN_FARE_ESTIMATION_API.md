# Postman API Collection for Fare Estimation

## Base Configuration

**Base URL:** `http://159.198.74.112:3001`
**API Endpoint:** `POST /api/fare/estimate-fare`
**Full URL:** `http://159.198.74.112:3001/api/fare/estimate-fare`

## Headers

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4YWFjMjNjOTc4NDUwYjdjZTQ5NjMyZiIsImlhdCI6MTc1NjA0OTYyNSwiZXhwIjoxNzU4NjQxNjI1fQ.IvUCEXC6Pf1KKnNqedYxnZDENIKPW0WRfH_ChSmqgpo
Content-Type: application/json
```

## Request Body Examples

### 1. Basic Car Cab Request

```json
{
  "pickupLocation": {
    "latitude": 24.8607,
    "longitude": 67.0011
  },
  "dropoffLocation": {
    "latitude": 24.8615,
    "longitude": 67.0025
  },
  "serviceType": "car cab",
  "serviceCategory": "standard",
  "vehicleType": "economy",
  "routeType": "one_way",
  "distanceInMeters": 12500,
  "estimatedDuration": 25,
  "trafficCondition": "moderate",
  "isNightTime": false,
  "demandRatio": 1.0,
  "waitingMinutes": 0
}
```

### 2. Car Cab with Round Trip

```json
{
  "pickupLocation": {
    "latitude": 24.8607,
    "longitude": 67.0011
  },
  "dropoffLocation": {
    "latitude": 24.8615,
    "longitude": 67.0025
  },
  "serviceType": "car cab",
  "serviceCategory": "standard",
  "vehicleType": "premium",
  "routeType": "round_trip",
  "distanceInMeters": 12500,
  "estimatedDuration": 25,
  "trafficCondition": "moderate",
  "isNightTime": false,
  "demandRatio": 1.0,
  "waitingMinutes": 0,
  "serviceDetails": {
    "rideType": "premium",
    "passengerCount": 2,
    "luggageCount": 2
  },
  "serviceOptions": {
    "roundTrip": true,
    "discount": 10,
    "freeStayMinutes": 30
  }
}
```

### 3. Bike Service

```json
{
  "pickupLocation": {
    "latitude": 24.8607,
    "longitude": 67.0011
  },
  "dropoffLocation": {
    "latitude": 24.8615,
    "longitude": 67.0025
  },
  "serviceType": "bike",
  "serviceCategory": "standard",
  "vehicleType": "economy",
  "routeType": "one_way",
  "distanceInMeters": 8000,
  "estimatedDuration": 15,
  "trafficCondition": "light",
  "isNightTime": false,
  "demandRatio": 1.0,
  "waitingMinutes": 0,
  "serviceDetails": {
    "rideType": "economy",
    "helmetRequired": true
  },
  "serviceOptions": {
    "roundTrip": false,
    "discount": 0,
    "freeStayMinutes": 0
  }
}
```

### 4. Car Recovery Service

```json
{
  "pickupLocation": {
    "latitude": 24.8607,
    "longitude": 67.0011
  },
  "dropoffLocation": {
    "latitude": 24.8615,
    "longitude": 67.0025
  },
  "serviceType": "car recovery",
  "serviceCategory": "standard",
  "vehicleType": "flatbed",
  "routeType": "one_way",
  "distanceInMeters": 15000,
  "estimatedDuration": 35,
  "trafficCondition": "moderate",
  "isNightTime": false,
  "demandRatio": 1.2,
  "waitingMinutes": 10,
  "serviceDetails": {
    "recoveryType": "flatbed",
    "subcategory": "towing services",
    "vehicleCondition": "operational",
    "accessibilityLevel": "standard"
  }
}
```

### 5. Shifting & Movers Service

```json
{
  "pickupLocation": {
    "latitude": 24.8607,
    "longitude": 67.0011
  },
  "dropoffLocation": {
    "latitude": 24.8615,
    "longitude": 67.0025
  },
  "serviceType": "shifting & movers",
  "serviceCategory": "standard",
  "vehicleType": "medium truck",
  "routeType": "one_way",
  "distanceInMeters": 20000,
  "estimatedDuration": 45,
  "trafficCondition": "heavy",
  "isNightTime": false,
  "demandRatio": 1.1,
  "waitingMinutes": 15,
  "serviceDetails": {
    "moveType": "residential",
    "vehicleSize": "medium truck",
    "floorLevel": 2,
    "elevatorAccess": true
  },
  "itemDetails": [
    {
      "category": "furniture",
      "items": [
        {"name": "sofa", "quantity": 1, "weight": 50},
        {"name": "bed", "quantity": 2, "weight": 40}
      ]
    },
    {
      "category": "appliances",
      "items": [
        {"name": "refrigerator", "quantity": 1, "weight": 80},
        {"name": "washing_machine", "quantity": 1, "weight": 60}
      ]
    }
  ],
  "serviceOptions": {
    "packingHelper": true,
    "loadingHelper": true,
    "fixingHelper": false,
    "roundTrip": true,
    "discount": 10,
    "freeStayMinutes": 30
  }
}
```

## Service Type Options

### Car Cab Vehicle Types:
- `economy`
- `premium` 
- `xl` (Group Ride)
- `family`
- `luxury` (VIP)

### Bike Vehicle Types:
- `economy`
- `premium`
- `vip`

### Car Recovery Vehicle Types:
- `flatbed`
- `wheel_lift`
- `winch_truck`
- `heavy_recovery`

### Shifting & Movers Vehicle Types:
- `mini_pickup`
- `suzuki_carry`
- `small_van`
- `medium_truck`
- `mazda`
- `covered_van`
- `large_truck`
- `6_wheeler`
- `container_truck`

## Traffic Conditions:
- `light`
- `moderate`
- `heavy`
- `severe`

## Route Types:
- `one_way`
- `round_trip`

## Expected Response Format

```json
{
  "success": true,
  "data": {
    "estimatedFare": 25.50,
    "baseFare": 20.00,
    "distanceFare": 3.50,
    "timeFare": 2.00,
    "surcharges": {
      "nightTime": 0,
      "demand": 0,
      "traffic": 0
    },
    "discounts": {
      "roundTrip": 2.50
    },
    "currency": "AED",
    "estimatedDuration": 25,
    "distanceInKm": 12.5
  }
}
```

## Postman Setup Instructions

1. **Create New Collection:** Name it "Ride Booking API"

2. **Add Environment Variables:**
   - `base_url`: `http://159.198.74.112:3001`
   - `token`: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4YWFjMjNjOTc4NDUwYjdjZTQ5NjMyZiIsImlhdCI6MTc1NjA0OTYyNSwiZXhwIjoxNzU4NjQxNjI1fQ.IvUCEXC6Pf1KKnNqedYxnZDENIKPW0WRfH_ChSmqgpo`

3. **Create Request:**
   - Method: `POST`
   - URL: `{{base_url}}/api/fare/estimate-fare`
   - Headers:
     - `Authorization`: `Bearer {{token}}`
     - `Content-Type`: `application/json`
   - Body: Raw JSON (use any of the examples above)

4. **Test Different Scenarios:**
   - Create separate requests for each service type
   - Test with different vehicle types
   - Test round trip vs one way
   - Test with different traffic conditions
   - Test night time surcharges

## Common Issues & Troubleshooting

1. **401 Unauthorized:** Check if the token is valid and properly formatted
2. **404 Not Found:** Verify the endpoint URL is correct
3. **400 Bad Request:** Check the JSON body format and required fields
4. **500 Internal Server Error:** Check server logs or contact backend team

## Additional Test Endpoints

### Health Check
- **URL:** `GET {{base_url}}/api/health`
- **Headers:** `Authorization: Bearer {{token}}`

### Socket Connection Test
- **URL:** `{{base_url}}` (WebSocket connection)
- **Auth:** `{"token": "{{token}}"}`