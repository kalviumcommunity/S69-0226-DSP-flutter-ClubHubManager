import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Find the _saveEvent function and update the Firebase part:
  Future<void> _saveEvent() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) return;

    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "Unknown";

    await FirebaseFirestore.instance.collection('events').add({
      'title': _titleController.text,
      'description': _descController.text,
      'postedBy': userEmail, // <--- Add this line
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post New Event")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Event Title")),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveEvent, child: const Text("Post to Club Hub")),
          ],
        ),
      ),
    );
  }
}