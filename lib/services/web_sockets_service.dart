import 'dart:async';
import 'dart:developer';
import 'package:practicesocketmap/services/app_exceptions.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketApiServices {
  final Map<String, IO.Socket> _sockets = {};

  Future<void> connect(String url, String? token) async {
    if (_sockets.containsKey(url)) {
      if (_sockets[url]!.connected) {
        log('Socket already connected to: $url');
        return;
      }
      log('Reconnecting existing socket to: $url');
      _sockets[url]!.connect();
      return;
    }

    try {
      log('Connecting to Socket.IO: $url');
      final socket = IO.io(url, <String, dynamic>{
        'transports': ['websocket', 'polling'], // Add polling like HTML
        'autoConnect': false,
        'timeout': 20000, // 20 second timeout like HTML
        'forceNew': true, // Force new connection like HTML
        if (token != null) 'auth': {'token': token}, // Primary auth method like HTML
        if (token != null) 'extraHeaders': {'Authorization': 'Bearer $token'}, // Fallback auth
      });

      final completer = Completer<void>();
      socket.onConnect((_) {
        log('✅ Connected to Socket.IO: $url');
        print('🚀 Socket connection established to: $url');
        if (!completer.isCompleted) completer.complete();
      });

      socket.onConnectError((error) {
        log('❌ Connection error: $url, $error');
        if (!completer.isCompleted) {
          completer.completeError(FetchDataException('Connection failed: $error'));
        }
      });

      // Add authentication listener like HTML
      socket.on('authenticated', (data) {
        log('🔐 Authenticated as: ${data['user']['email']} (${data['user']['role']})');
      });

      // Add disconnect listener like HTML
      socket.onDisconnect((reason) {
        log('❌ Disconnected from $url: $reason');
      });

      socket.connect();
      _sockets[url] = socket;

      await completer.future.timeout(
        Duration(seconds: 10),
        onTimeout: () {
          if (!_sockets[url]!.connected) {
            throw RequestTimeOutException('Socket connection timed out: $url');
          }
          return;
        },
      );

      socket.onError((error) => log('Socket error: $url, $error'));
    } catch (e) {
      log('Socket connection failed: $url, $e');
      throw FetchDataException('Failed to connect: $e');
    }
  }

  void emit(String url, String event, dynamic data) {
    if (!_sockets.containsKey(url)) {
      throw FetchDataException('Socket not initialized for URL: $url');
    }
    if (!_sockets[url]!.connected) {
      throw FetchDataException('Socket not connected to: $url');
    }
    log('Emitting $event on $url: $data');
    _sockets[url]!.emit(event, data);
  }

  // Check if socket is connected
  bool isConnected(String url) {
    return _sockets.containsKey(url) && _sockets[url]!.connected;
  }

  // Get connection status
  String getConnectionStatus(String url) {
    if (!_sockets.containsKey(url)) {
      return 'Not initialized';
    }
    return _sockets[url]!.connected ? 'Connected' : 'Disconnected';
  }

  void on(String url, String event, Function(dynamic) callback) {
    if (!_sockets.containsKey(url)) {
      throw FetchDataException('Socket not initialized: $url');
    }
    _sockets[url]!.on(event, (data) {
      log('📡 Received $event on $url: $data');
      callback(data);
    });
  }

  // Listen for location update confirmations and errors
  void listenForLocationConfirmations(String url) {
    if (!_sockets.containsKey(url)) return;
    
    final socket = _sockets[url]!;
    
    // Listen for location update confirmations
    socket.on('location_updated', (data) {
      log('📍 Location update confirmed: $data');
    });
    
    // Listen for location update errors
    socket.on('location_error', (data) {
      log('❌ Location update error: $data');
    });
  }
  
  // Listen for live location events
  void listenForLiveLocationEvents(String url, Function(dynamic) onLiveLocationResponse, Function(dynamic) onLiveLocationError) {
    if (!_sockets.containsKey(url)) return;
    
    final socket = _sockets[url]!;
    
    // Listen for live location requests
    socket.on('get_live_location', (data) {
      log('📍 Live location requested: $data');
      // This event is typically sent by the server to request current location
      // The client should respond with current location
    });
    
    // Listen for live location responses
    socket.on('live_location_response', (data) {
      log('📍 Live location response received: $data');
      onLiveLocationResponse(data);
    });
    
    // Listen for live location errors
    socket.on('live_location_error', (data) {
      log('❌ Live location error: $data');
      onLiveLocationError(data);
    });
  }
  
  // Emit live location request
  void requestLiveLocation(String url, String targetUserId) {
    if (!_sockets.containsKey(url)) return;
    
    final socket = _sockets[url]!;
    socket.emit('get_live_location', {
      'targetUserId': targetUserId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    log('📍 Live location requested for user: $targetUserId');
  }
  
  // Respond to live location request
  void respondToLiveLocationRequest(String url, double latitude, double longitude, String requesterId) {
    if (!_sockets.containsKey(url)) return;
    
    final socket = _sockets[url]!;
    socket.emit('live_location_response', {
      'coordinates': [longitude, latitude], // Server expects [longitude, latitude] format
      'requesterId': requesterId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    log('📍 Live location response sent to: $requesterId');
  }

  void disconnect(String url) {
    if (_sockets.containsKey(url)) {
      _sockets[url]!.disconnect();
      _sockets.remove(url);
      log('Socket disconnected: $url');
    }
  }
}