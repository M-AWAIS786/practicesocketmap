import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:practicesocketmap/provider/socket_connect_provider.dart';
import 'package:practicesocketmap/screens/bookingScreen.dart';
import 'package:practicesocketmap/screens/location_tracking_screen.dart';


class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socketState = ref.watch(socketProvider);
      final authService = ref.read(driverAuthServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket.IO Demo'),
        backgroundColor: Colors.blue[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display connection status or notifications
            socketState.when(
              data: (message) => Text(
                message ?? 'Press the button to connect',
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                'Error: $error',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
            const SizedBox(height: 24),
            // Connect Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(socketProvider.notifier).connectAndJoinUserRoom();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Connect to Socket.IO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            Text("niche bdriver ko socket connect kra gye"),
            TextButton(
            onPressed: (){
               ref.read(socketProvider.notifier).connectAndJoinDriverRoom();
            },
            child: Text("Driver Lora Connect Socket"),
             ),
             socketState.when(data: (data) {
               return Text(data.toString());
             }, error: (error, stackTrace) => Text("lora erro agaye $error $stackTrace"), loading: () => CircularProgressIndicator(),),
          TextButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen(
              userId: authService.driverId ?? '',
              userName:"awais" ,
              userToken:authService.token  ?? '',
            ),));
          }, child: Text("user booking lora")),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationTrackingScreen(),
                ),
              );
            },
            child: const Text("Location Tracking"),
          )
          ],
        ),
      ),
    );
  }
}