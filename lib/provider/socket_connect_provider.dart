import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:practicesocketmap/repository/login_repo.dart';
import 'package:practicesocketmap/services/app_exceptions.dart';
import 'package:practicesocketmap/services/driver_auth_service.dart';
import 'package:practicesocketmap/services/web_sockets_service.dart';

final socketConnectProvider = StateNotifierProvider<SocketConnectNotifier, AsyncValue<String?>>((ref) {
  return SocketConnectNotifier(ref);
});

class SocketConnectNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;
  final _socketRepo = SocketRepository();
  final _socketApiServices = SocketApiServices();
  final String _serverUrl = 'http://159.198.74.112:3001';
  bool _isConnected = false;

  SocketConnectNotifier(this._ref) : super(const AsyncData(null));

  bool get isConnected => _isConnected;

  Future<void> connectSocket() async {
    state = const AsyncLoading();
    try {
      final authService = _ref.read(driverAuthServiceProvider);
      final token = authService.token;
      final userId = authService.driverId;
      
      if (token == null || userId == null) {
        throw FetchDataException('Not authenticated');
      }

      await _socketApiServices.connect(_serverUrl, token);
      _isConnected = _socketApiServices.isConnected(_serverUrl);
      
      if (_isConnected) {
        state = AsyncData('Connected to Socket.IO server');
        log('✅ Socket connected successfully');
      } else {
        throw FetchDataException('Failed to establish socket connection');
      }
    } catch (e, stack) {
      _isConnected = false;
      log('❌ Error connecting to Socket.IO: $e');
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  void emit(String event, dynamic data) {
    try {
      if (!_isConnected) {
        throw FetchDataException('Socket not connected');
      }
      _socketApiServices.emit(_serverUrl, event, data);
      log('📤 Emitted $event: $data');
    } catch (e) {
      log('❌ Error emitting $event: $e');
      rethrow;
    }
  }

  void on(String event, Function(dynamic) callback) {
    try {
      _socketApiServices.on(_serverUrl, event, (data) {
        log('📥 Received $event: $data');
        callback(data);
      });
    } catch (e) {
      log('❌ Error setting up listener for $event: $e');
    }
  }

  Future<void> connectAndJoinUserRoom() async {
    state = const AsyncLoading();
    try {
      final authService = _ref.read(driverAuthServiceProvider);
      final token = authService.token;
      final userId = authService.driverId;
      if (token == null || userId == null) {
        throw FetchDataException('Not authenticated');
      }

      await _socketRepo.connectAndJoinUserRoom(_serverUrl, token, userId, 'join_user_room');
      _isConnected = true;
      state = AsyncData('Connected to Socket.IO and joined room for user: $userId');
    } catch (e, stack) {
      _isConnected = false;
      log('Error connecting to Socket.IO: $e');
      state = AsyncError(e, stack);
    }
  }

  Future<void> connectAndJoinDriverRoom() async {
    state = const AsyncLoading();
    try {
      final authService = _ref.read(driverAuthServiceProvider);
      final token = authService.token;
      final userIds = authService.driverId;
      await _socketRepo.connectAndJoinDriverRoom(_serverUrl, token!, userIds!, 'join_driver_room');
      _isConnected = true;
      state = AsyncData('Connected to Socket.IO and joined room for user: $userIds');
    } catch (e, stack) {
      _isConnected = false;
      log('Error connecting to Socket.IO: $e');
      state = AsyncError(e, stack);
    }
  }

  void disconnect() {
    try {
      _socketApiServices.disconnect(_serverUrl);
      _socketRepo.disconnect();
      _isConnected = false;
      state = const AsyncData('Disconnected');
      log('🔌 Socket disconnected');
    } catch (e) {
      log('❌ Error disconnecting: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

// Provider for DriverAuthService (adjust based on your setup)
final driverAuthServiceProvider = Provider<DriverAuthService>((ref) {
  return DriverAuthService();
});