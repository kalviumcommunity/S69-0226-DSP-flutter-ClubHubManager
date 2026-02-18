import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart'; // Import the events list
import 'login_screen.dart';    // Added this to fix the redirect error

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This gets the email of the person logged in
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 1. Sign out from Firebase
              await FirebaseAuth.instance.signOut();
              
              // 2. Clear the screen stack and go back to Login
              // This ensures the app "resets" to the LoginScreen
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text("Welcome, $userEmail!", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            // THE BUTTON to go to the Events page
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              },
              icon: const Icon(Icons.event_note),
              label: const Text("View Club Events", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}