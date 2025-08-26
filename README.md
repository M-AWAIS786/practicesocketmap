# Socket Map Practice App

A Flutter application that integrates Google Maps with Socket.IO for real-time communication testing.

## Features

### 🗺️ Google Maps Integration
- Interactive Google Maps with your provided API key
- Current location detection and display
- Location markers and info windows
- My Location button for quick navigation

### 🔌 Socket.IO Testing
- Real-time socket connection testing
- Connection status indicator
- Send and receive test messages
- Visual feedback for connection state
- Message history display

### 📱 User Interface
- Clean, modern Material Design UI
- Three-panel layout:
  - Socket status and controls (top)
  - Google Maps view (middle)
  - Socket messages log (bottom)
- Real-time status updates

## Setup Instructions

### Prerequisites
- Flutter SDK installed
- Android Studio or VS Code with Flutter extensions
- Android device or emulator for testing

### API Key Configuration
The Google Maps API key is already configured in the code:
```
AIzaSyBCZ15zo1KEU63Ji7PrMmloxRX0HDU6vV0
```

### Installation
1. Clone or download this project
2. Run `flutter pub get` to install dependencies
3. Connect your Android device or start an emulator
4. Run `flutter run` to launch the app

## Dependencies

```yaml
dependencies:
  google_maps_flutter: ^2.5.0    # Google Maps integration
  socket_io_client: ^2.0.3+1     # Socket.IO client
  location: ^5.0.3                # Location services
  permission_handler: ^11.0.1     # Runtime permissions
```

## How to Test

### 🗺️ Testing Google Maps
1. Launch the app
2. Grant location permissions when prompted
3. The map should load with your current location
4. Tap the floating action button (📍) to center on your location
5. Verify the map displays correctly with your location marker

### 🔌 Testing Socket Connection
1. Look at the top panel - it shows socket status
2. Tap "Connect" to establish socket connection
3. Watch the status indicator change from red (disconnected) to green (connected)
4. Tap "Send Test" to send a test message
5. Check the message log at the bottom to see sent/received messages
6. Tap "Clear" to clear the message history

## Troubleshooting

**Maps not loading:**
- Verify the API key is correct
- Check internet connection
- Ensure location permissions are granted

**Socket connection fails:**
- Check internet connection
- The test server (socket.io) might be temporarily unavailable
- Connection errors will be displayed in the message log

**Location not working:**
- Grant location permissions in device settings
- Enable GPS/Location services
- Try the location button (📍) to refresh
