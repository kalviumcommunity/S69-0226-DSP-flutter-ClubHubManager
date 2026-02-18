import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Club Hub Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // This takes you back to the login page
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: const Center(
        child: Text("Welcome to the College Club App!", 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}