import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pin_tag_client/screens/auth_screen.dart';
import 'package:pin_tag_client/screens/board_screen.dart';
import 'package:pin_tag_client/services/api_service.dart';
import 'package:pin_tag_client/services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PinTag',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder(
        future: _checkExistingAuth(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final authData = snapshot.data as Map<String, dynamic>?;
          if (authData != null) {
            final apiService = ApiService();

            return BoardsScreen(userId: authData['userId']);
          } else {
            return AuthScreen();
          }
        },
      ),
      routes: {
        '/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return BoardsScreen(userId: args?['userId'] ?? 0);
        },
      },
    );
  }

  Future<Map<String, dynamic>?> _checkExistingAuth() async {
    final storage = StorageService();
    final userId = await storage.getUserId();
    final connectId = await storage.getConnectId();

    if (userId != null && connectId != null) {
      return {'userId': userId, 'connectId': connectId};
    }
    return null;
  }
}
