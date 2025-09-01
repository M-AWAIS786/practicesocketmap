import 'dart:async';
import 'dart:developer';
import 'package:practicesocketmap/services/web_sockets_service.dart';

class SocketRepository {
  final _socketApiServices = SocketApiServices();
  String? _currentUrl;

  // Connect to Socket.IO and join user room
  Future<void> connectAndJoinUserRoom(String url, String token, String userId, String event) async {
    try {
      log('Connecting to Socket.IO and joining room for user: $userId');
      _currentUrl = url; // Store the URL for later use
      await _socketApiServices.connect(url, token);
      _socketApiServices.emit(url, event, {'userId': userId});
      log('Emitted $event for user: $userId');
    } catch (e) {
      log('Error in connectAndJoinRoom: $e');
      rethrow;
    }
  }

  Future<void> connectAndJoinDriverRoom(String url, String token, String userId, String event)async{
     try{
        await _socketApiServices.connect(url, token);
        _socketApiServices.emit(url, event, {'userId': userId});
        log('Emitted $event for driver: $userId');
     }catch(e){
      log('Error in connectAndJoinDriverRoom: $e');
     }
  }

  // Disconnect
  void disconnect() {
    if (_currentUrl != null) {
      _socketApiServices.disconnect(_currentUrl!);
      _currentUrl = null;
    }
  }
}