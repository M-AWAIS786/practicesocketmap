# API URLs from COMPLETE_BOOKING_FLOW_GUIDE.md

This document contains all the API endpoints found in the COMPLETE_BOOKING_FLOW_GUIDE.md file.

## Authentication APIs

- `POST /api/user/login` - User login

## Fare Estimation APIs

- `POST /api/fare/estimate` - Get fare estimation

## Booking Management APIs

### Booking Creation & Details
- `POST /api/bookings/create-booking` - Create new booking
- `GET /api/bookings/:bookingId` - Get booking details

### Booking Lifecycle
- `POST /api/bookings/:bookingId/start` - Start ride
- `POST /api/bookings/:bookingId/complete` - Complete ride
- `POST /api/bookings/cancel-booking` - Cancel booking

### Fare Management
- `POST /api/bookings/raise-fare/:bookingId` - Increase fare
- `POST /api/bookings/lower-fare/:bookingId` - Decrease fare
- `POST /api/bookings/:bookingId/modify-fare` - Driver modify fare
- `POST /api/bookings/respond-fare-offer/:bookingId` - Respond to fare offer

## Driver APIs

### Booking Actions
- `POST /api/bookings/accept-booking/:bookingId` - Accept booking
- `POST /api/bookings/:bookingId/reject` - Reject booking

### Driver Status & Location
- `POST /api/bookings/driver/location` - Update driver location
- `POST /api/bookings/driver/status` - Update driver status
- `POST /api/bookings/driver/auto-accept-settings` - Update auto-accept settings
- `POST /api/bookings/driver/ride-preferences` - Update ride preferences

## Communication APIs

- `POST /api/bookings/:bookingId/send-message` - Send message
- `GET /api/bookings/:bookingId/messages` - Get ride messages

## Rating & Receipt APIs

- `POST /api/bookings/:bookingId/rating` - Submit rating
- `GET /api/bookings/:bookingId/receipt` - Get ride receipt

---

## Summary

**Total API Endpoints: 20**

### By Category:
- **Authentication**: 1 endpoint
- **Fare Estimation**: 1 endpoint
- **Booking Management**: 7 endpoints
- **Driver APIs**: 6 endpoints
- **Communication**: 2 endpoints
- **Rating & Receipt**: 2 endpoints
- **Fare Management**: 4 endpoints

### By HTTP Method:
- **POST**: 17 endpoints
- **GET**: 3 endpoints

### Key Endpoints for Mobile App:
1. `POST /api/user/login` - Authentication
2. `POST /api/fare/estimate` - Fare calculation
3. `POST /api/bookings/create-booking` - Create booking
4. `POST /api/bookings/:bookingId/start` - Start ride
5. `POST /api/bookings/:bookingId/complete` - Complete ride
6. `GET /api/bookings/:bookingId/receipt` - Get receipt
7. `POST /api/bookings/:bookingId/rating` - Submit rating