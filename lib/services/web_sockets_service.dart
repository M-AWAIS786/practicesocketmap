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
        'transports': ['websocket'],
        'autoConnect': false,
        if (token != null) 'auth': {'token': token}, // Support auth.token
        if (token != null) 'extraHeaders': {'Authorization': 'Bearer $token'}, // Support Bearer header
      });

      final completer = Completer<void>();
      socket.onConnect((_) {
        log('Connected to Socket.IO: $url');
        if (!completer.isCompleted) completer.complete();
      });

      socket.onConnectError((error) {
        log('Connection error: $url, $error');
        if (!completer.isCompleted) {
          completer.completeError(FetchDataException('Connection failed: $error'));
        }
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
      log('Received $event on $url: $data');
      callback(data);
    });
  }

  void disconnect(String url) {
    if (_sockets.containsKey(url)) {
      _sockets[url]!.disconnect();
      _sockets.remove(url);
      log('Socket disconnected: $url');
    }
  }
}