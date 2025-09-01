import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:practicesocketmap/repository/login_repo.dart';
import 'package:practicesocketmap/services/app_exceptions.dart';
import 'package:practicesocketmap/services/driver_auth_service.dart';

final socketProvider = StateNotifierProvider<SocketNotifier, AsyncValue<String?>>((ref) {
  return SocketNotifier(ref);
});

class SocketNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;
  final _socketRepo = SocketRepository();

  SocketNotifier(this._ref) : super(const AsyncData(null)) {

  }

  Future<void> connectAndJoinUserRoom() async {
    state = const AsyncLoading();
    try {
      final authService = _ref.read(driverAuthServiceProvider);
      final token = authService.token;
      final userId = authService.driverId; // Assume DriverAuthService has userId
      if (token == null || userId == null) {
        throw FetchDataException('Not authenticated');
      }

      await _socketRepo.connectAndJoinUserRoom('http://159.198.74.112:3001', token, userId, 'join_user_room');
      state = AsyncData('Connected to Socket.IO and joined room for user: $userId');
    } catch (e, stack) {
      log('Error connecting to Socket.IO: $e');
      state = AsyncError(e, stack);
    }
  }

  Future<void> connectAndJoinDriverRoom()async{
       state = AsyncLoading();
       try{
           final authService = _ref.read(driverAuthServiceProvider);
           final token = authService.token;
           final userIds = authService.driverId;
           await _socketRepo.connectAndJoinDriverRoom('http://159.198.74.112:3001', token!, userIds!, 'join_driver_room');
  state = AsyncData('Connected to Socket.IO and joined room for user: $userIds');
 
           
       }catch(e,stack){
         
      log('Error connecting to Socket.IO: $e');
      state = AsyncError(e, stack);
       }
}


  @override
  void dispose() {
    _socketRepo.disconnect();
    super.dispose();
  }
}

// Provider for DriverAuthService (adjust based on your setup)
final driverAuthServiceProvider = Provider<DriverAuthService>((ref) {
  return DriverAuthService();
});