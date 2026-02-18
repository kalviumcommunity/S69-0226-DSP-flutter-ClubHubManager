import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for StreamBuilder
import 'firebase_options.dart';
import 'screens/login_screen.dart'; 
import 'screens/home_screen.dart'; // Needed to show the Home page

void main() async {
  // This ensures the app is ready to talk to the phone hardware
  WidgetsFlutterBinding.ensureInitialized();
  
  // This connects the app to your Firebase project
  await Firebase.initializeApp( 
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // This "Stream" automatically switches between Login and Home
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the snapshot has data, it means a user is already logged in
          if (snapshot.hasData) {
            return const HomeScreen(); 
          } else {
            // Otherwise, show the login screen
            return const LoginScreen(); 
          }
        },
      ),
    );
  }
}