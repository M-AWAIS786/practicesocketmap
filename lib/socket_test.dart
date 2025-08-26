import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketTest {
  IO.Socket? socket;
  bool isConnected = false;
  
  void initializeSocket() {
    try {
      // Test socket connection to socket.io test server
      socket = IO.io('https://socket.io/', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      socket!.onConnect((_) {
        isConnected = true;
        print('✅ Socket connected successfully!');
        
        // Send a test message
        socket!.emit('message', 'Hello from Flutter Socket Test!');
      });

      socket!.onDisconnect((_) {
        isConnected = false;
        print('❌ Socket disconnected');
      });

      socket!.onConnectError((data) {
        print('🔴 Socket connection error: $data');
      });

      socket!.on('message', (data) {
        print('📨 Received message: $data');
      });

      // Connect to the socket
      socket!.connect();
      
    } catch (e) {
      print('🚨 Socket initialization error: $e');
    }
  }
  
  void sendTestMessage(String message) {
    if (socket != null && isConnected) {
      socket!.emit('message', message);
      print('📤 Sent: $message');
    } else {
      print('⚠️ Socket not connected. Cannot send message.');
    }
  }
  
  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
  }
}

// Simple test function
void testSocket() async {
  print('🧪 Starting Socket Test...');
  
  SocketTest socketTest = SocketTest();
  socketTest.initializeSocket();
  
  // Wait a bit for connection
  await Future.delayed(Duration(seconds: 3));
  
  // Send test messages
  socketTest.sendTestMessage('Test message 1');
  await Future.delayed(Duration(seconds: 1));
  socketTest.sendTestMessage('Test message 2');
  
  // Wait before disconnecting
  await Future.delayed(Duration(seconds: 2));
  socketTest.disconnect();
  
  print('🏁 Socket test completed!');
}