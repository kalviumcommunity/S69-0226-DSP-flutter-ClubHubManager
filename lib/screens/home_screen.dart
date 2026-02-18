import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart'; // Import the events list

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
            onPressed: () => FirebaseAuth.instance.signOut(),
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